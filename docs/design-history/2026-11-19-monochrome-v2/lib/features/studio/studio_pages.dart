import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';
import '../wallet/wallet_page.dart';
import 'rehearsal_player.dart';

class StudioPage extends StatelessWidget {
  const StudioPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Your practice.', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 16),
        const Text(
          'Keep your routines, rehearsal videos and next steps together.',
        ),
        const SizedBox(height: 24),
        VButton(
          'Start a practice note',
          glyph: Glyph.add,

          onPressed: () => openPage(context, const PracticeEditor()),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Text(
                'Your rehearsal journal',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Text('${app.practices.length} saved'),
          ],
        ),
        if (app.journalError != null)
          ErrorNote(
            app.journalError!,
            onRetry: () => unawaited(app.refreshAccount()),
          ),
        if (app.practices.isEmpty && app.journalError == null)
          const EmptyNote(
            'Remember what clicked.',
            'Save a routine, your tempo and one thing to try next time.',
          ),
        for (final practice in app.practices)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SurfacePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    practice.routine,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${practice.style} · ${practice.minutes} min · ${practice.counts} eights · ${displayDate(practice.createdAt)}',
                    style: const TextStyle(color: VimiColors.muted),
                  ),
                  if (practice.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      practice.notes,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  VButton(
                    'Open practice',
                    quiet: true,
                    onPressed: () =>
                        openPage(context, PracticeEditor(session: practice)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 40),
        Text(
          'Build a practice habit',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Reusable planning packs. Your everyday journal is always free.',
        ),
        for (final pack in StudioPack.all)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(pack.description),
                const SizedBox(height: 8),
                VButton(
                  app.unlocked.contains(pack.id)
                      ? 'Open your pack'
                      : 'See pack · ${pack.cost} coins',
                  glyph: app.unlocked.contains(pack.id)
                      ? Glyph.check
                      : Glyph.coin,
                  quiet: true,
                  onPressed: () =>
                      openPage(context, StudioPackPage(pack: pack)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PracticeEditor extends StatefulWidget {
  const PracticeEditor({super.key, this.session, this.pack});
  final PracticeSession? session;
  final StudioPack? pack;
  @override
  State<PracticeEditor> createState() => _PracticeEditorState();
}

class _PracticeEditorState extends State<PracticeEditor> {
  final routine = TextEditingController(),
      minutes = TextEditingController(text: '20'),
      counts = TextEditingController(text: '4'),
      bpm = TextEditingController(text: '100'),
      notes = TextEditingController();
  String style = 'K-pop';
  String? video, error;
  bool busy = false, ready = false;
  String id = const Uuid().v4();
  SharedPreferences? preferences;
  String? draftKey;
  void persistDraft() {
    final prefs = preferences, key = draftKey;
    if (!ready || prefs == null || key == null) return;
    unawaited(
      prefs.setString(
        key,
        jsonEncode({
          'id': id,
          'routine': routine.text,
          'minutes': minutes.text,
          'counts': counts.text,
          'bpm': bpm.text,
          'notes': notes.text,
          'style': style,
          'video': video,
        }),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    final app = VimiScope.of(context);
    preferences = app.studio.preferences;
    draftKey =
        'practice-draft.v1.${app.account}.${widget.session?.id ?? widget.pack?.id ?? 'new'}';
    final raw = preferences!.getString(draftKey!);
    if (raw != null) {
      try {
        final d = jsonMap(jsonDecode(raw));
        id = d['id'] as String;
        routine.text = d['routine'] as String;
        minutes.text = d['minutes'] as String;
        counts.text = d['counts'] as String;
        bpm.text = d['bpm'] as String;
        notes.text = d['notes'] as String;
        style = d['style'] as String;
        video = d['video'] as String?;
      } catch (_) {
        error =
            'Your draft could not be opened. The original saved note has been kept.';
      }
    }
    ready = true;
    for (final c in [routine, minutes, counts, bpm, notes]) {
      c.addListener(persistDraft);
    }
  }

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    if (s != null) {
      id = s.id;
      routine.text = s.routine;
      minutes.text = '${s.minutes}';
      counts.text = '${s.counts}';
      bpm.text = '${s.bpm}';
      notes.text = s.notes;
      style = s.style;
      video = s.videoPath;
    } else if (widget.pack != null) {
      routine.text = widget.pack!.title;
      notes.text = widget.pack!.drills.join('\n\n');
    }
  }

  Future<void> chooseVideo() async {
    if (busy) return;
    setState(() => busy = true);
    PlaybackCoordinator.pauseAll();
    try {
      final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (file != null && mounted) {
        final app = VimiScope.of(context);
        final owner = app.account;
        final retained = await app.studio.retainVideo(owner, file.path);
        if (mounted && owner == app.account) setState(() => video = retained);
        persistDraft();
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy) return;
    final time = int.tryParse(minutes.text),
        phrases = int.tryParse(counts.text),
        tempo = int.tryParse(bpm.text);
    if (routine.text.trim().isEmpty ||
        time == null ||
        time < 1 ||
        time > 240 ||
        phrases == null ||
        phrases < 1 ||
        phrases > 64 ||
        tempo == null ||
        tempo < 20 ||
        tempo > 240) {
      setState(
        () => error =
            'Add a routine, 1–240 minutes, 1–64 eight-count phrases and a tempo from 20–240 BPM.',
      );
      return;
    }
    setState(() => busy = true);
    try {
      await VimiScope.of(context).savePractice(
        PracticeSession(
          id: id,
          routine: routine.text.trim(),
          style: style,
          minutes: time,
          counts: phrases,
          bpm: tempo,
          notes: notes.text.trim(),
          createdAt: widget.session?.createdAt ?? DateTime.now(),
          videoPath: video,
          packId: widget.pack?.id ?? widget.session?.packId,
        ),
      );
      if (draftKey != null) await preferences!.remove(draftKey!);
      if (mounted) {
        ready = false;
        Navigator.pop(context);
        feedback(context, 'Practice saved.');
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    persistDraft();
    for (final c in [routine, minutes, counts, bpm, notes]) {
      c.removeListener(persistDraft);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: widget.session == null
        ? 'A note for your next eight'
        : 'Your rehearsal',
    child: ListView(
      padding: const EdgeInsets.all(24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        VField('Routine or song', controller: routine, maxLength: 100),
        ChoiceStrip(
          options: DanceStyle.values.map((s) => s.label).toList(),
          value: style,
          onChanged: (s) {
            setState(() => style = s);
            persistDraft();
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          children: [
            SizedBox(
              width: 135,
              child: VField(
                'Minutes',
                controller: minutes,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: 135,
              child: VField(
                'Eight-count phrases',
                controller: counts,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: 135,
              child: VField(
                'Tempo · BPM',
                controller: bpm,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        VField(
          'What clicked? What is next?',
          controller: notes,
          lines: 6,
          maxLength: 4000,
        ),
        if (video != null && File(video!).existsSync()) ...[
          RehearsalPlayer(source: video!, practice: true),
          VButton(
            'Remove video from this note',
            quiet: true,
            onPressed: () {
              setState(() => video = null);
              persistDraft();
            },
          ),
        ],
        VButton(
          video == null ? 'Add your rehearsal video' : 'Choose another video',
          glyph: Glyph.video,
          quiet: true,
          onPressed: busy ? null : chooseVideo,
        ),
        const SizedBox(height: 16),
        if (error != null) ErrorNote(error!),
        VButton('Save practice', busy: busy, onPressed: save),
        if (widget.session != null)
          VButton(
            'Delete practice note',
            glyph: Glyph.delete,
            quiet: true,
            onPressed: () async {
              if (!await confirmAction(
                    context,
                    title: 'Delete this practice note?',
                    body: 'This journal entry will be removed.',
                    action: 'Delete note',
                  ) ||
                  !context.mounted)
                return;
              try {
                await VimiScope.of(context).removePractice(id);
                ready = false;
                if (draftKey != null) await preferences!.remove(draftKey!);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) feedback(context, readableError(e));
              }
            },
          ),
      ],
    ),
  );
}

class StudioPackPage extends StatefulWidget {
  const StudioPackPage({super.key, required this.pack});
  final StudioPack pack;
  @override
  State<StudioPackPage> createState() => _StudioPackPageState();
}

class _StudioPackPageState extends State<StudioPackPage> {
  bool busy = false;
  String? error;
  Set<int> checked = {};
  String? owner;
  String keyFor(String account) =>
      'pack-progress.v1.$account.${widget.pack.id}';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (owner != app.account) {
      owner = app.account;
      checked =
          (app.studio.preferences.getStringList(keyFor(app.account)) ?? [])
              .map(int.parse)
              .toSet();
    }
  }

  Future<void> unlock() async {
    if (busy || !await requireSignIn(context) || !mounted) return;
    final app = VimiScope.of(context), pack = widget.pack;
    if (app.coins < pack.cost) {
      await openPage(context, const WalletPage());
      return;
    }
    if (!await confirmAction(
          context,
          title: 'Unlock ${pack.title}?',
          body:
              'Spend ${pack.cost} coins once for this planning pack. It stays available in your account.',
          action: 'Unlock · ${pack.cost} coins',
        ) ||
        !mounted)
      return;
    setState(() => busy = true);
    try {
      await app.repo!.unlock(pack.id);
      await app.refreshWallet();
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final pack = widget.pack;
    final unlocked = app.unlocked.contains(pack.id);
    return VPage(
      title: pack.title,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            pack.description,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text(
            unlocked ? 'Your practice sequence' : 'What is inside',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < pack.drills.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (unlocked)
                    VIconButton(
                      checked.contains(i) ? Glyph.check : Glyph.add,
                      label:
                          '${checked.contains(i) ? 'Uncheck' : 'Complete'} step ${i + 1}',
                      onPressed: () async {
                        final index = i;
                        final next = {...checked};
                        if (!next.add(index)) next.remove(index);
                        final ok = await app.studio.preferences.setStringList(
                          keyFor(app.account),
                          next.map((n) => '$n').toList(),
                        );
                        if (mounted && ok) setState(() => checked = next);
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 12),
                      child: Text('${i + 1}.'),
                    ),
                  Expanded(
                    child: Text(
                      pack.drills[i],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (error != null) ErrorNote(error!),
          if (unlocked)
            VButton(
              'Use in a practice note',

              onPressed: () => openPage(context, PracticeEditor(pack: pack)),
            )
          else
            VButton(
              'Unlock · ${pack.cost} coins',
              glyph: Glyph.coin,
              busy: busy,
              onPressed: unlock,
            ),
          VButton(
            'Your coin wallet',
            quiet: true,
            onPressed: () async {
              if (await requireSignIn(context) && context.mounted)
                await openPage(context, const WalletPage());
            },
          ),
        ],
      ),
    );
  }
}
