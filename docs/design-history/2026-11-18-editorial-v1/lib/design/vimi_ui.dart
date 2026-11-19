import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class VimiColors {
  static const paper = Color(0xFFF4F2EA),
      ink = Color(0xFF22251F),
      muted = Color(0xFF606455),
      lime = Color(0xFFCBE85B),
      line = Color(0xFFD9DCCF),
      danger = Color(0xFF923B32);
}

ThemeData vimiTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'DMSans',
  scaffoldBackgroundColor: VimiColors.paper,
  colorScheme: const ColorScheme.light(
    primary: VimiColors.ink,
    onPrimary: VimiColors.paper,
    secondary: VimiColors.lime,
    onSecondary: VimiColors.ink,
    surface: VimiColors.paper,
    onSurface: VimiColors.ink,
    error: VimiColors.danger,
  ),
  textTheme: const TextTheme(
    displaySmall: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: 44,
      height: 1.08,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.1,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: 32,
      height: 1.16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.7,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'SpaceGrotesk',
      fontSize: 24,
      height: 1.2,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.5),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    labelLarge: TextStyle(
      fontSize: 14,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: VimiColors.ink,
    selectionColor: VimiColors.lime,
    selectionHandleColor: VimiColors.ink,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: false,
    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
    border: UnderlineInputBorder(
      borderSide: BorderSide(color: VimiColors.line),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: VimiColors.line),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: VimiColors.ink, width: 2),
    ),
    errorStyle: TextStyle(color: VimiColors.danger, fontSize: 14),
  ),
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {TargetPlatform.android: PredictiveBackPageTransitionsBuilder()},
  ),
);

enum Glyph {
  floor,
  studio,
  inbox,
  person,
  add,
  back,
  close,
  more,
  heart,
  heartFull,
  comment,
  save,
  search,
  settings,
  coin,
  check,
  play,
  pause,
  mute,
  sound,
  camera,
  video,
  photo,
  upload,
  report,
  block,
  delete,
  logout,
  refresh,
  share,
  send,
  clock,
}

class VIcon extends StatelessWidget {
  const VIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color = VimiColors.ink,
  });
  final Glyph glyph;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final cell = size * 1.4;
    final index = glyph.index;
    // Display an original raster atlas; no paths or replacement artwork are drawn.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: cell * 8,
            maxWidth: cell * 8,
            minHeight: cell * 4,
            maxHeight: cell * 4,
            child: Transform.translate(
              offset: Offset(
                -(index % 8) * cell - (cell - size) / 2,
                -(index ~/ 8) * cell - (cell - size) / 2,
              ),
              child: Image.asset(
                'assets/ui/icons.webp',
                width: cell * 8,
                height: cell * 4,
                fit: BoxFit.fill,
                color: color,
                colorBlendMode: BlendMode.srcIn,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VButton extends StatelessWidget {
  const VButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.glyph,
    this.lime = false,
    this.busy = false,
    this.quiet = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final Glyph? glyph;
  final bool lime, busy, quiet;
  @override
  Widget build(BuildContext context) {
    final ink = quiet || lime ? VimiColors.ink : VimiColors.paper;
    return Semantics(
      liveRegion: busy,
      child: Opacity(
        opacity: onPressed == null && !busy ? 0.5 : 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!quiet)
                Positioned.fill(
                  child: Image.asset(
                    'assets/ui/button.webp',
                    fit: BoxFit.fill,
                    color: lime ? VimiColors.lime : null,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ink,
                  disabledForegroundColor: ink,
                  minimumSize: const Size(48, 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: const RoundedRectangleBorder(),
                  textStyle: Theme.of(context).textTheme.labelLarge,
                ),
                onPressed: busy ? null : onPressed,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (glyph != null) ...[
                      VIcon(glyph!, size: 20, color: ink),
                      const SizedBox(width: 10),
                    ],
                    Flexible(
                      child: Text(
                        busy ? 'Please wait…' : label,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VIconButton extends StatelessWidget {
  const VIconButton(
    this.glyph, {
    super.key,
    required this.label,
    required this.onPressed,
    this.color = VimiColors.ink,
  });
  final Glyph glyph;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Tooltip(
      message: label,
      textStyle: const TextStyle(
        color: VimiColors.ink,
        fontFamily: 'DMSans',
        fontSize: 14,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/ui/paper.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.all(12),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: onPressed,
        child: VIcon(glyph, color: color),
      ),
    ),
  );
}

class Paper extends StatelessWidget {
  const Paper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/ui/paper.webp'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class VPage extends StatelessWidget {
  const VPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.art = 'studio',
    this.back = true,
  });
  final String title, art;
  final Widget child;
  final List<Widget> actions;
  final bool back;
  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/ui/$art.webp',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(.10),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    if (back)
                      VIconButton(
                        Glyph.back,
                        label: 'Go back',
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    ),
  );
}

class VField extends StatelessWidget {
  const VField(
    this.label, {
    super.key,
    required this.controller,
    this.obscure = false,
    this.lines = 1,
    this.keyboardType,
    this.onChanged,
    this.maxLength,
    this.enabled = true,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final bool enabled;
  final int lines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      maxLines: lines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      autocorrect: !obscure,
      enableSuggestions: !obscure,
      textInputAction: lines > 1
          ? TextInputAction.newline
          : TextInputAction.done,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(labelText: label),
    ),
  );
}

class ChoiceStrip extends StatelessWidget {
  const ChoiceStrip({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: options
          .map(
            (v) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: VButton(
                v,
                lime: true,
                quiet: value != v,
                onPressed: () => onChanged(v),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class EmptyNote extends StatelessWidget {
  const EmptyNote(this.title, this.body, {super.key, this.action});
  final String title, body;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          body,
          style: const TextStyle(
            color: VimiColors.muted,
            fontSize: 16,
            height: 1.5,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class ErrorNote extends StatelessWidget {
  const ErrorNote(this.message, {super.key, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Paper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(color: VimiColors.danger)),
          if (onRetry != null)
            VButton(
              'Try again',
              quiet: true,
              glyph: Glyph.refresh,
              onPressed: onRetry,
            ),
        ],
      ),
    ),
  );
}

void feedback(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      content: Paper(
        child: Text(message, style: const TextStyle(color: VimiColors.ink)),
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Paper(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(body),
                const SizedBox(height: 24),
                VButton(action, onPressed: () => Navigator.pop(context, true)),
                VButton(
                  'Cancel',
                  quiet: true,
                  onPressed: () => Navigator.pop(context, false),
                ),
              ],
            ),
          ),
        ),
      ),
    ) ??
    false;

String displayDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  return '${months[local.month - 1]} ${local.day}';
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, this.size = 48});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: size,
      child: url == null
          ? Image.asset('assets/ui/app_icon.webp', fit: BoxFit.cover)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/ui/app_icon.webp', fit: BoxFit.cover),
            ),
    ),
  );
}
