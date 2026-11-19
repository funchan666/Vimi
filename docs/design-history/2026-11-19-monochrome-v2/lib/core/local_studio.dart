import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class LocalStudio {
  LocalStudio(this.preferences);
  final SharedPreferences preferences;
  Future<List<PracticeSession>> load(String account) async {
    final raw = preferences.getString('practice.v1.$account');
    if (raw == null) return [];
    // A corrupt file is preserved, never silently replaced with an empty journal.
    return jsonRows(jsonDecode(raw)).map(PracticeSession.fromJson).toList();
  }

  Future<void> save(String account, List<PracticeSession> sessions) async {
    final ok = await preferences.setString(
      'practice.v1.$account',
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
    if (!ok)
      throw const FileSystemException(
        'Your practice could not be saved. Please try again.',
      );
  }

  Future<String> retainVideo(String account, String source) async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/practice/$account');
    await directory.create(recursive: true);
    final suffix = source.toLowerCase().endsWith('.mov') ? 'mov' : 'mp4';
    return (await File(source).copy(
      '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.$suffix',
    )).path;
  }

  Future<void> clear(String account) async {
    await preferences.remove('practice.v1.$account');
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/practice/$account');
    if (await directory.exists()) await directory.delete(recursive: true);
    final drafts = Directory('${root.path}/drafts/$account');
    if (await drafts.exists()) await drafts.delete(recursive: true);
  }
}
