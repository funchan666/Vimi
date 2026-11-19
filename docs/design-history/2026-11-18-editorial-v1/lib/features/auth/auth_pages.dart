import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../design/vimi_ui.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/ui/floor.webp',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: box.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/ui/app_icon.webp',
                                    width: 52,
                                    height: 52,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'vimi',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displaySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Find your people.\nFeel every eight.',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 12),
                            const SizedBox(
                              width: 265,
                              child: Text(
                                'K-pop covers, shared practice,\nand a floor for your next move.',
                                style: TextStyle(fontSize: 16, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 240),
                          child: Paper(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                VButton(
                                  'Join the floor',
                                  lime: true,
                                  onPressed: () => openPage(
                                    context,
                                    const AuthPage(signUp: true),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                VButton(
                                  'I already have an account',
                                  onPressed: () => openPage(
                                    context,
                                    const AuthPage(signUp: false),
                                  ),
                                ),
                                VButton(
                                  'Explore the studio',
                                  quiet: true,
                                  onPressed: app.explore,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> requireSignIn(BuildContext context) async {
  if (VimiScope.of(context).signedIn) return true;
  await openPage(context, const AuthPage(signUp: false));
  return context.mounted && VimiScope.of(context).signedIn;
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.signUp});
  final bool signUp;
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController(),
      birth = TextEditingController();
  bool consent = false, busy = false;
  String? error, notice;
  @override
  void dispose() {
    for (final c in [email, password, name, birth]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final app = VimiScope.of(context);
    final auth = app.repo?.client.auth;
    if (auth == null) {
      setState(
        () => error =
            'Sign-in is unavailable right now. You can still explore the studio.',
      );
      return;
    }
    final address = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address) ||
        password.text.length < 8) {
      setState(
        () => error =
            'Enter a valid email and a password with at least 8 characters.',
      );
      return;
    }
    if (!consent) {
      setState(
        () => error = 'Please accept the Terms and Privacy Policy to continue.',
      );
      return;
    }
    if (widget.signUp) {
      final birthday = DateTime.tryParse(birth.text.trim());
      final now = DateTime.now();
      final adult = DateTime(now.year - 18, now.month, now.day);
      if (name.text.trim().length < 2 ||
          name.text.trim().length > 40 ||
          birthday == null ||
          birthday.isAfter(adult) ||
          birthday.year < 1900 ||
          birthday.toIso8601String().substring(0, 10) != birth.text.trim()) {
        setState(
          () => error =
              'Add a name and your date of birth as YYYY-MM-DD. Vimi is for ages 18 and over.',
        );
        return;
      }
    }
    setState(() {
      busy = true;
      error = null;
      notice = null;
    });
    try {
      if (widget.signUp) {
        final response = await auth.signUp(
          email: address,
          password: password.text,
          emailRedirectTo: 'com.vimistudio.vimi://auth-callback/',
          data: {
            'display_name': name.text.trim(),
            'birth_date': birth.text.trim(),
            'consent_version': '2026-11-18',
          },
        );
        if (response.session == null && mounted)
          setState(
            () => notice =
                'Check your email to confirm your account, then sign in.',
          );
      } else {
        await auth.signInWithPassword(email: address, password: password.text);
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: widget.signUp ? 'Your first eight' : 'Back on the floor',
    art: 'profile',
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            Text(
              widget.signUp
                  ? 'A place for your\nkind of movement.'
                  : 'Good to have\nyou back.',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 32),
            if (widget.signUp)
              VField('Display name', controller: name, maxLength: 40),
            VField(
              'Email',
              controller: email,
              keyboardType: TextInputType.emailAddress,
            ),
            VField('Password', controller: password, obscure: true),
            if (widget.signUp) ...[
              VField(
                'Date of birth · YYYY-MM-DD',
                controller: birth,
                keyboardType: TextInputType.datetime,
              ),
              const Text(
                'An adult community, for ages 18 and over.',
                style: TextStyle(color: VimiColors.muted),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VIconButton(
                  consent ? Glyph.check : Glyph.add,
                  label: consent
                      ? 'Withdraw agreement'
                      : 'Accept Terms and Privacy Policy',
                  onPressed: () => setState(() => consent = !consent),
                ),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('I agree to the '),
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          const LegalPage('Terms of Use', 'terms'),
                        ),
                        child: const Text('Terms'),
                      ),
                      const Text(' and '),
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          const LegalPage('Privacy Policy', 'privacy'),
                        ),
                        child: const Text('Privacy Policy'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              ErrorNote(error!),
            ],
            if (notice != null) ...[
              const SizedBox(height: 16),
              Paper(child: Text(notice!)),
            ],
            const SizedBox(height: 24),
            VButton(
              widget.signUp ? 'Create account' : 'Sign in',
              busy: busy,
              onPressed: submit,
              lime: true,
            ),
            if (!widget.signUp)
              VButton(
                'Forgot password?',
                quiet: true,
                onPressed: () => openPage(context, const RecoverAccountPage()),
              ),
            if (widget.signUp && notice != null)
              VButton(
                'Continue to sign in',
                quiet: true,
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthPage(signUp: false),
                  ),
                ),
              ),
            VButton(
              widget.signUp
                  ? 'Already a member? Sign in'
                  : 'New here? Create an account',
              quiet: true,
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AuthPage(signUp: !widget.signUp),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class RecoverAccountPage extends StatefulWidget {
  const RecoverAccountPage({super.key});
  @override
  State<RecoverAccountPage> createState() => _RecoverAccountPageState();
}

class _RecoverAccountPageState extends State<RecoverAccountPage> {
  final email = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> recover() async {
    final app = VimiScope.of(context);
    if (busy || app.repo == null) return;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.text.trim())) {
      setState(() => message = 'Enter a valid email address.');
      return;
    }
    setState(() => busy = true);
    try {
      await app.repo!.client.auth.resetPasswordForEmail(
        email.text.trim(),
        redirectTo: 'com.vimistudio.vimi://auth-callback/',
      );
      if (mounted)
        setState(
          () => message =
              'If an account uses this email, a recovery link is on its way.',
        );
    } catch (e) {
      if (mounted) setState(() => message = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'Find your way back',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Enter your account email. Open the recovery link on this device to choose a new password.',
        ),
        const SizedBox(height: 24),
        VField(
          'Email',
          controller: email,
          keyboardType: TextInputType.emailAddress,
        ),
        VButton('Send recovery link', onPressed: recover, busy: busy),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(message!),
          ),
      ],
    ),
  );
}

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key, required this.onSaved});
  final VoidCallback onSaved;
  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    if (password.text.length < 8) {
      setState(() => error = 'Use at least 8 characters.');
      return;
    }
    setState(() => busy = true);
    try {
      await VimiScope.of(
        context,
      ).repo!.client.auth.updateUser(UserAttributes(password: password.text));
      if (mounted) widget.onSaved();
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'A fresh password',
    back: false,
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        VField('New password', controller: password, obscure: true),
        if (error != null) ErrorNote(error!),
        VButton('Save password', onPressed: save, busy: busy),
      ],
    ),
  );
}

class LegalPage extends StatelessWidget {
  const LegalPage(this.title, this.file, {super.key});
  final String title, file;
  @override
  Widget build(BuildContext context) => VPage(
    title: title,
    child: FutureBuilder<String>(
      future: rootBundle.loadString('assets/legal/$file.txt'),
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SelectableText(
            snapshot.data ?? 'Opening…',
            style: const TextStyle(fontSize: 16, height: 1.65),
          ),
        ],
      ),
    ),
  );
}
