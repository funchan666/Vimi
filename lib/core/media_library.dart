import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

bool isLibraryVideo(String source) =>
    RegExp(r'^library:[a-z0-9-]+$').hasMatch(source) ||
    RegExp(r'^asset:assets/content/videos/[a-z0-9-]+\.mp4$').hasMatch(source);

/// Metadata only. Optimized media bytes live in the publisher's public bucket.
class LibraryResource {
  const LibraryResource({
    required this.url,
    required this.bytes,
    required this.hash,
    required this.contentType,
  });
  final String url, hash, contentType;
  final int bytes;
  static const prefix =
      'https://hgxbfgcdfsalavdfyvjr.supabase.co/storage/v1/object/public/dance-library/v1/';

  factory LibraryResource.fromJson(Map<String, dynamic> json) {
    final url = json['url'] as String;
    final uri = Uri.parse(url);
    final bytes = json['bytes'] as int;
    final hash = json['sha256'] as String;
    final type = json['content_type'] as String;
    if (!url.startsWith(prefix) ||
        uri.hasQuery ||
        uri.hasFragment ||
        url.contains('..') ||
        bytes <= 0 ||
        bytes > 50 * 1024 * 1024 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        !const [
          'image/jpeg',
          'image/png',
          'image/webp',
          'video/mp4',
        ].contains(type)) {
      throw const FormatException('This library resource is unavailable.');
    }
    return LibraryResource(
      url: url,
      bytes: bytes,
      hash: hash,
      contentType: type,
    );
  }

  /// Bounded download for an explicit profile save. No auth token or account
  /// data is sent to this public publisher-content URL.
  Future<Uint8List> download() async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _downloadOnce();
      } on HandshakeException {
        if (attempt >= 2) rethrow;
      } on SocketException {
        if (attempt >= 2) rethrow;
      } on TimeoutException {
        if (attempt >= 2) rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
    }
  }

  Future<Uint8List> _downloadOnce() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != HttpStatus.ok ||
          response.headers.contentType?.mimeType != contentType ||
          (response.contentLength >= 0 && response.contentLength != bytes)) {
        throw const HttpException(
          'This library image could not be downloaded. Check your connection and retry.',
        );
      }
      final result = BytesBuilder(copy: false);
      var length = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        length += chunk.length;
        if (length > bytes)
          throw const FormatException('The library download is invalid.');
        result.add(chunk);
      }
      final data = result.takeBytes();
      if (length != bytes || sha256.convert(data).toString() != hash) {
        throw const FormatException(
          'The library download is incomplete. Please retry.',
        );
      }
      return data;
    } finally {
      client.close(force: true);
    }
  }
}

class LibraryClip {
  const LibraryClip({
    required this.id,
    required this.title,
    required this.legacyAsset,
    required this.video,
    required this.cover,
    required this.category,
    required this.duration,
    required this.hasAudio,
  });
  final String id, title, legacyAsset, category;
  final LibraryResource video, cover;
  final double duration;
  final bool hasAudio;
  String get source => 'library:$id';
  String get url => video.url;
  String get thumbnail => cover.url;
  String get legacySource => 'asset:$legacyAsset';
  String get durationLabel =>
      '${duration.floor() ~/ 60}:${(duration.floor() % 60).toString().padLeft(2, '0')}';
}

class LibraryPortrait {
  const LibraryPortrait({
    required this.id,
    required this.title,
    required this.image,
    required this.preview,
  });
  final String id, title;
  final LibraryResource image, preview;
  String get url => image.url;
  String get thumbnail => preview.url;
  String get extension => Uri.parse(url).path.split('.').last;
  Future<Uint8List> download() => image.download();
}

class MediaLibrary {
  const MediaLibrary({required this.clips, required this.portraits});
  final List<LibraryClip> clips;
  final List<LibraryPortrait> portraits;

  LibraryPortrait? defaultAvatarFor(String accountId) {
    const avatarIds = {
      'portrait-001',
      'portrait-007',
      'portrait-014',
      'portrait-015',
      'portrait-017',
      'portrait-018',
      'portrait-022',
      'portrait-030',
    };
    final choices = portraits
        .where((photo) => avatarIds.contains(photo.id))
        .toList();
    if (choices.isEmpty) return null;
    final choice = md5.convert(utf8.encode(accountId)).bytes.first;
    return choices[choice % choices.length];
  }

  /// Both new IDs and notes/drafts/backups saved by version 1 remain playable.
  LibraryClip clipForSource(String source) => clips.firstWhere(
    (clip) => clip.source == source || clip.legacySource == source,
    orElse: () => throw const FormatException(
      'This library clip is unavailable. Choose another video.',
    ),
  );

  factory MediaLibrary.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 2)
      throw const FormatException('This media library could not be opened.');
    final resources = (json['resources'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        LibraryResource.fromJson(value as Map<String, dynamic>),
      ),
    );
    return MediaLibrary(
      clips: List.unmodifiable(
        (json['clips'] as List).map(
          (entry) => LibraryClip(
            id: entry['id'] as String,
            title: entry['title'] as String,
            legacyAsset: entry['asset'] as String,
            video: resources[entry['asset']]!,
            cover: resources[entry['thumbnail']]!,
            category: entry['category'] as String,
            duration: (entry['duration'] as num).toDouble(),
            hasAudio: entry['has_audio'] as bool,
          ),
        ),
      ),
      portraits: List.unmodifiable(
        (json['portraits'] as List).map(
          (entry) => LibraryPortrait(
            id: entry['id'] as String,
            title: entry['title'] as String,
            image: resources[entry['asset']]!,
            preview: resources[entry['thumbnail']]!,
          ),
        ),
      ),
    );
  }

  static Future<MediaLibrary> load() async => MediaLibrary.fromJson(
    jsonDecode(await rootBundle.loadString('assets/data/media_library.json'))
        as Map<String, dynamic>,
  );
}
