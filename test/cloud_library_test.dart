import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vimi/core/media_library.dart';

void main() {
  final data =
      jsonDecode(File('assets/data/media_library.json').readAsStringSync())
          as Map<String, dynamic>;
  final library = MediaLibrary.fromJson(data);
  test(
    'all supplied media retain IDs and bounded public resource metadata',
    () {
      expect(library.portraits, hasLength(55));
      expect(library.clips, hasLength(10));
      expect(data['resources'], hasLength(128));
      for (final portrait in library.portraits) {
        expect(portrait.url, startsWith(LibraryResource.prefix));
        expect(portrait.thumbnail, startsWith(LibraryResource.prefix));
        expect(portrait.image.bytes, lessThan(50 * 1024 * 1024));
      }
    },
  );
  test(
    'all previous note, draft and recovery asset references resolve without mutation',
    () {
      for (final clip in library.clips) {
        expect(isLibraryVideo(clip.legacySource), isTrue);
        expect(isLibraryVideo(clip.source), isTrue);
        expect(library.clipForSource(clip.legacySource), same(clip));
        expect(library.clipForSource(clip.source), same(clip));
      }
      expect(
        isLibraryVideo('asset:assets/content/videos/../private.mp4'),
        isFalse,
      );
      expect(
        () => library.clipForSource('library:unknown'),
        throwsFormatException,
      );
      expect(isLibraryVideo('/private/personal-video.mp4'), isFalse);
    },
  );
  test(
    'resource metadata rejects other origins, queries and unbounded or invalid downloads',
    () {
      final original = Map<String, dynamic>.from(
        (data['resources'] as Map).values.first as Map,
      );
      for (final replacement in <Map<String, dynamic>>[
        {'url': 'https://example.invalid/video.mp4'},
        {'url': '${original['url']}?redirect=elsewhere'},
        {'bytes': 60 * 1024 * 1024},
        {'sha256': 'not-a-hash'},
        {'content_type': 'text/html'},
      ]) {
        expect(
          () => LibraryResource.fromJson({...original, ...replacement}),
          throwsFormatException,
        );
      }
    },
  );
}
