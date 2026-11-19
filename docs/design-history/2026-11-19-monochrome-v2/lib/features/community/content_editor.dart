import 'package:flutter/material.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../design/vimi_ui.dart';

class EditContentPage extends StatefulWidget {
  const EditContentPage({
    super.key,
    required this.kind,
    required this.id,
    required this.text,
    this.style,
  });
  final String kind, id, text;
  final String? style;
  @override
  State<EditContentPage> createState() => _EditContentPageState();
}

class _EditContentPageState extends State<EditContentPage> {
  late final TextEditingController body;
  late String style;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    body = TextEditingController(text: widget.text);
    style = widget.style ?? 'K-pop';
  }

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy || body.text.trim().isEmpty) return;
    final app = VimiScope.of(context);
    setState(() => busy = true);
    try {
      await app.repo!.client.rpc(
        'edit_content',
        params: {
          'p_type': widget.kind,
          'p_id': widget.id,
          'p_body': body.text.trim(),
          'p_style': widget.kind == 'post' ? style : null,
        },
      );
      app.changed();
      if (mounted) {
        Navigator.pop(context);
        feedback(context, 'Changes submitted for review.');
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: widget.kind == 'post' ? 'Edit your dance' : 'Edit your comment',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (widget.kind == 'post')
          ChoiceStrip(
            options: DanceStyle.values.map((s) => s.label).toList(),
            value: style,
            onChanged: (s) => setState(() => style = s),
          ),
        VField(
          widget.kind == 'post' ? 'Caption' : 'Comment',
          controller: body,
          lines: 5,
          maxLength: widget.kind == 'post' ? 2000 : 1000,
          enabled: !busy,
        ),
        const Text('Edits are reviewed before appearing to other dancers.'),
        const SizedBox(height: 24),
        if (error != null) ErrorNote(error!),
        VButton('Save for review', busy: busy, onPressed: save),
      ],
    ),
  );
}
