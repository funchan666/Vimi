import 'package:flutter/material.dart';
import '../core/app_controller.dart';
import '../design/vimi_ui.dart';
import 'auth/auth_pages.dart';
import 'community/community_pages.dart';
import 'community/publish_page.dart';
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
  @override
  void initState() {
    super.initState();
    tab = widget.initialTab;
  }

  static const titles = ['Floor', 'Studio', 'Inbox', 'Me'];
  static const icons = [Glyph.floor, Glyph.studio, Glyph.inbox, Glyph.person];
  void select(int next) {
    if (next == tab) return;
    PlaybackCoordinator.pauseAll();
    setState(() => tab = next);
  }

  Widget destination(int index) => SizedBox(
    width: 60,
    height: 52,
    child: VIconButton(
      icons[index],
      label: titles[index],
      selected: tab == index,
      color: VimiColors.muted,
      onPressed: () => select(index),
    ),
  );

  Widget navigation(bool expanded) => Padding(
    padding: EdgeInsets.fromLTRB(expanded ? 12 : 20, 8, expanded ? 12 : 20, 10),
    child: SurfacePanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: expanded
          ? SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < titles.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
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
        final body = Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titles[tab],
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * .5,
                    ),
                    child: VIconButton(
                      Glyph.add,
                      label: 'Post',
                      primary: true,
                      onPressed: () async {
                        if (await requireSignIn(context) && context.mounted)
                          await openPage(context, const PublishPage());
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: IndexedStack(
                    index: tab,
                    children: [
                      FloorPage(key: ValueKey('floor-${app.account}')),
                      const StudioPage(),
                      InboxPage(key: ValueKey('inbox-${app.account}')),
                      const MePage(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        return Scaffold(
          body: NeonBackdrop(
            child: SafeArea(
              child: expanded
                  ? Row(
                      children: [
                        SizedBox(width: 112, child: navigation(true)),
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
