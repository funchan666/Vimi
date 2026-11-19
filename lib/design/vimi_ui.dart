import 'dart:math' as math;
import 'package:flutter/material.dart';

abstract final class VimiColors {
  static const background = Color(0xFF0C0716),
      surface = Color(0xFF1B122B),
      ink = Color(0xFFF7F2FF),
      muted = Color(0xFFBBB0CD),
      tonal = Color(0xFF322143),
      line = Color(0xFF806899),
      accent = Color(0xFFF58BDD),
      violet = Color(0xFFBBA4FF),
      cyan = Color(0xFF86E7F4),
      onAccent = Color(0xFF170C24),
      danger = Color(0xFFFFA3B5);
}

ThemeData vimiTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'DMSans',
  scaffoldBackgroundColor: VimiColors.background,
  colorScheme: const ColorScheme.dark(
    primary: VimiColors.accent,
    onPrimary: VimiColors.onAccent,
    secondary: VimiColors.cyan,
    onSecondary: VimiColors.onAccent,
    secondaryContainer: VimiColors.tonal,
    onSecondaryContainer: VimiColors.ink,
    surface: VimiColors.surface,
    onSurface: VimiColors.ink,
    onSurfaceVariant: VimiColors.muted,
    outline: VimiColors.line,
    outlineVariant: VimiColors.line,
    error: VimiColors.danger,
    onError: VimiColors.onAccent,
  ),
  textTheme: const TextTheme(
    displaySmall: TextStyle(
      fontFamily: 'DMSans',
      fontSize: 40,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.9,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'DMSans',
      fontSize: 32,
      height: 1.16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.7,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'DMSans',
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
  ).apply(bodyColor: VimiColors.ink, displayColor: VimiColors.ink),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: VimiColors.accent),
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: VimiColors.accent,
    selectionColor: VimiColors.tonal,
    selectionHandleColor: VimiColors.accent,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: VimiColors.surface,
    labelStyle: TextStyle(color: VimiColors.muted),
    floatingLabelStyle: TextStyle(color: VimiColors.accent),
    contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: VimiColors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: VimiColors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: VimiColors.accent, width: 2),
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
  static const _regions = <Rect>[
    Rect.fromLTRB(87.0, 91.0, 213.0, 237.0),
    Rect.fromLTRB(294.0, 113.0, 439.0, 212.0),
    Rect.fromLTRB(508.0, 106.0, 641.0, 225.0),
    Rect.fromLTRB(720.0, 94.0, 843.0, 226.0),
    Rect.fromLTRB(939.0, 103.0, 1051.0, 215.0),
    Rect.fromLTRB(1150.0, 117.0, 1264.0, 202.0),
    Rect.fromLTRB(1370.0, 114.0, 1461.0, 205.0),
    Rect.fromLTRB(1570.0, 147.0, 1679.0, 171.0),
    Rect.fromLTRB(86.0, 314.0, 218.0, 432.0),
    Rect.fromLTRB(297.0, 315.0, 428.0, 429.0),
    Rect.fromLTRB(508.0, 305.0, 639.0, 438.0),
    Rect.fromLTRB(734.0, 307.0, 832.0, 431.0),
    Rect.fromLTRB(926.0, 307.0, 1056.0, 434.0),
    Rect.fromLTRB(1132.0, 300.0, 1277.0, 445.0),
    Rect.fromLTRB(1349.0, 304.0, 1479.0, 436.0),
    Rect.fromLTRB(1567.0, 327.0, 1683.0, 411.0),
    Rect.fromLTRB(107.0, 512.0, 200.0, 622.0),
    Rect.fromLTRB(325.0, 516.0, 396.0, 619.0),
    Rect.fromLTRB(498.0, 510.0, 636.0, 622.0),
    Rect.fromLTRB(710.0, 510.0, 855.0, 624.0),
    Rect.fromLTRB(925.0, 509.0, 1064.0, 623.0),
    Rect.fromLTRB(1134.0, 521.0, 1281.0, 614.0),
    Rect.fromLTRB(1347.0, 511.0, 1490.0, 619.0),
    Rect.fromLTRB(1568.0, 510.0, 1691.0, 620.0),
    Rect.fromLTRB(107.0, 703.0, 210.0, 833.0),
    Rect.fromLTRB(296.0, 703.0, 426.0, 834.0),
    Rect.fromLTRB(513.0, 698.0, 630.0, 836.0),
    Rect.fromLTRB(719.0, 705.0, 853.0, 828.0),
    Rect.fromLTRB(931.0, 703.0, 1056.0, 830.0),
    Rect.fromLTRB(1143.0, 699.0, 1261.0, 832.0),
    Rect.fromLTRB(1339.0, 706.0, 1480.0, 825.0),
    Rect.fromLTRB(1556.0, 700.0, 1691.0, 837.0),
  ];
  final Glyph glyph;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final region = _regions[glyph.index];
    final scale = size * .92 / math.max(region.width, region.height);
    final atlasWidth = 1774.0 * scale;
    final atlasHeight = 887.0 * scale;
    // Display an original raster atlas; no paths or replacement artwork are drawn.
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: atlasWidth,
            maxWidth: atlasWidth,
            minHeight: atlasHeight,
            maxHeight: atlasHeight,
            child: Transform.translate(
              offset: Offset(
                size / 2 - region.center.dx * scale,
                size / 2 - region.center.dy * scale,
              ),
              child: Image.asset(
                'assets/ui/glyphs-clean.webp',
                width: atlasWidth,
                height: atlasHeight,
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
    this.tonal = false,
    this.busy = false,
    this.quiet = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final Glyph? glyph;
  final bool tonal, busy, quiet;
  @override
  Widget build(BuildContext context) {
    final ink = quiet
        ? VimiColors.accent
        : tonal
        ? VimiColors.ink
        : VimiColors.onAccent;
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      tonal
                          ? 'assets/ui/control-fill.webp'
                          : 'assets/ui/neon-spectrum.webp',
                      fit: BoxFit.fill,
                      color: tonal ? VimiColors.tonal : null,
                      colorBlendMode: tonal ? BlendMode.srcIn : null,
                    ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
          image: AssetImage('assets/ui/surface-clean.webp'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(VimiColors.surface, BlendMode.srcIn),
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

class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.illuminated = false,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool illuminated;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: DecoratedBox(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            illuminated
                ? 'assets/ui/neon-spectrum.webp'
                : 'assets/ui/surface-clean.webp',
          ),
          fit: BoxFit.cover,
          colorFilter: illuminated
              ? const ColorFilter.mode(Color(0xDE1B122B), BlendMode.srcATop)
              : const ColorFilter.mode(VimiColors.surface, BlendMode.srcIn),
        ),
      ),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class NeonBackdrop extends StatelessWidget {
  const NeonBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: VimiColors.background,
    child: Stack(
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: Opacity(
              opacity: .07,
              child: Image.asset(
                'assets/ui/neon-spectrum.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

class VimiWordmark extends StatelessWidget {
  const VimiWordmark({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.asset('assets/ui/neon-mark.webp', width: 38, height: 38),
      ),
      const SizedBox(width: 10),
      const Flexible(
        child: Text(
          'vimi',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
          ),
        ),
      ),
    ],
  );
}

class VPage extends StatelessWidget {
  const VPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.back = true,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final bool back;
  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: NeonBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    this.enabled = true,
  });
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
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

                tonal: value != v,
                onPressed: enabled ? () => onChanged(v) : null,
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
    child: SurfacePanel(
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
      content: SurfacePanel(
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
          child: SurfacePanel(
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
          ? Image.asset('assets/ui/neon-mark.webp', fit: BoxFit.cover)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/ui/neon-mark.webp', fit: BoxFit.cover),
            ),
    ),
  );
}
