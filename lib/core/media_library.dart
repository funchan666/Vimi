import 'dart:convert';
import 'package:flutter/services.dart';

bool isLibraryVideo(String source) =>
    source.startsWith('asset:assets/content/videos/') &&
    source.endsWith('.mp4') &&
    !source.contains('..');

class LibraryClip {
  const LibraryClip({
    required this.id,
    required this.title,
    required this.asset,
    required this.thumbnail,
    required this.category,
    required this.duration,
    required this.hasAudio,
  });
  final String id, title, asset, thumbnail, category;
  final double duration;
  final bool hasAudio;
  String get source => 'asset:$asset';
  String get durationLabel =>
      '${duration.floor() ~/ 60}:${(duration.floor() % 60).toString().padLeft(2, '0')}';

  factory LibraryClip.fromJson(Map<String, dynamic> json) => LibraryClip(
    id: json['id'] as String,
    title: json['title'] as String,
    asset: json['asset'] as String,
    thumbnail: json['thumbnail'] as String,
    category: json['category'] as String,
    duration: (json['duration'] as num).toDouble(),
    hasAudio: json['has_audio'] as bool,
  );
}

class LibraryPortrait {
  const LibraryPortrait({
    required this.id,
    required this.title,
    required this.asset,
    required this.thumbnail,
  });
  final String id, title, asset, thumbnail;
  factory LibraryPortrait.fromJson(Map<String, dynamic> json) =>
      LibraryPortrait(
        id: json['id'] as String,
        title: json['title'] as String,
        asset: json['asset'] as String,
        thumbnail: json['thumbnail'] as String,
      );
}

class MediaLibrary {
  const MediaLibrary({required this.clips, required this.portraits});
  final List<LibraryClip> clips;
  final List<LibraryPortrait> portraits;

  static Future<MediaLibrary> load() async {
    final json =
        jsonDecode(
              await rootBundle.loadString('assets/data/media_library.json'),
            )
            as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('This media library could not be opened.');
    }
    return MediaLibrary(
      clips: List.unmodifiable(
        (json['clips'] as List).map(
          (entry) => LibraryClip.fromJson(entry as Map<String, dynamic>),
        ),
      ),
      portraits: List.unmodifiable(
        (json['portraits'] as List).map(
          (entry) => LibraryPortrait.fromJson(entry as Map<String, dynamic>),
        ),
      ),
    );
  }
}
