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
  const DanceShell({super.key});
  @override
  State<DanceShell> createState() => _DanceShellState();
}

class _DanceShellState extends State<DanceShell> {
  int tab = 0;
  static const titles = ['Floor', 'Studio', 'Inbox', 'Me'];
  static const icons = [Glyph.floor, Glyph.studio, Glyph.inbox, Glyph.person];
  void select(int next) {
    if (next == tab) return;
    PlaybackCoordinator.pauseAll();
    setState(() => tab = next);
  }

  Widget navigation(bool expanded) => SurfacePanel(
    padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 4, vertical: 8),
    child: expanded
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text('vimi', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 40),
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VButton(
                    titles[i],
                    glyph: icons[i],
                    tonal: true,

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
                        foregroundColor: VimiColors.ink,
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
                            color: tab == i ? VimiColors.ink : VimiColors.muted,
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
                          if (tab == i)
                            Image.asset(
                              'assets/ui/control-fill.webp',
                              width: 24,
                              height: 4,
                              color: VimiColors.ink,
                              colorBlendMode: BlendMode.srcIn,
                              fit: BoxFit.fill,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
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
                      expanded ? titles[tab] : 'vimi',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * .5,
                    ),
                    child: VButton(
                      'Share a dance',
                      glyph: Glyph.add,
                      quiet: true,
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
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/ui/surface-clean.webp',
                  fit: BoxFit.cover,
                  color: VimiColors.surface,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
              SafeArea(
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
            ],
          ),
        );
      },
    );
  }
}
