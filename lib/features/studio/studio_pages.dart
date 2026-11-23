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
import 'rehearsal_player.dart';
import 'journal_recovery_page.dart';
import 'media_library_pages.dart';
import 'weekly_practice_goal.dart';

class StudioPage extends StatelessWidget {
  const StudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final type = Theme.of(context).textTheme;
    final noteCount = app.practices.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SurfacePanel(
          illuminated: true,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Practice journal', style: type.titleLarge),
                    const SizedBox(height: 4),
                    if (app.journalError == null)
                      Text(
                        noteCount == 0
                            ? 'No practice notes yet'
                            : '$noteCount saved ${noteCount == 1 ? 'note' : 'notes'}',
                        style: type.bodyMedium?.copyWith(
                          color: VimiColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              VIconButton(
                Glyph.clock,
                label: 'Open practice history',
                color: VimiColors.violet,
                onPressed: () => openPage(context, const PracticeHistoryPage()),
              ),
              const SizedBox(width: 8),
              VIconButton(
                Glyph.add,
                label: 'Start a practice note',
                primary: true,
                onPressed: app.journalError == null
                    ? () => openPage(context, const PracticeEditor())
                    : null,
              ),
            ],
          ),
        ),
        if (app.journalError case final error?) ...[
          const SizedBox(height: 8),
          ErrorNote(error, onRetry: () => unawaited(app.refreshAccount())),
        ],
        const SizedBox(height: 16),
        RehearsalShelf(
          practiceBuilder: (clip) => PracticeEditor(initialClip: clip),
        ),
        const SizedBox(height: 16),
        const WeeklyPracticeGoal(),
        if (app.journalError == null && noteCount > 0) ...[
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text('Recent notes', style: type.titleMedium),
          ),
          for (final practice in app.practices.take(3))
            _PracticeNoteRow(practice: practice),
        ],
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
          child: Text('Practice plans', style: type.titleMedium),
        ),
        for (final plan in StudioPack.all) _PracticePlanRow(plan: plan),
      ],
    );
  }
}

class PracticeHistoryPage extends StatefulWidget {
  const PracticeHistoryPage({super.key});

  @override
  State<PracticeHistoryPage> createState() => _PracticeHistoryPageState();
}

class _PracticeHistoryPageState extends State<PracticeHistoryPage> {
  final _search = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final error = app.journalError;
    final query = _search.text.trim().toLowerCase();
    final now = DateTime.now();
    final week = practiceWeek(now);
    final visibleNotes = app.practices.where((note) {
      final matchesFilter = switch (_filter) {
        'This week' =>
          !note.createdAt.isBefore(week.start) && !note.createdAt.isAfter(now),
        'With video' => note.videoPath?.isNotEmpty == true,
        _ => true,
      };
      return matchesFilter &&
          (query.isEmpty ||
              note.routine.toLowerCase().contains(query) ||
              note.style.toLowerCase().contains(query) ||
              note.notes.toLowerCase().contains(query));
    }).toList();
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: 1 + (error == null ? visibleNotes.length : 0),
        itemBuilder: (context, index) {
          if (index > 0)
            return _PracticeNoteRow(practice: visibleNotes[index - 1]);
          if (error != null) {
            return ErrorNote(
              error,
              onRetry: () => unawaited(app.refreshAccount()),
            );
          }
          if (app.practices.isEmpty) {
            return SurfacePanel(
              padding: const EdgeInsets.all(6),
              child: VActionRow(
                'Start a practice note',
                detail: 'Save a routine, video or rehearsal cue.',
                glyph: Glyph.studio,
                onPressed: startNote,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VField(
                'Search your journal',
                controller: _search,
                onChanged: (_) => setState(() {}),
              ),
              ChoiceStrip(
                options: const ['All', 'This week', 'With video'],
                value: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 16),
              if (visibleNotes.isEmpty)
                const EmptyNote(
                  'No matching notes',
                  'Try a different search or filter.',
                )
              else
                Text(
                  '${visibleNotes.length} ${visibleNotes.length == 1 ? 'note' : 'notes'}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: VimiColors.muted),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PracticeNoteRow extends StatelessWidget {
  const _PracticeNoteRow({required this.practice});
  final PracticeSession practice;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Open practice',
    child: _StudioRow(
      name: practice.routine,
      metadata:
          '${practice.style} · ${practice.minutes} min · ${displayDate(practice.createdAt)}',
      glyph: practice.videoPath == null ? Glyph.studio : Glyph.video,
      onPressed: () => openPage(context, PracticeEditor(session: practice)),
    ),
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

String _planProgressKey(String account, StudioPack plan) =>
    'pack-progress.v1.$account.${plan.id}';

Set<int> _checkedPlanSteps(
  LocalStudio studio,
  String account,
  StudioPack plan,
) {
  final saved = studio.preferences.get(_planProgressKey(account, plan));
  if (saved is! List) return {};
  return saved
      .whereType<String>()
      .map(int.tryParse)
      .whereType<int>()
      .where((index) => index >= 0 && index < plan.drills.length)
      .toSet();
}

class _PracticePlanRow extends StatelessWidget {
  const _PracticePlanRow({required this.plan});
  final StudioPack plan;

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final checked = _checkedPlanSteps(app.studio, app.account, plan).length;
    return _StudioRow(
      name: plan.title,
      metadata: checked == 0
          ? '${plan.drills.length} steps'
          : '$checked of ${plan.drills.length} steps complete',
      glyph: checked == plan.drills.length ? Glyph.check : Glyph.loop,
      onPressed: () => openPage(context, PracticePlanPage(plan: plan)),
    );
  }
}

class PracticePlanPage extends StatefulWidget {
  const PracticePlanPage({super.key, required this.plan});
  final StudioPack plan;

  @override
  State<PracticePlanPage> createState() => _PracticePlanPageState();
}

class _PracticePlanPageState extends State<PracticePlanPage> {
  bool busy = false;
  String? error;
  Set<int> checked = {};
  String? owner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (owner != app.account) {
      owner = app.account;
      checked = _checkedPlanSteps(app.studio, app.account, widget.plan);
      error = null;
    }
  }

  Future<void> saveProgress(Set<int> next) async {
    final app = VimiScope.of(context);
    final account = app.account;
    if (busy || owner != account) return;
    final preferences = app.studio.preferences;
    final key = _planProgressKey(account, widget.plan);
    final previous = checked;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final saved = await preferences.setStringList(
        key,
        next.map((index) => '$index').toList(),
      );
      if (!saved) {
        throw const FileSystemException(
          'Your progress could not be saved. Please try again.',
        );
      }
      if (mounted && app.account == account) {
        setState(() => checked = next);
        app.changed();
      }
    } catch (e) {
      // SharedPreferences changes its cache before the platform confirms a write.
      await preferences
          .setStringList(key, previous.map((index) => '$index').toList())
          .onError((_, _) => false);
      if (mounted && app.account == account) {
        setState(() => error = readableError(e));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetProgress() async {
    final app = VimiScope.of(context);
    final account = app.account;
    if (busy || checked.isEmpty) return;
    final confirmed = await confirmAction(
      context,
      title: 'Reset practice plan?',
      body: 'Clear the checked steps to use this plan again.',
      action: 'Reset progress',
    );
    if (confirmed && mounted && app.account == account) {
      await saveProgress({});
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final plan = widget.plan;
    final type = Theme.of(context).textTheme;
    final total = plan.drills.length;
    final progressLabel = '${checked.length} of $total steps complete';
    return PopScope(
      canPop: !busy,
      child: VPage(
        title: plan.title,
        actions: [
          if (checked.isNotEmpty)
            VIconButton(
              Glyph.refresh,
              label: 'Reset plan progress',
              color: VimiColors.cyan,
              onPressed: busy ? null : resetProgress,
            ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SurfacePanel(
              illuminated: true,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(plan.description, style: type.titleMedium),
                  const SizedBox(height: 16),
                  Text(
                    progressLabel,
                    style: type.bodyMedium?.copyWith(color: VimiColors.muted),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: checked.length / total,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                    color: VimiColors.cyan,
                    backgroundColor: VimiColors.tonal,
                    semanticsLabel: 'Practice plan progress',
                    semanticsValue: progressLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final (index, drill) in plan.drills.indexed)
              Semantics(
                checked: checked.contains(index),
                child: TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          final next = {...checked};
                          if (!next.add(index)) next.remove(index);
                          unawaited(saveProgress(next));
                        },
                  style: TextButton.styleFrom(
                    foregroundColor: VimiColors.ink,
                    minimumSize: const Size(48, 52),
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  ),
                  child: Row(
                    children: [
                      VIcon(
                        checked.contains(index) ? Glyph.check : Glyph.add,
                        size: 20,
                        color: checked.contains(index)
                            ? VimiColors.cyan
                            : VimiColors.violet,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(drill, style: type.bodyLarge)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (error case final message?) ...[
              ErrorNote(message),
              const SizedBox(height: 12),
            ],
            if (app.journalError == null)
              VButton(
                'Use in a practice note',
                glyph: Glyph.studio,
                onPressed: busy
                    ? null
                    : () => openPage(context, PracticeEditor(pack: plan)),
              )
            else
              VActionRow(
                'Open journal recovery',
                glyph: Glyph.studio,
                onPressed: busy
                    ? null
                    : () => openPage(context, const JournalRecoveryPage()),
              ),
          ],
        ),
      ),
    );
  }
}
