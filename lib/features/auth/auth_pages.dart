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
    onTerms: () => openPage(context, const LegalPage('Terms of Use', 'terms')),
    onPrivacy: () =>
        openPage(context, const LegalPage('Privacy Policy', 'privacy')),
    onSafety: () => openPage(
      context,
      const LegalPage('Child safety standards', 'child-safety'),
    ),
    onPreview: (clip) async {
      // The navigator survives the switch from welcome to the signed-in shell.
      final nav = Navigator.of(context);
      if (!await requireSignIn(nav.context) || !nav.mounted) return;
      await openPage(
        nav.context,
        ClipLibraryDetail(
          clip: clip,
          practiceBuilder: (value) => PracticeEditor(initialClip: value),
        ),
      );
    },
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
  bool consent = false, busy = false, showPassword = false;
  String? error;
  void switchMode(bool signUp) {
    final route = MaterialPageRoute<void>(
      builder: (_) => AuthPage(signUp: signUp, initialEmail: email.text.trim()),
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
        () => error = 'Account access is unavailable. Please try again.',
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
    if (widget.signUp && !consent) {
      setState(
        () => error =
            'Agree to the Terms of Use and Community Guidelines to create an account.',
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
              'Enter a display name and your date of birth as YYYY-MM-DD. You must be at least 18.',
        );
        return;
      }
    }
    setState(() {
      busy = true;
      error = null;
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
  Widget build(BuildContext context) {
    final signUp = widget.signUp;
    return Scaffold(
      body: NeonBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                      child: VIconButton(
                        Glyph.back,
                        label: 'Go back',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                        _AuthHeading(signUp: signUp),
                        const SizedBox(height: 24),
                        AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (signUp)
                                VField(
                                  'Display name',
                                  controller: name,
                                  maxLength: 40,
                                  enabled: !busy,
                                ),
                              _field('Email', email, isPassword: false),
                              const SizedBox(height: 12),
                              _field('Password', password, isPassword: true),
                              if (signUp) ...[
                                const SizedBox(height: 16),
                                VField(
                                  'Date of birth · YYYY-MM-DD',
                                  controller: birth,
                                  enabled: !busy,
                                  keyboardType: TextInputType.datetime,
                                ),
                                const Text(
                                  'We use your birth date to check that you’re 18 or older.',
                                  style: TextStyle(color: VimiColors.muted),
                                ),
                              ] else
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _AuthLink(
                                    'Forgot password?',
                                    onPressed: busy
                                        ? null
                                        : () => openPage(
                                            context,
                                            const RecoverAccountPage(),
                                          ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (signUp) ...[
                          const SizedBox(height: 20),
                          _SignupAgreement(
                            accepted: consent,
                            onChanged: busy
                                ? null
                                : () => setState(() {
                                    consent = !consent;
                                    error = null;
                                  }),
                          ),
                        ],
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Semantics(liveRegion: true, child: ErrorNote(error!)),
                        ],
                        SizedBox(height: signUp ? 20 : 12),
                        VButton(
                          signUp ? 'Create account' : 'Sign in',
                          glyph: Glyph.next,
                          busy: busy,
                          onPressed: submit,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: _AuthLink(
                            signUp
                                ? 'Already a member? Sign in'
                                : 'New here? Create an account',
                            onPressed: busy ? null : () => switchMode(!signUp),
                          ),
                        ),
                        if (!signUp)
                          const _AuthPolicyLinks(includeAgreement: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required bool isPassword,
  }) => TextField(
    controller: controller,
    enabled: !busy,
    obscureText: isPassword && !showPassword,
    autocorrect: false,
    enableSuggestions: false,
    keyboardType: isPassword
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
    autofillHints: isPassword
        ? [widget.signUp ? AutofillHints.newPassword : AutofillHints.password]
        : const [AutofillHints.email],
    textInputAction: isPassword && !widget.signUp
        ? TextInputAction.done
        : TextInputAction.next,
    onSubmitted: isPassword && !widget.signUp ? (_) => submit() : null,
    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: isPassword
          ? _AuthLink(
              showPassword ? 'Hide' : 'Show',
              onPressed: busy
                  ? null
                  : () => setState(() => showPassword = !showPassword),
            )
          : null,
    ),
  );
}

class _AuthHeading extends StatelessWidget {
  const _AuthHeading({required this.signUp});
  final bool signUp;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/ui/neon-spectrum.webp',
            fit: BoxFit.cover,
            alignment: signUp ? Alignment.centerLeft : Alignment.centerRight,
            excludeFromSemantics: true,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 2),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          color: VimiColors.background.withValues(alpha: .85),
          child: Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: signUp ? 'Join the\n' : 'Back on\n'),
                  TextSpan(
                    text: signUp ? 'crew.' : 'the floor.',
                    style: TextStyle(
                      color: signUp ? VimiColors.accent : VimiColors.cyan,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 40,
                height: 1.04,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.05,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SignupAgreement extends StatelessWidget {
  const _SignupAgreement({required this.accepted, required this.onChanged});
  final bool accepted;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) => SurfacePanel(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tooltip(
          message: 'Agree to Terms of Use and Community Guidelines',
          excludeFromSemantics: true,
          child: Semantics(
            checked: accepted,
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: VimiColors.ink,
                minimumSize: const Size(48, 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onChanged,
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accepted ? VimiColors.accent : VimiColors.line,
                      ),
                      color: accepted
                          ? VimiColors.accent
                          : VimiColors.background,
                    ),
                    child: accepted
                        ? const VIcon(
                            Glyph.check,
                            color: VimiColors.onAccent,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I agree to the Terms of Use and Community Guidelines.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const _AuthPolicyLinks(includeAgreement: true),
      ],
    ),
  );
}

class _AuthPolicyLinks extends StatelessWidget {
  const _AuthPolicyLinks({required this.includeAgreement});
  final bool includeAgreement;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      if (includeAgreement) ...[
        _policy(context, 'Terms of Use', 'terms'),
        _policy(context, 'Community Guidelines', 'community'),
      ],
      _policy(context, 'Privacy Policy', 'privacy'),
      _policy(
        context,
        'Child safety',
        'child-safety',
        title: 'Child safety standards',
      ),
    ],
  );

  Widget _policy(
    BuildContext context,
    String label,
    String file, {
    String? title,
  }) => _AuthLink(
    label,
    onPressed: () => openPage(context, LegalPage(title ?? label, file)),
  );
}

class _AuthLink extends StatelessWidget {
  const _AuthLink(this.label, {required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      foregroundColor: VimiColors.violet,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onPressed,
    child: Text(label, textAlign: TextAlign.center),
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
