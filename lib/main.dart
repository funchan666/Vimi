import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_controller.dart';
import 'core/dance_repository.dart';
import 'core/local_studio.dart';
import 'core/secure_session.dart';
import 'design/vimi_ui.dart';
import 'features/auth/auth_pages.dart';
import 'features/shell.dart';
import 'features/profile/profile_pages.dart';
import 'features/studio/rehearsal_player.dart';
import 'features/wallet/play_coins.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'DM Sans',
    ], await rootBundle.loadString('assets/fonts/dmsans-OFL.txt'));
  });
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const VimiBootstrap());
}

class VimiBootstrap extends StatefulWidget {
  const VimiBootstrap({super.key});
  @override
  State<VimiBootstrap> createState() => _VimiBootstrapState();
}

class _VimiBootstrapState extends State<VimiBootstrap> {
  AppController? app;
  Object? failure;
  bool starting = false;
  @override
  void initState() {
    super.initState();
    unawaited(start());
  }

  Future<void> start() async {
    if (starting) return;
    setState(() {
      starting = true;
      failure = null;
    });
    try {
      const url = String.fromEnvironment('SUPABASE_URL');
      const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
      DanceRepository? repo;
      if (url.isNotEmpty && key.isNotEmpty) {
        await Supabase.initialize(
          url: url,
          publishableKey: key,
          debug: false,
          authOptions: const FlutterAuthClientOptions(
            localStorage: SecureSession(),
          ),
        );
        repo = DanceRepository(Supabase.instance.client);
      }
      final controller = AppController(
        studio: LocalStudio(await SharedPreferences.getInstance()),
        repo: repo,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => app = controller);
    } catch (e) {
      if (mounted) setState(() => failure = e);
    } finally {
      starting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (app != null)
      return VimiScope(
        controller: app!,
        child: VimiApp(controller: app!),
      );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: vimiTheme(),
      home: Scaffold(
        body: NeonBackdrop(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        failure == null
                            ? 'Getting the floor ready…'
                            : 'Couldn’t open the app.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (failure != null) ...[
                      const SizedBox(height: 24),
                      VButton('Try again', onPressed: start),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VimiApp extends StatefulWidget {
  const VimiApp({super.key, required this.controller});
  final AppController controller;
  @override
  State<VimiApp> createState() => _VimiAppState();
}

class _VimiAppState extends State<VimiApp> with WidgetsBindingObserver {
  final navigator = GlobalKey<NavigatorState>();
  String account = 'guest';
  late final PlayCoins billing;
  late final PlaybackRouteObserver routes;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    account = widget.controller.account;
    billing = PlayCoins(widget.controller);
    routes = PlaybackRouteObserver(
      onReturned: () {
        if (mounted) widget.controller.changed();
      },
    );
    widget.controller.addListener(changed);
  }

  void changed() {
    final next = widget.controller.account;
    if (account != next || widget.controller.recoveringPassword) {
      final resume =
          account == 'guest' &&
          next != 'guest' &&
          widget.controller.resumingGuestAction &&
          !widget.controller.recoveringPassword;
      account = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = navigator.currentState;
        if (resume) {
          nav?.popUntil(
            (r) => r.settings.name == 'vimi-resume-auth' || r.isFirst,
          );
          if (nav?.canPop() == true) nav!.pop();
        } else {
          nav?.popUntil((r) => r.isFirst);
        }
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      PlaybackCoordinator.pauseAll();
    } else {
      unawaited(billing.retryPending());
      unawaited(widget.controller.refreshAccount());
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(changed);
    billing.dispose();
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: navigator,
    debugShowCheckedModeBanner: false,
    title: 'Vimi',
    theme: vimiTheme(),
    navigatorObservers: [routes],
    home: widget.controller.recoveringPassword
        ? UpdatePasswordPage(
            onSaved: () {
              widget.controller.recoveringPassword = false;
              widget.controller.changed();
            },
          )
        : widget.controller.signedIn &&
              widget.controller.accountStatus == 'deleting'
        ? const DeleteAccountPage()
        : widget.controller.signedIn &&
              widget.controller.accountStatus != 'active'
        ? Builder(
            builder: (pageContext) => VPage(
              title: 'Your account',
              back: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ListView(
                  children: [
                    const Text(
                      'This account is currently unavailable. You can sign out and return later.',
                    ),
                    VButton(
                      'Sign out',
                      onPressed: () => widget.controller.signOut(),
                    ),
                    VButton(
                      'Help & safety',
                      quiet: true,
                      onPressed: () => openPage(
                        pageContext,
                        const LegalPage('Help & account deletion', 'deletion'),
                      ),
                    ),
                    VButton(
                      'Delete account',
                      glyph: Glyph.delete,
                      quiet: true,
                      onPressed: () =>
                          openPage(pageContext, const DeleteAccountPage()),
                    ),
                  ],
                ),
              ),
            ),
          )
        : widget.controller.signedIn
        ? const DanceShell()
        : const WelcomePage(),
  );
}
