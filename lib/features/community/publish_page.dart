import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../core/local_studio.dart';
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
  bool video = false, busy = true, rights = false, loaded = false;
  String? draftOwner, challengeId;
  late LocalStudio draftStore;
  String get draftKey => 'publish.v1.$draftOwner';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      loaded = true;
      draftStore = VimiScope.of(context).studio;
      challengeId = widget.challenge;
      unawaited(restore());
    }
  }

  Future<void> restore() async {
    final app = VimiScope.of(context);
    draftOwner ??= app.account;
    try {
      final d = draftStore.readDraft(draftKey);
      if (d != null) {
        caption.text = d['caption'] as String? ?? '';
        style = d['style'] as String? ?? 'K-pop';
        path = d['path'] as String?;
        uploaded = d['uploaded'] as String?;
        video = d['video'] == true;
        clientId = d['client_id'] as String? ?? clientId;
        challengeId ??= d['challenge'] as String?;
        rights = d['rights'] == true;
        if (path != null && !File(path!).existsSync()) {
          error =
              'The media in this draft is no longer on this device. Discard the draft to choose another file.';
        }
      }
      if (Platform.isAndroid) {
        final lost = await picker.retrieveLostData();
        if (!mounted || draftOwner != app.account) return;
        if (!lost.isEmpty && lost.files != null && lost.files!.isNotEmpty) {
          await retain(lost.files!.first, lost.type == RetrieveType.video);
        }
      }
    } catch (e) {
      if (mounted)
        setState(
          () => error =
              'Your previous draft could not be opened. Choose media to start a new post.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> persist() async {
    if (!mounted) return;
    await draftStore.writeDraft(draftKey, {
      'caption': caption.text,
      'style': style,
      'path': path,
      'uploaded': uploaded,
      'video': video,
      'client_id': clientId,
      'challenge': challengeId,
      'rights': rights,
    });
  }

  void persistQuietly() {
    unawaited(
      persist().catchError((Object e) {
        if (mounted) setState(() => error = readableError(e));
      }),
    );
  }

  Future<void> discard() async {
    if (busy ||
        !await confirmAction(
          context,
          title: 'Discard this draft?',
          body:
              'Your selected media and caption will be removed from this draft. Posts already submitted will stay in your archive.',
          action: 'Discard draft',
        ) ||
        !mounted)
      return;
    setState(() => busy = true);
    try {
      final repository = VimiScope.of(context).repo;
      if (uploaded != null && repository != null) {
        await repository.removeMedia(uploaded!);
      }
      await draftStore.removeDraft(draftKey);
      if (path != null && await File(path!).exists())
        await File(path!).delete();
      if (!mounted) return;
      setState(() {
        caption.clear();
        path = uploaded = null;
        video = rights = false;
        clientId = const Uuid().v4();
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
    if (!mounted) return;
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
    rights = false;
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

  Future<void> captureDance() async {
    final record = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SurfacePanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VActionRow(
                  'Take photo',
                  glyph: Glyph.photo,
                  onPressed: () => Navigator.pop(ctx, false),
                ),
                VActionRow(
                  'Record video',
                  glyph: Glyph.video,
                  onPressed: () => Navigator.pop(ctx, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (record != null && mounted) await choose(ImageSource.camera, record);
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
    if (!app.signedIn) {
      setState(
        () => error =
            'Sign in before submitting your dance. Your draft stays on this device.',
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
        challenge: challengeId,
      );
      await draftStore.removeDraft(draftKey);
      final local = File(path!);
      if (await local.exists()) await local.delete();
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
        const SizedBox(height: 12),
        const Text(
          'Submitting uploads your selected photo or video to Vimi. Approved posts are visible to signed-in members.',
        ),
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
                : Image.file(
                    File(path!),
                    height: 320,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const ErrorNote(
                      'This draft media is unavailable. Discard the draft and choose another file.',
                    ),
                  ),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            VIconButton(
              Glyph.photo,
              label: 'Photo library',
              filled: true,
              onPressed: busy || uploaded != null
                  ? null
                  : () => choose(ImageSource.gallery, false),
            ),
            VIconButton(
              Glyph.video,
              label: 'Video library',
              filled: true,
              onPressed: busy || uploaded != null
                  ? null
                  : () => choose(ImageSource.gallery, true),
            ),
            VIconButton(
              Glyph.camera,
              label: 'Capture dance',
              filled: true,
              onPressed: busy || uploaded != null ? null : captureDance,
            ),
          ],
        ),
        const SizedBox(height: 24),
        ChoiceStrip(
          options: DanceStyle.values.map((s) => s.label).toList(),
          value: style,
          enabled: !busy,
          onChanged: (s) {
            setState(() => style = s);
            persistQuietly();
          },
        ),
        const SizedBox(height: 16),
        Text('Dance challenge', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ChoiceStrip(
          options: [
            'No challenge',
            ...VimiScope.of(context).challenges.map((c) => c.title),
          ],
          value: challengeId == null
              ? 'No challenge'
              : VimiScope.of(context).challenges
                        .where((c) => c.id == challengeId)
                        .map((c) => c.title)
                        .firstOrNull ??
                    'No challenge',
          enabled: !busy,
          onChanged: (title) {
            setState(
              () => challengeId = VimiScope.of(context).challenges
                  .where((c) => c.title == title)
                  .map((c) => c.id)
                  .firstOrNull,
            );
            persistQuietly();
          },
        ),
        const SizedBox(height: 20),
        VField(
          'What did you work on?',
          controller: caption,
          enabled: !busy,
          lines: 4,
          maxLength: 2000,
          onChanged: (_) => persistQuietly(),
        ),
        Row(
          children: [
            VIconButton(
              rights ? Glyph.check : Glyph.add,
              label: 'Confirm media and music rights',
              onPressed: busy
                  ? null
                  : () {
                      setState(() => rights = !rights);
                      persistQuietly();
                    },
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
        if (path != null || caption.text.isNotEmpty || error != null)
          VButton(
            'Discard draft',
            glyph: Glyph.delete,
            quiet: true,
            onPressed: busy ? null : discard,
          ),
        const SizedBox(height: 24),
      ],
    ),
  );
}
