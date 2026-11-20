import 'package:flutter/material.dart';
import '../core/pagination.dart';
import '../core/dance_repository.dart';
import 'vimi_ui.dart';

class PageFooter<T> extends StatelessWidget {
  const PageFooter({
    super.key,
    required this.pager,
    required this.moreLabel,
    this.loadingLabel = 'Loading…',
  });
  final CursorPager<T> pager;
  final String moreLabel, loadingLabel;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (pager.error != null)
        ErrorNote(readableError(pager.error!), onRetry: pager.retry),
      if (pager.loading)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(loadingLabel),
        ),
      if (!pager.loading &&
          pager.error == null &&
          pager.loaded &&
          pager.hasMore)
        Center(
          child: VIconButton(
            Glyph.next,
            label: moreLabel,
            filled: true,
            onPressed: pager.loadMore,
          ),
        ),
    ],
  );
}
