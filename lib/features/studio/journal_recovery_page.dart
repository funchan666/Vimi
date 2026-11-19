import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../design/vimi_ui.dart';

class JournalRecoveryPage extends StatefulWidget {
  const JournalRecoveryPage({super.key});
  @override
  State<JournalRecoveryPage> createState() => _JournalRecoveryPageState();
}

class _JournalRecoveryPageState extends State<JournalRecoveryPage> {
  bool busy = false;
  String? error, notice;
  Future<void> reset() async {
    if (busy ||
        !await confirmAction(
          context,
          title: 'Back up and start fresh?',
          body:
              'Your current journal data will be saved as a recovery copy on this device before a fresh journal is created. Personal videos are kept.',
          action: 'Back up and reset',
        ) ||
        !mounted)
      return;
    final app = VimiScope.of(context);
    setState(() {
      busy = true;
      error = notice = null;
    });
    try {
      await app.studio.backupAndReset(app.account);
      await app.refreshAccount();
      if (mounted)
        setState(
          () => notice =
              'Your fresh journal is ready. The recovery copy is below.',
        );
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restore(String key) async {
    if (busy ||
        !await confirmAction(
          context,
          title: 'Restore this journal copy?',
          body:
              'Your current journal will be backed up before this copy replaces it.',
          action: 'Restore copy',
        ) ||
        !mounted)
      return;
    final app = VimiScope.of(context);
    setState(() {
      busy = true;
      error = notice = null;
    });
    try {
      await app.studio.restoreBackup(app.account, key);
      await app.refreshAccount();
      if (mounted)
        setState(
          () => notice = 'Journal restored. Open Studio to see your notes.',
        );
    } catch (_) {
      if (mounted)
        setState(
          () => error =
              'This copy could not be restored. Your current journal was kept. You can copy the original recovery data.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final copies = app.studio.recoveryCopies(app.account);
    return VPage(
      title: 'Journal recovery',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SurfacePanel(
            illuminated: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep your practice safe.',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Recovery copies stay on this device in this account. Resetting the journal keeps your original data and personal videos.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (error != null) ErrorNote(error!),
          if (notice != null)
            Text(notice!, style: const TextStyle(color: VimiColors.cyan)),
          const SizedBox(height: 12),
          VButton('Back up and start fresh', busy: busy, onPressed: reset),
          const SizedBox(height: 28),
          Text(
            'Recovery copies',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (copies.isEmpty)
            const EmptyNote(
              'No copies yet.',
              'A recovery copy is created before a journal reset or restore.',
            ),
          for (final copy in copies)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayDate(DateTime.parse(copy['created_at'] as String)),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    VButton(
                      'Restore copy',
                      tonal: true,
                      onPressed: busy
                          ? null
                          : () => restore(copy['key'] as String),
                    ),
                    VButton(
                      'Copy recovery data',
                      quiet: true,
                      onPressed: busy
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: copy['raw'] as String),
                              );
                              if (context.mounted)
                                feedback(context, 'Recovery data copied.');
                            },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
