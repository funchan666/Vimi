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

  Widget navigation(bool expanded) => Padding(
    padding: EdgeInsets.fromLTRB(expanded ? 8 : 12, 8, expanded ? 8 : 12, 10),
    child: SurfacePanel(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 4, vertical: 8),
      child: expanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const VimiWordmark(),
                const SizedBox(height: 40),
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: VButton(
                      titles[i],
                      glyph: icons[i],
                      quiet: tab != i,
                      onPressed: () => select(i),
                    ),
                  ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: Semantics(
                      selected: tab == i,
                      child: TextButton(
                        onPressed: () => select(i),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 56),
                          foregroundColor: tab == i
                              ? VimiColors.accent
                              : VimiColors.muted,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VIcon(
                              icons[i],
                              size: 24,
                              color: tab == i
                                  ? VimiColors.accent
                                  : VimiColors.muted,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              titles[i],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: tab == i
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 24,
                              height: 3,
                              child: tab == i
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(2),
                                      child: Image.asset(
                                        'assets/ui/neon-spectrum.webp',
                                        fit: BoxFit.fill,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                    child: expanded
                        ? Text(
                            titles[tab],
                            style: Theme.of(context).textTheme.headlineSmall,
                          )
                        : const VimiWordmark(),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * .5,
                    ),
                    child: VButton(
                      'Post',
                      glyph: Glyph.add,
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
                        SizedBox(width: 200, child: navigation(true)),
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
