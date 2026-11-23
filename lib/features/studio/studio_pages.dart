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
import '../../core/local_studio.dart';
import '../../core/media_library.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';
import '../wallet/wallet_page.dart';
import 'rehearsal_player.dart';
import 'journal_recovery_page.dart';
import 'media_library_pages.dart';
import 'weekly_practice_goal.dart';

class StudioPage extends StatelessWidget {
  const StudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final minutes = app.practices
        .where((practice) => !practice.createdAt.isBefore(cutoff))
        .fold(0, (total, practice) => total + practice.minutes);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        RehearsalShelf(
          practiceBuilder: (clip) => PracticeEditor(initialClip: clip),
        ),
        const SizedBox(height: 12),
        const WeeklyPracticeGoal(),
        const SizedBox(height: 20),
        SurfacePanel(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              const VIcon(Glyph.studio, size: 20, color: VimiColors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Practice journal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (app.journalError == null)
                      Text(
                        app.practices.isEmpty
                            ? 'No practice notes yet'
                            : '$minutes min · Last 7 days',
                        style: const TextStyle(
                          fontSize: 12,
                          color: VimiColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              VIconButton(
                Glyph.more,
                label: 'Journal recovery',
                color: VimiColors.muted,
                onPressed: () => openPage(context, const JournalRecoveryPage()),
              ),
              VIconButton(
                Glyph.add,
                label: 'Start a practice note',
                color: VimiColors.cyan,
                onPressed: () => openPage(context, const PracticeEditor()),
              ),
            ],
          ),
        ),
        if (app.journalError case final error?)
          ErrorNote(error, onRetry: () => unawaited(app.refreshAccount())),
        for (final practice in app.practices)
          Tooltip(
            message: 'Open practice',
            child: _PracticeNoteRow(practice: practice),
          ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text(
            'Practice packs',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        for (final pack in StudioPack.all)
          Tooltip(
            message: app.unlocked.contains(pack.id)
                ? 'Open your pack'
                : 'See pack · ${pack.cost} coins',
            child: _StudioRow(
              name: pack.title,
              metadata: app.unlocked.contains(pack.id)
                  ? 'Unlocked'
                  : '${pack.cost} coins',
              glyph: app.unlocked.contains(pack.id) ? Glyph.check : Glyph.coin,
              onPressed: () => openPage(context, StudioPackPage(pack: pack)),
            ),
          ),
      ],
    );
  }
}

class PracticeHistoryPage extends StatelessWidget {
  const PracticeHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final error = app.journalError;
    void startNote() => openPage(context, const PracticeEditor());

    return VPage(
      title: 'Practice history',
      actions: [
        VIconButton(
          Glyph.more,
          label: 'Journal recovery',
          onPressed: () => openPage(context, const JournalRecoveryPage()),
        ),
        if (error == null && app.practices.isNotEmpty)
          VIconButton(
            Glyph.add,
            label: 'Start a practice note',
            color: VimiColors.cyan,
            onPressed: startNote,
          ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (error != null)
            ErrorNote(error, onRetry: () => unawaited(app.refreshAccount()))
          else if (app.practices.isEmpty)
            SurfacePanel(
              padding: const EdgeInsets.all(6),
              child: VActionRow(
                'Start a practice note',
                detail: 'Save a routine, video or rehearsal cue.',
                glyph: Glyph.studio,
                onPressed: startNote,
              ),
            ),
          for (final practice in app.practices)
            Tooltip(
              message: 'Open practice',
              child: _PracticeNoteRow(practice: practice),
            ),
        ],
      ),
    );
  }
}

class _PracticeNoteRow extends StatelessWidget {
  const _PracticeNoteRow({required this.practice});
  final PracticeSession practice;

  @override
  Widget build(BuildContext context) => _StudioRow(
    name: practice.routine,
    metadata:
        '${practice.minutes} min · ${practice.counts} eights · ${displayDate(practice.createdAt)}',
    glyph: practice.videoPath == null ? Glyph.studio : Glyph.video,
    onPressed: () => openPage(context, PracticeEditor(session: practice)),
  );
}

class _StudioRow extends StatelessWidget {
  const _StudioRow({
    required this.name,
    required this.metadata,
    required this.glyph,
    required this.onPressed,
  });
  final String name, metadata;
  final Glyph glyph;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: VimiColors.ink,
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    ),
    child: Row(
      children: [
        VIcon(glyph, size: 20, color: VimiColors.violet),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                metadata,
                style: const TextStyle(fontSize: 12, color: VimiColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const VIcon(Glyph.next, size: 14, color: VimiColors.muted),
      ],
    ),
  );
}

class PracticeEditor extends StatefulWidget {
  const PracticeEditor({super.key, this.session, this.pack, this.initialClip});
  final PracticeSession? session;
  final StudioPack? pack;
  final LibraryClip? initialClip;
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
  LocalStudio? draftStore;
  String? draftKey;
  void persistDraft() {
    final prefs = preferences, key = draftKey;
    if (!ready || prefs == null || key == null) return;
    unawaited(
      draftStore!
          .writeDraft(key, {
            'id': id,
            'routine': routine.text,
            'minutes': minutes.text,
            'counts': counts.text,
            'bpm': bpm.text,
            'notes': notes.text,
            'style': style,
            'video': video,
          })
          .catchError((Object e) {
            if (mounted) setState(() => error = readableError(e));
          }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    final app = VimiScope.of(context);
    preferences = app.studio.preferences;
    draftStore = app.studio;
    draftKey =
        'practice-draft.v1.${app.account}.${widget.session?.id ?? widget.pack?.id ?? widget.initialClip?.id ?? 'new'}';
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
    } else if (widget.initialClip != null) {
      routine.text = widget.initialClip!.title;
      video = widget.initialClip!.source;
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
      if (draftKey != null) await draftStore!.removeDraft(draftKey!);
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
        VField(
          'Routine or song',
          controller: routine,
          maxLength: 100,
          enabled: !busy,
        ),
        ChoiceStrip(
          options: DanceStyle.values.map((s) => s.label).toList(),
          value: style,
          enabled: !busy,
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
                enabled: !busy,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: 175,
              child: VField(
                'Eight-count phrases',
                controller: counts,
                enabled: !busy,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: 135,
              child: VField(
                'Tempo · BPM',
                controller: bpm,
                enabled: !busy,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        VField(
          'What clicked? What is next?',
          controller: notes,
          enabled: !busy,
          lines: 6,
          maxLength: 4000,
        ),
        if (video != null &&
            (isLibraryVideo(video!) || File(video!).existsSync())) ...[
          RehearsalPlayer(source: video!, practice: true),
          VIconButton(
            Glyph.close,
            label: 'Remove video from this note',
            onPressed: busy
                ? null
                : () {
                    setState(() => video = null);
                    persistDraft();
                  },
          ),
        ],
        VActionRow(
          video == null ? 'Add your rehearsal video' : 'Choose another video',
          glyph: Glyph.video,
          onPressed: busy ? null : chooseVideo,
        ),
        const SizedBox(height: 16),
        if (error != null) ErrorNote(error!),
        VButton('Save practice', busy: busy, onPressed: save),
        if (widget.session != null)
          VIconButton(
            Glyph.delete,
            label: 'Delete practice note',
            color: VimiColors.danger,
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
                if (draftKey != null) await draftStore!.removeDraft(draftKey!);
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
              .map(int.tryParse)
              .whereType<int>()
              .where((index) => index >= 0 && index < widget.pack.drills.length)
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
                      onPressed: busy
                          ? null
                          : () async {
                              final account = app.account;
                              final index = i;
                              final next = {...checked};
                              if (!next.add(index)) next.remove(index);
                              setState(() => busy = true);
                              try {
                                final ok = await app.studio.preferences
                                    .setStringList(
                                      keyFor(account),
                                      next.map((n) => '$n').toList(),
                                    );
                                if (!ok)
                                  throw const FileSystemException(
                                    'Your progress could not be saved. Please try again.',
                                  );
                                if (mounted && app.account == account)
                                  setState(() => checked = next);
                              } catch (e) {
                                if (mounted)
                                  setState(() => error = readableError(e));
                              } finally {
                                if (mounted) setState(() => busy = false);
                              }
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
