import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/media_library.dart';
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
  final agreementKey = GlobalKey();
  bool agreementDialogOpen = false;
  String? error;
  late final Future<String?> cover = MediaLibrary.load().then((library) {
    final id = widget.signUp ? 'room-formation' : 'evening-plaza-duet';
    return library.clips.where((clip) => clip.id == id).firstOrNull?.thumbnail;
  });

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

  Future<void> showAgreementReminder() async {
    agreementDialogOpen = true;
    try {
      final review = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: SingleChildScrollView(
              child: SurfacePanel(
                illuminated: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Agreement required',
                        style: Theme.of(dialogContext).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Read and agree to the Terms of Use and Community Guidelines before creating an account.',
                    ),
                    const SizedBox(height: 20),
                    AccountEntryButton(
                      'Review agreement',
                      onPressed: () => Navigator.pop(dialogContext, true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final agreement = agreementKey.currentContext;
      if (review == true && agreement != null && agreement.mounted) {
        await Scrollable.ensureVisible(
          agreement,
          alignment: .2,
          duration: MediaQuery.disableAnimationsOf(agreement)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } finally {
      agreementDialogOpen = false;
    }
  }

  Future<void> submit() async {
    if (busy || agreementDialogOpen) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.signUp && !consent) {
      await showAgreementReminder();
      return;
    }
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
    if (widget.signUp) {
      final birthday = DateTime.tryParse(birth.text.trim());
      final now = DateTime.now();
      final adult = DateTime(now.year - 18, now.month, now.day);
      if (name.text.trim().length < 2 || name.text.trim().length > 40) {
        setState(() => error = 'Use 2 to 40 characters for your display name.');
        return;
      }
      if (birthday == null ||
          birthday.year < 1900 ||
          birthday.isAfter(now) ||
          birthday.toIso8601String().substring(0, 10) != birth.text.trim()) {
        setState(() => error = 'Enter a valid date of birth as YYYY-MM-DD.');
        return;
      }
      if (birthday.isAfter(adult)) {
        setState(() => error = 'You’re not eligible to create an account.');
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
        } else if (response.session != null) {
          TextInput.finishAutofillContext();
        }
      } else {
        await auth.signInWithPassword(email: address, password: password.text);
        TextInput.finishAutofillContext();
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: NeonBackdrop(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            final hero = _AuthCover(
              signUp: widget.signUp,
              cover: cover,
              wide: wide,
            );
            final heroHeight = wide
                ? 52.0
                : hero.compactHeight(context, constraints.maxWidth);
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverAppBar(
                  primary: false,
                  pinned: true,
                  toolbarHeight: 52,
                  expandedHeight: wide ? null : heroHeight,
                  backgroundColor: VimiColors.background,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  leadingWidth: 66,
                  leading: Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 6,
                      top: 2,
                      bottom: 2,
                    ),
                    child: VIconButton(
                      Glyph.back,
                      label: 'Go back',
                      filled: !wide,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  flexibleSpace: wide
                      ? null
                      : LayoutBuilder(
                          builder: (context, box) => ClipRect(
                            child: Opacity(
                              opacity:
                                  ((box.maxHeight - 58) / (heroHeight - 58))
                                      .clamp(0.0, 1.0),
                              child: OverflowBox(
                                alignment: Alignment.bottomCenter,
                                minHeight: heroHeight,
                                maxHeight: heroHeight,
                                child: hero,
                              ),
                            ),
                          ),
                        ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 1060 : 540),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          wide ? 32 : 20,
                          wide ? 16 : 20,
                          wide ? 32 : 20,
                          28,
                        ),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 510,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: hero,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(child: _form()),
                                ],
                              )
                            : _form(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _form() {
    final signUp = widget.signUp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AutofillGroup(
          onDisposeAction: AutofillContextAction.cancel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (signUp) ...[
                _fieldGroup([
                  _field('Display name', name, maxLength: 40),
                  _field(
                    'Date of birth',
                    birth,
                    keyboard: TextInputType.datetime,
                    hint: 'YYYY-MM-DD',
                  ),
                ]),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 6, 4, 14),
                  child: Text(
                    'Birth date is used to check account eligibility.',
                    style: TextStyle(color: VimiColors.muted, fontSize: 13),
                  ),
                ),
              ],
              _fieldGroup([
                _field(
                  'Email',
                  email,
                  keyboard: TextInputType.emailAddress,
                  autofill: const [AutofillHints.email],
                ),
                _field('Password', password, isPassword: true),
              ]),
            ],
          ),
        ),
        if (signUp) ...[
          const SizedBox(height: 14),
          _SignupAgreement(
            key: agreementKey,
            accepted: consent,
            onChanged: busy
                ? null
                : () => setState(() {
                    consent = !consent;
                    error = null;
                  }),
          ),
        ] else
          Align(
            alignment: Alignment.centerRight,
            child: _AuthLink(
              'Forgot password?',
              onPressed: busy
                  ? null
                  : () => openPage(context, const RecoverAccountPage()),
            ),
          ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Semantics(liveRegion: true, child: ErrorNote(error!)),
        ],
        SizedBox(height: signUp ? 14 : 6),
        AccountEntryButton(
          signUp ? 'Create account' : 'Sign in',
          busy: busy,
          onPressed: submit,
        ),
        const SizedBox(height: 6),
        Center(
          child: _AuthLink(
            signUp
                ? 'Already a member? Sign in'
                : 'New here? Create an account',
            onPressed: busy ? null : () => switchMode(!signUp),
          ),
        ),
        if (!signUp) const _AuthPolicyLinks(includeAgreement: false),
      ],
    );
  }

  Widget _fieldGroup(List<Widget> fields) => SurfacePanel(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (var i = 0; i < fields.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: VimiColors.tonal,
            ),
          fields[i],
        ],
      ],
    ),
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType? keyboard,
    List<String>? autofill,
    int? maxLength,
    String? hint,
  }) => TextField(
    controller: controller,
    enabled: !busy,
    obscureText: isPassword && !showPassword,
    autocorrect: false,
    enableSuggestions: false,
    inputFormatters: maxLength == null
        ? null
        : [LengthLimitingTextInputFormatter(maxLength)],
    keyboardType: isPassword ? TextInputType.visiblePassword : keyboard,
    autofillHints: isPassword
        ? [widget.signUp ? AutofillHints.newPassword : AutofillHints.password]
        : autofill,
    textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
    onSubmitted: isPassword && !widget.signUp ? (_) => submit() : null,
    onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.focused)
              ? VimiColors.accent
              : VimiColors.muted,
        ),
      ),
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: VimiColors.accent, width: 2),
      ),
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

class _AuthCover extends StatelessWidget {
  const _AuthCover({
    required this.signUp,
    required this.cover,
    required this.wide,
  });
  final bool signUp, wide;
  final Future<String?> cover;

  String get firstLine => signUp ? 'Find your\n' : 'Back on\n';
  String get secondLine => signUp ? 'crew.' : 'the floor.';
  TextStyle get titleStyle => TextStyle(
    fontSize: wide ? 58 : (signUp ? 34 : 44),
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.3,
  );

  double compactHeight(BuildContext context, double width) {
    final title = TextPainter(
      text: TextSpan(
        text: '$firstLine$secondLine',
        style: DefaultTextStyle.of(context).style.merge(titleStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: width > 40 ? width - 40 : 0);
    final height = title.height + 76;
    title.dispose();
    final minimum = signUp ? 170.0 : 228.0;
    return height > minimum ? height : minimum;
  }

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: VimiColors.background.withValues(alpha: .8)),
      Opacity(
        opacity: .16,
        child: Image.asset(
          'assets/ui/neon-spectrum.webp',
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: wide ? 1 : .71,
          heightFactor: 1,
          child: FutureBuilder<String?>(
            future: cover,
            builder: (context, snapshot) {
              final url = snapshot.data;
              if (url == null) return const SizedBox.expand();
              return ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (area) =>
                    (wide
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black,
                                  Colors.black,
                                  Colors.transparent,
                                ],
                                stops: [0, .43, 1],
                              )
                            : const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black,
                                  Colors.black,
                                ],
                                stops: [0, .49, 1],
                              ))
                        .createShader(area),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  alignment: Alignment(0, signUp ? -.22 : .56),
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stack) =>
                      const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xE00C0716)],
            stops: [.45, 1],
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 20, 12, 20, wide ? 32 : 19),
          child: Semantics(
            header: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: firstLine),
                  TextSpan(
                    text: secondLine,
                    style: TextStyle(
                      color: signUp ? VimiColors.accent : VimiColors.cyan,
                    ),
                  ),
                ],
              ),
              style: titleStyle,
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 2,
        child: Image.asset(
          'assets/ui/neon-spectrum.webp',
          fit: BoxFit.fill,
          excludeFromSemantics: true,
        ),
      ),
    ],
  );
}

class _SignupAgreement extends StatelessWidget {
  const _SignupAgreement({
    super.key,
    required this.accepted,
    required this.onChanged,
  });
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
                    alignment: Alignment.center,
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
  final _headings = <int, GlobalKey>{};

  Future<void> _openWeb(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // The bundled text remains readable if the browser cannot open.
    }
    if (mounted) {
      feedback(
        context,
        'The webpage could not be opened. You can read the policy here.',
      );
    }
  }

  Widget _reader(String text) {
    final blocks = text.trim().split(RegExp(r'\r?\n[ \t]*\r?\n'));
    final heading = blocks.first.split(RegExp(r'\r?\n'));
    final body = blocks.skip(1).toList();
    final sections = <int, String>{
      for (final (index, value) in body.indexed)
        if (value.length < 72 &&
            !value.contains('\n') &&
            !RegExp(r'[.?!]$').hasMatch(value))
          index: value,
    };
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SurfacePanel(
          illuminated: true,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(widget.title, style: theme.headlineSmall),
              ),
              if (heading.length > 1) ...[
                const SizedBox(height: 8),
                Text(
                  heading.skip(1).join(' '),
                  style: theme.bodySmall?.copyWith(color: VimiColors.cyan),
                ),
              ],
            ],
          ),
        ),
        if (sections.length > 1) ...[
          const SizedBox(height: 18),
          Text('On this page', style: theme.titleSmall),
          Wrap(
            spacing: 6,
            children: [
              for (final section in sections.entries)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: VimiColors.cyan,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () {
                    final anchor = _headings[section.key]?.currentContext;
                    if (anchor == null) return;
                    Scrollable.ensureVisible(
                      anchor,
                      alignment: .06,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                    );
                  },
                  child: Text(section.value),
                ),
            ],
          ),
          const Divider(height: 20, color: VimiColors.tonal),
        ],
        const SizedBox(height: 14),
        SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, value) in body.indexed)
                if (sections.containsKey(index))
                  Padding(
                    key: _headings.putIfAbsent(index, GlobalKey.new),
                    padding: const EdgeInsets.only(top: 12, bottom: 9),
                    child: Semantics(
                      header: true,
                      child: Text(value, style: theme.titleMedium),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(value, style: const TextStyle(height: 1.6)),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(webUrl);
    return VPage(
      title: '',
      actions: [
        if (uri != null && uri.scheme == 'https' && uri.hasAuthority)
          VIconButton(
            Glyph.share,
            label: 'Open public webpage',
            onPressed: () => _openWeb(uri),
          ),
      ],
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: FutureBuilder<String>(
            future: document,
            builder: (context, snapshot) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
              child: snapshot.hasError
                  ? ErrorNote(
                      'This policy could not be opened.',
                      onRetry: retry,
                    )
                  : snapshot.hasData
                  ? _reader(snapshot.data!)
                  : const Text('Opening policy…'),
            ),
          ),
        ),
      ),
    );
  }
}
