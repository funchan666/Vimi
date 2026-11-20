import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../design/vimi_ui.dart';
import 'account_security_pages.dart';
import 'welcome_scene.dart';
import '../studio/media_library_pages.dart';
import '../studio/studio_pages.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) => DanceWelcomeScene(
    onJoin: () => openPage(context, const AuthPage(signUp: true)),
    onSignIn: () => openPage(context, const AuthPage(signUp: false)),
    onExplore: VimiScope.of(context).explore,
    onPrivacy: () =>
        openPage(context, const LegalPage('Privacy Policy', 'privacy')),
    onSafety: () => openPage(
      context,
      const LegalPage('Child safety standards', 'child-safety'),
    ),
    onPreview: (clip) => openPage(
      context,
      ClipLibraryDetail(
        clip: clip,
        practiceBuilder: (value) => PracticeEditor(initialClip: value),
      ),
    ),
  );
}

Future<bool> requireSignIn(BuildContext context) async {
  final app = VimiScope.of(context);
  if (app.signedIn) return true;
  if (app.resumingGuestAction) return false;
  app.resumingGuestAction = true;
  try {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'vimi-resume-auth'),
        builder: (_) => const AuthPage(signUp: false),
      ),
    );
    if (!context.mounted || !app.signedIn) return false;
    await app.refreshAccount();
    if (!context.mounted) return false;
    if (app.cloudError != null) {
      feedback(context, app.cloudError!);
      return false;
    }
    return app.accountStatus == 'active';
  } finally {
    app.resumingGuestAction = false;
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.signUp, this.initialEmail});
  final bool signUp;
  final String? initialEmail;
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
  void switchMode(bool signUp) {
    final route = MaterialPageRoute<void>(
      builder: (_) => AuthPage(signUp: signUp),
    );
    if (VimiScope.of(context).resumingGuestAction) {
      Navigator.of(context).push(route);
    } else {
      Navigator.of(context).pushReplacement(route);
    }
  }

  @override
  void initState() {
    super.initState();
    email.text = widget.initialEmail ?? '';
  }

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
        if (response.session == null && mounted) {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => EmailConfirmationPage(email: address),
            ),
          );
        }
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
              VField(
                'Display name',
                controller: name,
                maxLength: 40,
                enabled: !busy,
              ),
            VField(
              'Email',
              controller: email,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
            ),
            VField(
              'Password',
              controller: password,
              obscure: true,
              enabled: !busy,
            ),
            if (widget.signUp) ...[
              VField(
                'Date of birth · YYYY-MM-DD',
                controller: birth,
                enabled: !busy,
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
                  onPressed: busy
                      ? null
                      : () => setState(() => consent = !consent),
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
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          const LegalPage('Community guidelines', 'community'),
                        ),
                        child: const Text('Community guidelines'),
                      ),
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          const LegalPage(
                            'Child safety standards',
                            'child-safety',
                          ),
                        ),
                        child: const Text('Child safety standards'),
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
              SurfacePanel(child: Text(notice!)),
            ],
            const SizedBox(height: 24),
            VButton(
              widget.signUp ? 'Create account' : 'Sign in',
              busy: busy,
              onPressed: submit,
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
                onPressed: () => switchMode(false),
              ),
            VButton(
              widget.signUp
                  ? 'Already a member? Sign in'
                  : 'New here? Create an account',
              quiet: true,
              onPressed: busy ? null : () => switchMode(!widget.signUp),
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
  final password = TextEditingController(),
      confirmation = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    if (password.text.length < 8 || password.text != confirmation.text) {
      setState(
        () => error = 'Use matching passwords with at least 8 characters.',
      );
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
        VField(
          'New password',
          controller: password,
          obscure: true,
          enabled: !busy,
        ),
        VField(
          'Confirm new password',
          controller: confirmation,
          obscure: true,
          enabled: !busy,
        ),
        if (error != null) ErrorNote(error!),
        VButton('Save password', onPressed: save, busy: busy),
        VButton(
          'Return to sign in',
          quiet: true,
          onPressed: busy
              ? null
              : () async {
                  try {
                    await VimiScope.of(context).signOut();
                  } catch (e) {
                    if (context.mounted) feedback(context, readableError(e));
                  }
                },
        ),
      ],
    ),
  );
}

class LegalPage extends StatefulWidget {
  const LegalPage(this.title, this.file, {super.key});
  final String title, file;
  @override
  State<LegalPage> createState() => _LegalPageState();
}

class _LegalPageState extends State<LegalPage> {
  late Future<String> document;
  @override
  void initState() {
    super.initState();
    document = read();
  }

  Future<String> read() =>
      rootBundle.loadString('assets/legal/${widget.file}.txt');
  void retry() => setState(() => document = read());
  String get webUrl => switch (widget.file) {
    'privacy' => const String.fromEnvironment('PRIVACY_URL'),
    'terms' => const String.fromEnvironment('TERMS_URL'),
    'community' => const String.fromEnvironment('COMMUNITY_URL'),
    'child-safety' => const String.fromEnvironment('CHILD_SAFETY_URL'),
    'deletion' => const String.fromEnvironment('DELETE_ACCOUNT_URL'),
    _ => '',
  };
  @override
  Widget build(BuildContext context) => VPage(
    title: widget.title,
    child: FutureBuilder<String>(
      future: document,
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (snapshot.hasError)
            ErrorNote('This policy could not be opened.', onRetry: retry)
          else if (!snapshot.hasData)
            const Text('Opening policy…')
          else
            SelectableText(
              snapshot.data!,
              style: const TextStyle(fontSize: 16, height: 1.65),
            ),
          if (Uri.tryParse(webUrl)?.scheme == 'https') ...[
            const SizedBox(height: 24),
            VButton(
              'Open public webpage',
              quiet: true,
              onPressed: () async {
                try {
                  if (!await launchUrl(
                        Uri.parse(webUrl),
                        mode: LaunchMode.externalApplication,
                      ) &&
                      context.mounted) {
                    feedback(
                      context,
                      'The webpage could not be opened. You can read the policy here.',
                    );
                  }
                } catch (_) {
                  if (context.mounted)
                    feedback(
                      context,
                      'The webpage could not be opened. You can read the policy here.',
                    );
                }
              },
            ),
          ],
        ],
      ),
    ),
  );
}
