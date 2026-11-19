import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vimi/core/local_studio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'queued text writes keep their nonce and cannot recreate a submitted draft',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalStudio(await SharedPreferences.getInstance());
      await Future.wait([
        store.writeDraft('message.v2.a.b', {
          'body': 'First',
          'client_id': 'one',
        }),
        store.writeDraft('message.v2.a.b', {
          'body': 'Final message',
          'client_id': 'two',
        }),
        store.removeDraft('message.v2.a.b'),
      ]);
      expect(store.readDraft('message.v2.a.b'), isNull);
      await store.writeDraft('message.v2.a.b', {
        'body': 'Retry safely',
        'client_id': 'stable-nonce',
      });
      final reopened = LocalStudio(store.preferences);
      expect(reopened.readDraft('message.v2.a.b'), {
        'body': 'Retry safely',
        'client_id': 'stable-nonce',
      });
      expect(reopened.readDraft('message.v2.b.a'), isNull);
    },
  );
}
