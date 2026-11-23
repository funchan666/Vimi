import 'package:flutter/material.dart';

import '../../design/vimi_ui.dart';

class CoinPackGrid extends StatelessWidget {
  const CoinPackGrid({
    required this.packs,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<({String id, int coins, String? price})> packs;
  final String? selectedId;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context);
        final columns = constraints.maxWidth >= 280 && textScale.scale(20) <= 28
            ? 2
            : 1;
        final tiles = [
          for (final pack in packs)
            _CoinPackTile(
              amount: MaterialLocalizations.of(
                context,
              ).formatDecimal(pack.coins),
              price: pack.price,
              selected: pack.id == selectedId,
              onPressed: onSelected == null ? null : () => onSelected!(pack.id),
            ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            for (var index = 0; index < tiles.length; index += columns)
              if (columns == 2 && index + 1 < tiles.length)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: gap,
                    children: [
                      Expanded(child: tiles[index]),
                      Expanded(child: tiles[index + 1]),
                    ],
                  ),
                )
              else
                tiles[index],
          ],
        );
      },
    );
  }
}

class _CoinPackTile extends StatelessWidget {
  const _CoinPackTile({
    required this.amount,
    required this.price,
    required this.selected,
    required this.onPressed,
  });

  final String amount;
  final String? price;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    const corners = BorderRadius.all(Radius.circular(14));
    final type = Theme.of(context).textTheme;
    final contents = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 58),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: amount,
                          style: type.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        TextSpan(
                          text: ' coins',
                          style: type.bodyMedium?.copyWith(
                            color: VimiColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (price case final value?)
                    Text(
                      value,
                      style: type.labelLarge?.copyWith(color: VimiColors.cyan),
                    ),
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const VIcon(Glyph.check, size: 16, color: VimiColors.accent),
            ],
          ],
        ),
      ),
    );
    return Material(
      type: MaterialType.transparency,
      borderRadius: corners,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? VimiColors.tonal : VimiColors.surface,
          borderRadius: corners,
          border: Border.all(
            color: selected
                ? VimiColors.accent
                : VimiColors.line.withValues(alpha: .35),
          ),
        ),
        child: onPressed == null
            ? contents
            : MergeSemantics(
                child: Semantics(
                  button: true,
                  selected: selected,
                  child: InkWell(
                    onTap: onPressed,
                    borderRadius: corners,
                    focusColor: VimiColors.cyan.withValues(alpha: .18),
                    child: contents,
                  ),
                ),
              ),
      ),
    );
  }
}
