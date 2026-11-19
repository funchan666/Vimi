import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../design/vimi_ui.dart';
import 'auth_pages.dart';

class EmailConfirmationPage extends StatefulWidget {
  const EmailConfirmationPage({super.key, required this.email});
  final String email;
  @override
  State<EmailConfirmationPage> createState() => _EmailConfirmationPageState();
}

class _EmailConfirmationPageState extends State<EmailConfirmationPage> {
  bool busy = false;
  String? error, notice;
  Future<void> resend() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = notice = null;
    });
    try {
      final auth = VimiScope.of(context).repo?.client.auth;
      if (auth == null) throw StateError('Sign-in is unavailable.');
      await auth.resend(
        type: OtpType.signup,
        email: widget.email,
        emailRedirectTo: 'com.vimistudio.vimi://auth-callback/',
      );
      if (mounted)
        setState(
          () => notice =
              'A new confirmation link was requested. Check your inbox and spam folder.',
        );
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'Check your email',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SurfacePanel(
          illuminated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VIcon(Glyph.inbox, color: VimiColors.cyan, size: 40),
              const SizedBox(height: 20),
              Text(
                'One more step to your crew.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Open the confirmation link sent to ${widget.email}. Then return to Vimi to sign in.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (notice != null)
          Text(notice!, style: const TextStyle(color: VimiColors.cyan)),
        if (error != null) ErrorNote(error!),
        VButton(
          'I confirmed · sign in',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  AuthPage(signUp: false, initialEmail: widget.email),
            ),
          ),
        ),
        const SizedBox(height: 12),
        VButton(
          'Resend confirmation email',
          quiet: true,
          busy: busy,
          onPressed: resend,
        ),
        VButton(
          'Use another email',
          quiet: true,
          onPressed: busy
              ? null
              : () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AuthPage(signUp: true),
                  ),
                ),
        ),
      ],
    ),
  );
}

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final current = TextEditingController(),
      next = TextEditingController(),
      confirmation = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    if (current.text.isEmpty ||
        next.text.length < 8 ||
        next.text != confirmation.text) {
      setState(
        () => error =
            'Enter your current password and matching new passwords with at least 8 characters.',
      );
      return;
    }
    final app = VimiScope.of(context);
    final owner = app.account;
    final auth = app.repo!.client.auth;
    final email = auth.currentUser?.email;
    if (email == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await auth.signInWithPassword(email: email, password: current.text);
      if (app.account != owner) return;
      await auth.updateUser(UserAttributes(password: next.text));
      if (mounted) {
        Navigator.pop(context);
        feedback(context, 'Password updated.');
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'Change password',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Confirm your current password to protect your account.'),
        const SizedBox(height: 24),
        VField(
          'Current password',
          controller: current,
          obscure: true,
          enabled: !busy,
        ),
        VField('New password', controller: next, obscure: true, enabled: !busy),
        VField(
          'Confirm new password',
          controller: confirmation,
          obscure: true,
          enabled: !busy,
        ),
        if (error != null) ErrorNote(error!),
        VButton('Update password', busy: busy, onPressed: save),
      ],
    ),
  );
}
