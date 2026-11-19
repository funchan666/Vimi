import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory('docs/verification/2026-11-19');
  await directory.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      final safe = Map<String, dynamic>.from(data ?? {})..remove('screenshots');
      await File(
        '${directory.path}/native-results.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(safe));
    },
    writeResponseOnFailure: true,
  );
}
