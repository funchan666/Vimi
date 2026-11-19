import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models.dart';

class TimelineCursor implements Comparable<TimelineCursor> {
  const TimelineCursor(this.createdAt, this.id);
  final DateTime createdAt;
  final String id;
  factory TimelineCursor.row(Json row, {String idField = 'id'}) =>
      TimelineCursor(
        DateTime.parse(row['created_at'] as String),
        row[idField] as String,
      );
  String filter({String idField = 'id', bool ascending = false}) {
    final operation = ascending ? 'gt' : 'lt';
    final time = createdAt.toUtc().toIso8601String();
    return 'created_at.$operation.$time,and(created_at.eq.$time,$idField.$operation.$id)';
  }

  Json get beforeParameters => {
    'p_before_created': createdAt.toUtc().toIso8601String(),
    'p_before_id': id,
  };
  @override
  int compareTo(TimelineCursor other) {
    final time = createdAt.compareTo(other.createdAt);
    return time == 0 ? id.compareTo(other.id) : time;
  }
}

class CursorPage<T> {
  const CursorPage(
    this.items, {
    this.next,
    this.hasMore = false,
    this.cursors = const [],
  });
  final List<T> items;
  final List<TimelineCursor> cursors;
  final TimelineCursor? next;
  final bool hasMore;
  factory CursorPage.rows(
    List<Json> rows,
    T Function(Json) decode, {
    int size = 25,
    String idField = 'id',
  }) {
    final visible = rows.take(size).toList();
    return CursorPage(
      visible.map(decode).toList(),
      next: visible.isEmpty
          ? null
          : TimelineCursor.row(visible.last, idField: idField),
      hasMore: rows.length > size,
      cursors: visible
          .map((row) => TimelineCursor.row(row, idField: idField))
          .toList(),
    );
  }
}

/// Keeps loaded history through a refresh, including timestamp ties and new rows.
class CursorPager<T> extends ChangeNotifier {
  CursorPager({
    required this.fetch,
    required this.identity,
    this.ascending = false,
    bool Function()? isCurrent,
  }) : isCurrent = isCurrent ?? (() => true);
  final Future<CursorPage<T>> Function(TimelineCursor?) fetch;
  final String Function(T) identity;
  final bool ascending;
  final bool Function() isCurrent;
  List<T> items = [];
  bool loading = false, loaded = false, hasMore = true;
  Object? error;
  TimelineCursor? _next;
  Future<void>? _work;
  bool _refreshQueued = false, _disposed = false, _failedRefresh = true;

  Future<void> refresh() {
    if (_disposed) return Future.value();
    if (_work != null) {
      _refreshQueued = true;
      return _work!;
    }
    return _start(true);
  }

  Future<void> loadMore() {
    if (_disposed || !hasMore) return Future.value();
    return _work ?? _start(false);
  }

  Future<void> retry() => _failedRefresh ? refresh() : loadMore();
  Future<void> _start(bool refresh) {
    Future<void> run() async {
      do {
        _refreshQueued = false;
        await _load(refresh);
        refresh = true;
      } while (_refreshQueued && !_disposed);
    }

    _work = run().whenComplete(() => _work = null);
    return _work!;
  }

  bool _usable() {
    if (_disposed) return false;
    if (isCurrent()) return true;
    items = [];
    _next = null;
    hasMore = false;
    loaded = true;
    return false;
  }

  Future<void> _load(bool refresh) async {
    if (!_usable()) {
      _emit();
      return;
    }
    loading = true;
    error = null;
    _failedRefresh = refresh;
    _emit();
    final previousEnd = refresh ? _next : null;
    var cursor = refresh ? null : _next;
    final incoming = <T>[];
    try {
      late CursorPage<T> page;
      do {
        page = await fetch(cursor);
        if (!_usable()) return;
        var trimmed = false;
        if (refresh &&
            previousEnd != null &&
            page.cursors.length == page.items.length) {
          final count = page.cursors
              .takeWhile(
                (item) => ascending
                    ? item.compareTo(previousEnd) <= 0
                    : item.compareTo(previousEnd) >= 0,
              )
              .length;
          if (count < page.items.length) {
            trimmed = true;
            page = CursorPage(
              page.items.take(count).toList(),
              next: count == 0 ? cursor : page.cursors[count - 1],
              hasMore: true,
              cursors: page.cursors.take(count).toList(),
            );
          }
        }
        final next = page.next;
        if (!trimmed &&
            page.hasMore &&
            (next == null ||
                (cursor != null &&
                    (ascending
                        ? next.compareTo(cursor) <= 0
                        : next.compareTo(cursor) >= 0)))) {
          throw StateError('The next page did not advance. Please retry.');
        }
        incoming.addAll(page.items);
        cursor = next;
        if (trimmed) break;
      } while (refresh &&
          page.hasMore &&
          cursor != null &&
          previousEnd != null &&
          (ascending
              ? cursor.compareTo(previousEnd) < 0
              : cursor.compareTo(previousEnd) > 0));
      final merged = <String, T>{};
      for (final item in [...(refresh ? <T>[] : items), ...incoming]) {
        merged[identity(item)] = item;
      }
      items = merged.values.toList();
      _next = page.next;
      hasMore = page.hasMore;
      loaded = true;
    } catch (e) {
      if (_usable()) error = e;
    } finally {
      if (!_disposed) {
        loading = false;
        _emit();
      }
    }
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
