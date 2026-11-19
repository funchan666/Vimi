import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../design/vimi_ui.dart';
import '../studio/rehearsal_player.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key, this.challenge});
  final String? challenge;
  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final caption = TextEditingController();
  final picker = ImagePicker();
  String style = 'K-pop', clientId = const Uuid().v4();
  String? path, uploaded, error;
  bool video = false, busy = false, rights = false, loaded = false;
  String? draftOwner;
  String get draftKey => 'publish.v1.$draftOwner';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      loaded = true;
      unawaited(restore());
    }
  }

  Future<void> restore() async {
    final app = VimiScope.of(context);
    draftOwner ??= app.account;
    try {
      final raw = app.studio.preferences.getString(draftKey);
      if (raw != null) {
        final d = jsonMap(jsonDecode(raw));
        caption.text = d['caption'] as String? ?? '';
        style = d['style'] as String? ?? 'K-pop';
        path = d['path'] as String?;
        uploaded = d['uploaded'] as String?;
        video = d['video'] == true;
        clientId = d['client_id'] as String? ?? clientId;
      }
      final lost = await picker.retrieveLostData();
      if (!lost.isEmpty && lost.files != null && lost.files!.isNotEmpty) {
        await retain(lost.files!.first, lost.type == RetrieveType.video);
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted)
        setState(
          () => error =
              'Your previous draft could not be opened. Choose media to start a new post.',
        );
    }
  }

  Future<void> persist() async {
    if (!mounted) return;
    await VimiScope.of(context).studio.preferences.setString(
      draftKey,
      jsonEncode({
        'caption': caption.text,
        'style': style,
        'path': path,
        'uploaded': uploaded,
        'video': video,
        'client_id': clientId,
        'challenge': widget.challenge,
      }),
    );
  }

  Future<void> retain(XFile file, bool isVideo) async {
    if (await file.length() > 50 * 1024 * 1024)
      throw const FileSystemException('Choose media smaller than 50 MB.');
    if (isVideo) {
      final check = VideoPlayerController.file(File(file.path));
      try {
        await check.initialize();
        if (check.value.duration > const Duration(minutes: 2))
          throw const FileSystemException(
            'Choose a dance clip up to 2 minutes long.',
          );
      } finally {
        await check.dispose();
      }
    }
    final app = VimiScope.of(context);
    final root = await getApplicationSupportDirectory();
    if (draftOwner != app.account) return;
    final folder = Directory('${root.path}/drafts/$draftOwner');
    await folder.create(recursive: true);
    final name = file.path
        .split('/')
        .last
        .replaceAll(RegExp('[^A-Za-z0-9.]'), '_');
    final local = await File(
      file.path,
    ).copy('${folder.path}/${const Uuid().v4()}_$name');
    path = local.path;
    video = isVideo;
    uploaded = null;
    clientId = const Uuid().v4();
    await persist();
  }

  Future<void> choose(ImageSource source, bool isVideo) async {
    if (busy || uploaded != null) return;
    PlaybackCoordinator.pauseAll();
    setState(() => busy = true);
    try {
      final file = isVideo
          ? await picker.pickVideo(
              source: source,
              maxDuration: const Duration(minutes: 2),
            )
          : await picker.pickImage(
              source: source,
              imageQuality: 85,
              maxWidth: 1800,
              maxHeight: 2400,
            );
      if (file != null && mounted) {
        await retain(file, isVideo);
        if (mounted) setState(() => error = null);
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> publish() async {
    if (busy) return;
    final app = VimiScope.of(context);
    if (path == null || caption.text.trim().isEmpty || !rights) {
      setState(
        () => error =
            'Choose media, add a caption and confirm that you may share the media and music.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    PlaybackCoordinator.pauseAll();
    try {
      final repo = app.repo!;
      if (draftOwner != app.account) return;
      uploaded ??= await repo.upload(
        File(path!),
        avatar: false,
        video: video,
        mediaId: clientId,
      );
      if (draftOwner != app.account) return;
      await persist();
      await repo.publish(
        caption: caption.text.trim(),
        style: style,
        path: uploaded!,
        video: video,
        clientId: clientId,
        challenge: widget.challenge,
      );
      await app.studio.preferences.remove(draftKey);
      app.changed();
      if (mounted) {
        Navigator.pop(context);
        feedback(context, 'Your dance has been submitted for review.');
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'Share your movement',

    child: ListView(
      padding: const EdgeInsets.all(24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const Text('A cover, a practice moment, a movement you made your own.'),
        const SizedBox(height: 24),
        if (path == null)
          SurfacePanel(
            child: Column(
              children: [
                const VIcon(Glyph.video, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Start with your dance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text('A photo or a video up to 2 minutes · 50 MB'),
              ],
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: video
                ? RehearsalPlayer(source: path!, practice: true)
                : Image.file(File(path!), height: 320, fit: BoxFit.contain),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            VButton(
              'Photo library',
              glyph: Glyph.photo,
              quiet: true,
              onPressed: busy || uploaded != null
                  ? null
                  : () => choose(ImageSource.gallery, false),
            ),
            VButton(
              'Video library',
              glyph: Glyph.video,
              quiet: true,
              onPressed: busy || uploaded != null
                  ? null
                  : () => choose(ImageSource.gallery, true),
            ),
            VButton(
              'Take photo',
              glyph: Glyph.camera,
              quiet: true,
              onPressed: busy || uploaded != null
                  ? null
                  : () => choose(ImageSource.camera, false),
            ),
            VButton(
              'Record video',
              glyph: Glyph.video,
              quiet: true,
              onPressed: busy || uploaded != null
                  ? null
                  : () => choose(ImageSource.camera, true),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ChoiceStrip(
          options: DanceStyle.values.map((s) => s.label).toList(),
          value: style,
          onChanged: (s) {
            setState(() => style = s);
            unawaited(persist());
          },
        ),
        const SizedBox(height: 16),
        VField(
          'What did you work on?',
          controller: caption,
          lines: 4,
          maxLength: 2000,
          onChanged: (_) => unawaited(persist()),
        ),
        Row(
          children: [
            VIconButton(
              rights ? Glyph.check : Glyph.add,
              label: 'Confirm media and music rights',
              onPressed: () => setState(() => rights = !rights),
            ),
            const Expanded(
              child: Text(
                'I have permission to share this media, music and the people shown.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Posts are reviewed before appearing on the floor. Your draft stays here if uploading is interrupted.',
          style: TextStyle(color: VimiColors.muted),
        ),
        if (error != null) ...[const SizedBox(height: 16), ErrorNote(error!)],
        const SizedBox(height: 24),
        VButton(
          uploaded != null ? 'Submit uploaded dance' : 'Submit for review',
          glyph: Glyph.upload,

          busy: busy,
          onPressed: publish,
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}
