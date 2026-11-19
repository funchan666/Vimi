import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:vimi/core/models.dart';
import 'package:vimi/core/pagination.dart';

Json row(int number) => {
  'id': number.toString().padLeft(6, '0'),
  'created_at': '2026-11-19T05:30:00.123456Z',
};
CursorPage<Json> page(
  List<Json> all,
  TimelineCursor? cursor, {
  bool ascending = false,
  int size = 3,
}) {
  final remaining = all
      .where(
        (item) =>
            cursor == null ||
            (ascending
                ? TimelineCursor.row(item).compareTo(cursor) > 0
                : TimelineCursor.row(item).compareTo(cursor) < 0),
      )
      .toList();
  return CursorPage.rows(
    remaining.take(size + 1).toList(),
    (item) => item,
    size: size,
  );
}

void main() {
  test(
    'timestamp ties and fractional seconds survive more than 100 rows',
    () async {
      final all = List.generate(137, (i) => row(137 - i));
      final pager = CursorPager<Json>(
        fetch: (cursor) async => page(all, cursor),
        identity: (item) => item['id'] as String,
      );
      addTearDown(pager.dispose);
      await pager.refresh();
      while (pager.hasMore) {
        await pager.loadMore();
      }
      expect(pager.items, all);
      expect(TimelineCursor.row(all.first).filter(), contains('.123456Z'));
    },
  );
  test(
    'arrivals and removed tail keep loaded depth, without fetching every older page',
    () async {
      final all = List.generate(40, (i) => row(40 - i));
      final pager = CursorPager<Json>(
        fetch: (cursor) async => page(all, cursor),
        identity: (item) => item['id'] as String,
      );
      addTearDown(pager.dispose);
      await pager.refresh();
      await pager.loadMore();
      final oldTail = pager.items.last['id'];
      all.insert(0, row(42));
      all.insert(1, row(41));
      await pager.refresh();
      expect(pager.items, all.take(8).toList());
      expect(pager.items.last['id'], oldTail);
      all.removeWhere((item) => item['id'] == oldTail);
      await pager.refresh();
      expect(pager.items, all.take(7).toList());
      await pager.loadMore();
      expect(pager.items, all.take(10).toList());
    },
  );
  test(
    'ascending review queue keeps its oldest-first cursor when items are resolved',
    () async {
      final all = List.generate(15, row);
      final pager = CursorPager<Json>(
        fetch: (cursor) async => page(all, cursor, ascending: true),
        identity: (item) => item['id'] as String,
        ascending: true,
      );
      addTearDown(pager.dispose);
      await pager.refresh();
      await pager.loadMore();
      all.removeAt(0);
      all.add(row(15));
      await pager.refresh();
      expect(pager.items.map((item) => item['id']), [
        '000001',
        '000002',
        '000003',
        '000004',
        '000005',
      ]);
      await pager.loadMore();
      expect(pager.items.last['id'], '000008');
    },
  );
  test(
    'failed second page retries the same cursor and preserves existing items',
    () async {
      final all = List.generate(10, (i) => row(10 - i));
      var fail = false;
      final pager = CursorPager<Json>(
        fetch: (cursor) async {
          if (fail) throw StateError('offline');
          return page(all, cursor);
        },
        identity: (item) => item['id'] as String,
      );
      addTearDown(pager.dispose);
      await pager.refresh();
      fail = true;
      await pager.loadMore();
      expect(pager.items, all.take(3).toList());
      expect(pager.error, isNotNull);
      fail = false;
      await pager.retry();
      expect(pager.items, all.take(6).toList());
      expect(pager.error, isNull);
    },
  );
  test('failed refresh keeps rows and retries from the head', () async {
    final all = List.generate(12, (i) => row(12 - i));
    var fail = false;
    final pager = CursorPager<Json>(
      fetch: (cursor) async {
        if (fail && cursor != null) throw StateError('offline');
        return page(all, cursor);
      },
      identity: (item) => item['id'] as String,
    );
    addTearDown(pager.dispose);
    await pager.refresh();
    await pager.loadMore();
    all.insert(0, row(13));
    fail = true;
    await pager.refresh();
    expect(pager.items, List.generate(6, (i) => row(12 - i)));
    expect(pager.error, isNotNull);
    fail = false;
    await pager.retry();
    expect(pager.items, all.take(7).toList());
  });
  test(
    'double taps and queued refreshes share work and do not duplicate rows',
    () async {
      final all = List.generate(8, (i) => row(8 - i));
      final first = Completer<CursorPage<Json>>();
      var requests = 0;
      final pager = CursorPager<Json>(
        fetch: (cursor) {
          requests++;
          return requests == 1 ? first.future : Future.value(page(all, cursor));
        },
        identity: (item) => item['id'] as String,
      );
      addTearDown(pager.dispose);
      final request = pager.refresh();
      final again = pager.loadMore();
      final refresh = pager.refresh();
      expect(identical(request, again), isTrue);
      expect(identical(request, refresh), isTrue);
      first.complete(page(all, null));
      await request;
      expect(requests, 2);
      expect(pager.items, all.take(3).toList());
    },
  );
  test(
    'switching account discards a late response and disposing ignores it',
    () async {
      var current = true;
      final waiting = Completer<CursorPage<Json>>();
      final pager = CursorPager<Json>(
        fetch: (_) => waiting.future,
        identity: (item) => item['id'] as String,
        isCurrent: () => current,
      );
      final request = pager.refresh();
      current = false;
      waiting.complete(page([row(1)], null));
      await request;
      expect(pager.items, isEmpty);
      pager.dispose();
      final later = Completer<CursorPage<Json>>();
      final disposed = CursorPager<Json>(
        fetch: (_) => later.future,
        identity: (item) => item['id'] as String,
      );
      final lateWork = disposed.refresh();
      disposed.dispose();
      later.complete(page([row(1)], null));
      await lateWork;
      expect(disposed.items, isEmpty);
    },
  );
  test(
    'non-advancing server cursor fails visibly instead of looping forever',
    () async {
      final cursor = TimelineCursor.row(row(5));
      var calls = 0;
      final pager = CursorPager<Json>(
        fetch: (_) async {
          calls++;
          return CursorPage([row(5)], next: cursor, hasMore: true);
        },
        identity: (item) => item['id'] as String,
      );
      addTearDown(pager.dispose);
      await pager.refresh();
      await pager.loadMore();
      expect(calls, 2);
      expect(pager.error, isA<StateError>());
      expect(pager.items, hasLength(1));
    },
  );
}
