import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../design/vimi_ui.dart';
import 'community/cover_feed_page.dart';
import 'messages/inbox_pages.dart';
import 'profile/profile_pages.dart';
import 'studio/rehearsal_player.dart';
import 'studio/studio_pages.dart';

class DanceShell extends StatefulWidget {
  const DanceShell({super.key, this.initialTab = 0});
  final int initialTab;
  @override
  State<DanceShell> createState() => _DanceShellState();
}

class _DanceShellState extends State<DanceShell> {
  late int tab;
  late final Set<int> opened;
  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
    opened = {tab};
  }

  static const titles = ['Floor', 'Studio', 'Inbox', 'Me'];
  static const icons = [Glyph.floor, Glyph.studio, Glyph.inbox, Glyph.person];
  void select(int next) {
    if (next == tab) return;
    PlaybackCoordinator.pauseAll();
    setState(() {
      tab = next;
      opened.add(next);
    });
  }

  Widget destination(int index) => SizedBox(
    width: 52,
    height: 48,
    child: VIconButton(
      icons[index],
      label: titles[index],
      selected: tab == index,
      color: VimiColors.muted,
      onPressed: () => select(index),
    ),
  );

  Widget navigation(bool expanded) => Padding(
    padding: EdgeInsets.fromLTRB(expanded ? 10 : 16, 4, expanded ? 10 : 16, 8),
    child: SurfacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: expanded
          ? SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < titles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    destination(i),
                  ],
                ],
              ),
            )
          : Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(child: Center(child: destination(i))),
              ],
            ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded = constraints.maxWidth >= 760;
        final pages = [
          CoverFeedPage(
            key: ValueKey('floor-${app.account}'),
            active: tab == 0,
          ),
          const StudioPage(),
          InboxPage(key: ValueKey('inbox-${app.account}'), active: tab == 2),
          const MePage(),
        ];
        final body = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: IndexedStack(
              index: tab,
              children: [
                for (var i = 0; i < pages.length; i++)
                  opened.contains(i) ? pages[i] : const SizedBox.shrink(),
              ],
            ),
          ),
        );
        return Scaffold(
          body: NeonBackdrop(
            child: SafeArea(
              child: expanded
                  ? Row(
                      children: [
                        SizedBox(width: 84, child: navigation(true)),
                        Expanded(child: body),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: body),
                        navigation(false),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
