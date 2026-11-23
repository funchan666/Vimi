import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_controller.dart';
import '../../core/local_studio.dart';
import '../../design/vimi_ui.dart';

class WeeklyPracticeGoal extends StatefulWidget {
  const WeeklyPracticeGoal({super.key});

  @override
  State<WeeklyPracticeGoal> createState() => _WeeklyPracticeGoalState();
}

class _WeeklyPracticeGoalState extends State<WeeklyPracticeGoal>
    with WidgetsBindingObserver {
  Timer? _rollover;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleRollover();
  }

  void _scheduleRollover() {
    _rollover?.cancel();
    final now = DateTime.now();
    _rollover = Timer(practiceWeek(now).end.difference(now), _refreshWeek);
  }

  void _refreshWeek() {
    if (!mounted) return;
    setState(() {});
    _scheduleRollover();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshWeek();
  }

  @override
  void dispose() {
    _rollover?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _editGoal() async {
    final app = VimiScope.of(context);
    final owner = app.account;
    final saved = await openPage<bool>(
      context,
      _WeeklyGoalEditor(
        owner: owner,
        initialMinutes: app.studio.weeklyPracticeGoal(owner) ?? 60,
      ),
    );
    if (saved == true && mounted && app.account == owner) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final target = app.studio.weeklyPracticeGoal(app.account);
    final minutes = app.journalError == null
        ? practiceMinutesThisWeek(app.practices, DateTime.now())
        : null;
    if (target == null) {
      return SurfacePanel(
        padding: EdgeInsets.zero,
        child: VActionRow(
          'Set a weekly goal',
          detail: minutes == null
              ? 'Set a target in minutes'
              : '$minutes min logged this week',
          glyph: Glyph.clock,
          onPressed: _editGoal,
        ),
      );
    }

    final reached = minutes != null && minutes >= target;
    return SurfacePanel(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              VIcon(
                reached ? Glyph.check : Glyph.clock,
                size: 20,
                color: VimiColors.cyan,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reached ? 'Weekly goal reached' : 'Weekly practice goal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              VIconButton(
                Glyph.edit,
                label: 'Edit weekly goal',
                color: VimiColors.cyan,
                onPressed: _editGoal,
              ),
            ],
          ),
          Text(
            minutes == null
                ? 'Progress unavailable · $target min target'
                : '$minutes of $target min this week',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: VimiColors.muted),
          ),
          if (minutes != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: LinearProgressIndicator(
                value: (minutes / target).clamp(0.0, 1.0),
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
                color: VimiColors.cyan,
                backgroundColor: VimiColors.tonal,
                semanticsLabel: 'Weekly practice progress',
                semanticsValue: '$minutes of $target minutes',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyGoalEditor extends StatefulWidget {
  const _WeeklyGoalEditor({required this.owner, required this.initialMinutes});

  final String owner;
  final int initialMinutes;

  @override
  State<_WeeklyGoalEditor> createState() => _WeeklyGoalEditorState();
}

class _WeeklyGoalEditorState extends State<_WeeklyGoalEditor> {
  late final _minutes = TextEditingController(text: '${widget.initialMinutes}');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = VimiScope.of(context);
    if (_saving || app.account != widget.owner || app.accountStatus != 'active')
      return;
    final target = int.tryParse(_minutes.text.trim());
    if (target == null ||
        target < 1 ||
        target > LocalStudio.maxWeeklyPracticeGoal) {
      setState(() => _error = 'Enter 1–10,080 minutes.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await app.studio.setWeeklyPracticeGoal(widget.owner, target);
      if (mounted && app.account == widget.owner) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted && app.account == widget.owner) {
        setState(
          () => _error = 'Your weekly goal could not be saved. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return PopScope(
      canPop: !_saving,
      child: VPage(
        title: 'Weekly practice goal',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'Practice notes count toward your goal from Monday to Sunday.',
            ),
            const SizedBox(height: 16),
            VField(
              'Minutes per week',
              controller: _minutes,
              keyboardType: TextInputType.number,
              enabled: !_saving,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error case final message?) ...[
              ErrorNote(message),
              const SizedBox(height: 12),
            ],
            VButton(
              'Save goal',
              glyph: Glyph.check,
              busy: _saving,
              onPressed:
                  app.account == widget.owner && app.accountStatus == 'active'
                  ? _save
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
