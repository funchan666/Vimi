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
      fontSize: 30,
      height: 1.12,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.9,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'DMSans',
      fontSize: 25,
      height: 1.16,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.7,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'DMSans',
      fontSize: 20,
      height: 1.2,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      height: 1.4,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(fontSize: 15, height: 1.45),
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
  edit,
  mirror,
  loop,
  expand,
  rewind,
  forward,
  next,
  library,
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
  static const _utilityRegions = <Rect>[
    Rect.fromLTRB(96, 82, 380, 383),
    Rect.fromLTRB(520, 75, 813, 400),
    Rect.fromLTRB(948, 89, 1270, 358),
    Rect.fromLTRB(1410, 87, 1697, 357),
    Rect.fromLTRB(84, 506, 369, 825),
    Rect.fromLTRB(513, 531, 806, 826),
    Rect.fromLTRB(1029, 542, 1184, 800),
    Rect.fromLTRB(1381, 542, 1721, 809),
  ];
  final Glyph glyph;
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final utility = glyph.index >= _regions.length;
    final region = utility
        ? _utilityRegions[glyph.index - _regions.length]
        : _regions[glyph.index];
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
                utility
                    ? 'assets/ui/utility-controls-v4.webp'
                    : 'assets/ui/glyphs-clean.webp',
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
    final ink = quiet || tonal ? VimiColors.ink : VimiColors.onAccent;
    return Semantics(
      liveRegion: busy,
      child: Opacity(
        opacity: onPressed == null && !busy ? 0.5 : 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    tonal || quiet
                        ? 'assets/ui/control-fill.webp'
                        : 'assets/ui/neon-spectrum.webp',
                    excludeFromSemantics: true,
                    fit: BoxFit.fill,
                    color: tonal || quiet ? VimiColors.tonal : null,
                    colorBlendMode: tonal || quiet ? BlendMode.srcIn : null,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ink,
                  disabledForegroundColor: ink,
                  minimumSize: const Size(48, 52),
                  padding: EdgeInsets.symmetric(
                    horizontal: quiet ? 14 : 20,
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
    this.filled = false,
    this.primary = false,
    this.selected,
    this.busy = false,
  });
  final Glyph glyph;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool filled, primary, busy;
  final bool? selected;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: busy ? '$label, please wait' : label,
    selected: selected,
    liveRegion: busy,
    enabled: !busy && onPressed != null,
    focusable: !busy && onPressed != null,
    onTap: busy ? null : onPressed,
    excludeSemantics: true,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (filled || primary || selected == true)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  primary || selected == true
                      ? 'assets/ui/neon-spectrum.webp'
                      : 'assets/ui/control-fill.webp',
                  excludeFromSemantics: true,
                  fit: BoxFit.fill,
                  color: primary || selected == true ? null : VimiColors.tonal,
                  colorBlendMode: primary || selected == true
                      ? null
                      : BlendMode.srcIn,
                ),
              ),
            ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: primary || selected == true
                  ? VimiColors.onAccent
                  : color,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: busy ? null : onPressed,
            child: Opacity(
              opacity: onPressed == null || busy ? .45 : 1,
              child: VIcon(
                glyph,
                color: primary || selected == true
                    ? VimiColors.onAccent
                    : color,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A destination is read as one row, rather than a separate text action.
class VActionRow extends StatelessWidget {
  const VActionRow(
    this.label, {
    super.key,
    required this.glyph,
    required this.onPressed,
    this.detail,
    this.value,
    this.danger = false,
  });
  final String label;
  final Glyph glyph;
  final VoidCallback? onPressed;
  final String? detail, value;
  final bool danger;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: danger ? VimiColors.danger : VimiColors.ink,
      minimumSize: const Size(48, 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    child: Row(
      children: [
        VIcon(glyph, color: danger ? VimiColors.danger : VimiColors.violet),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: danger ? VimiColors.danger : VimiColors.ink,
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail!,
                  style: const TextStyle(color: VimiColors.muted, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (value != null) ...[
          Text(
            value!,
            style: const TextStyle(
              color: VimiColors.cyan,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
        ],
        const VIcon(Glyph.next, size: 16, color: VimiColors.muted),
      ],
    ),
  );
}

class VProfileStat extends StatelessWidget {
  const VProfileStat({
    super.key,
    required this.count,
    required this.label,
    required this.onPressed,
  });
  final int count;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$count $label',
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: VimiColors.ink,
        minimumSize: const Size(80, 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              label,
              style: const TextStyle(color: VimiColors.muted, fontSize: 14),
            ),
          ],
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
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
  return '${months[local.month - 1]} ${local.day}${local.year == DateTime.now().year ? '' : ', ${local.year}'}';
}

String displayMessageTime(DateTime date) {
  final local = date.toLocal();
  return '${displayDate(local)} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    required this.label,
    this.url,
    this.alignment = Alignment.center,
    this.size = 48,
  });
  final String name, label;
  final String? url;
  final Alignment alignment;
  final double size;
  @override
  Widget build(BuildContext context) {
    final image = url;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
    final fallback = ColoredBox(
      color: VimiColors.tonal,
      child: Center(
        child: Text(
          initials.isEmpty ? 'D' : initials,
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontSize: size * .34,
            fontWeight: FontWeight.w700,
            color: VimiColors.violet,
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: image == null
              ? fallback
              : Image.network(
                  image,
                  cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                      .ceil()
                      .clamp(32, 216)
                      .toInt(),
                  fit: BoxFit.cover,
                  alignment: alignment,
                  excludeFromSemantics: true,
                  frameBuilder: (_, child, frame, _) =>
                      frame == null ? fallback : child,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
