import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/local_studio.dart';
import '../../core/models.dart';
import '../../core/pagination.dart';
import '../../core/media_library.dart';
import '../../design/page_footer.dart';
import '../../design/vimi_ui.dart';
import '../../design/library_image.dart';
import '../auth/auth_pages.dart';
import '../community/community_pages.dart';
import '../messages/direct_calls.dart';
import '../messages/inbox_pages.dart';
import 'license_page.dart';
import 'help_pages.dart';
import 'moderation_pages.dart';
import '../auth/account_security_pages.dart';
import '../studio/media_library_pages.dart';
import '../studio/studio_clip_credit.dart';
import '../studio/studio_pages.dart';
import 'personal_activity.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final profile = app.profile;
    if (!app.signedIn) {
      return Center(
        child: VButton(
          'Sign in',
          onPressed: () => openPage(context, const AuthPage(signUp: false)),
        ),
      );
    }
    if (profile == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: app.cloudError != null
            ? ErrorNote(
                app.cloudError!,
                onRetry: () => unawaited(app.refreshAccount()),
              )
            : const Text('Opening your profile…'),
      );
    }
    void editProfile() => openPage(context, EditProfilePage(profile: profile));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SurfacePanel(
              illuminated: true,
              padding: const EdgeInsets.fromLTRB(14, 16, 8, 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileIdentity(
                    profile: profile,
                    avatarSize: 70,
                    onAvatarTap: editProfile,
                    actions: [
                      VIconButton(
                        Glyph.edit,
                        label: 'Edit dance profile',
                        color: VimiColors.violet,
                        onPressed: editProfile,
                      ),
                      VIconButton(
                        Glyph.settings,
                        label: 'Open settings',
                        onPressed: () =>
                            openPage(context, const SettingsPage()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, color: VimiColors.tonal),
                  _ProfileRelations(profile: profile),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Semantics(
                header: true,
                child: Text(
                  'Your library',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            SurfacePanel(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Column(
                children: [
                  VActionRow(
                    'Practice history',
                    glyph: Glyph.studio,
                    detail: app.journalError != null
                        ? 'Open your private journal'
                        : '${app.practices.length} saved notes',
                    onPressed: () =>
                        openPage(context, const PracticeHistoryPage()),
                  ),
                  const Divider(height: 1, color: VimiColors.tonal, indent: 52),
                  VActionRow(
                    'Saved clips',
                    glyph: Glyph.video,
                    detail: 'Rewatch your rehearsal references',
                    onPressed: () => openPage(
                      context,
                      MediaLibraryPage(
                        showSaved: true,
                        practiceBuilder: (clip) =>
                            PracticeEditor(initialClip: clip),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: VimiColors.tonal, indent: 52),
                  VActionRow(
                    'Saved covers',
                    glyph: Glyph.save,
                    detail: 'Revisit posts you bookmarked',
                    onPressed: () => openPage(context, const SavedPostsPage()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PersonalActivity(key: ValueKey('mine-${app.account}')),
          ],
        ),
      ),
    );
  }
}

const _profileSection = TextStyle(fontSize: 17, fontWeight: FontWeight.w700);
const _profileMeta = TextStyle(fontSize: 13, color: VimiColors.muted);

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.profile,
    required this.actions,
    this.onAvatarTap,
    this.avatarSize = 56,
  });
  final Dancer profile;
  final List<Widget> actions;
  final VoidCallback? onAvatarTap;
  final double avatarSize;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (onAvatarTap == null)
            SignedAvatar(profile, size: avatarSize)
          else
            Tooltip(
              message: 'Change profile photo',
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onAvatarTap,
                  child: Ink(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/ui/neon-spectrum.webp'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: SignedAvatar(profile, size: avatarSize),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (profile.styles.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.styles.join(' · '),
                    style: _profileMeta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
      if (profile.bio.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(profile.bio, style: const TextStyle(fontSize: 14, height: 1.4)),
      ],
    ],
  );
}

class _ProfileRelations extends StatelessWidget {
  const _ProfileRelations({required this.profile});
  final Dancer profile;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _relation(context, followers: true, count: profile.followers),
      ),
      Expanded(
        child: _relation(context, followers: false, count: profile.following),
      ),
    ],
  );

  Widget _relation(
    BuildContext context, {
    required bool followers,
    required int count,
  }) {
    final label = followers ? 'followers' : 'following';
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      ),
      onPressed: () => openPage(
        context,
        RelationsPage(id: profile.id, followers: followers),
      ),
      child: Wrap(
        spacing: 5,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 15,
              color: VimiColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: _profileMeta),
        ],
      ),
    );
  }
}

class DancerDirectory extends StatefulWidget {
  const DancerDirectory({super.key});
  @override
  State<DancerDirectory> createState() => _DancerDirectoryState();
}

class _DancerDirectoryState extends State<DancerDirectory> {
  final query = TextEditingController();
  CursorPager<Dancer>? pager;
  String? owner;
  String submittedQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (app.signedIn && owner != app.account) search();
  }

  void search() {
    final app = VimiScope.of(context);
    if (!app.signedIn) return;
    pager?.dispose();
    owner = app.account;
    final currentOwner = owner;
    final term = query.text.trim();
    final repo = app.repo!;
    setState(() {
      submittedQuery = term;
      pager = CursorPager(
        fetch: (cursor) => repo.dancerPage(term, cursor: cursor),
        identity: (dancer) => dancer.id,
        isCurrent: () => app.signedIn && app.account == currentOwner,
      );
    });
    unawaited(pager!.refresh());
  }

  void submitSearch() {
    FocusScope.of(context).unfocus();
    search();
  }

  void clearSearch() {
    query.clear();
    submitSearch();
  }

  @override
  void dispose() {
    query.dispose();
    pager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: 'Dancers',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          TextField(
            controller: query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => submitSearch(),
            decoration: InputDecoration(
              labelText: 'Search dancer names',
              hintText: 'Name or @handle',
              suffixIcon: VIconButton(
                Glyph.search,
                label: 'Find dancers',
                color: VimiColors.cyan,
                onPressed: submitSearch,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!app.signedIn)
            VButton(
              'Sign in to meet the community',
              onPressed: () => openPage(context, const AuthPage(signUp: false)),
            )
          else if (pager case final directory?)
            _results(app, directory),
        ],
      ),
    );
  }

  Widget _results(AppController app, CursorPager<Dancer> directory) =>
      FutureBuilder<MediaLibrary>(
        future: app.avatarLibrary,
        builder: (context, studio) {
          final library = studio.data;
          final covers = library == null
              ? const <LibraryClip>[]
              : StudioClipCredit.findClips(library, submittedQuery)
                    .where(
                      (clip) =>
                          app.studio.studioCreatorPreference(
                            app.account,
                            clip.id,
                          ) !=
                          StudioCreatorPreference.hidden,
                    )
                    .toList();
          return AnimatedBuilder(
            animation: directory,
            builder: (context, _) {
              final emptyCommunity =
                  directory.loaded &&
                  !directory.loading &&
                  directory.items.isEmpty &&
                  directory.error == null;
              final emptyDirectory =
                  emptyCommunity && library != null && covers.isEmpty;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (covers.isNotEmpty) ...[
                    _sectionTitle('Studio editorial profiles'),
                    for (final clip in covers) _studioResult(clip),
                    const Divider(height: 20, color: VimiColors.tonal),
                    _sectionTitle('Community dancers'),
                  ],
                  if (emptyDirectory)
                    Row(
                      children: [
                        Expanded(
                          child: _directoryStatus(
                            submittedQuery.isEmpty
                                ? 'No dancers to browse yet.'
                                : 'No dancers match this search.',
                          ),
                        ),
                        if (submittedQuery.isNotEmpty)
                          VIconButton(
                            Glyph.close,
                            label: 'Clear dancer search',
                            color: VimiColors.violet,
                            onPressed: clearSearch,
                          ),
                      ],
                    )
                  else if (emptyCommunity)
                    _directoryStatus(
                      submittedQuery.isEmpty
                          ? 'No community dancers to browse yet.'
                          : 'No community dancers match this search.',
                    ),
                  for (final dancer in directory.items)
                    DancerRow(dancer, key: ValueKey(dancer.id)),
                  PageFooter(
                    pager: directory,
                    moreLabel: 'More dancers',
                    loadingLabel: 'Finding dancers…',
                  ),
                  if (studio.hasError)
                    _directoryStatus('Studio profiles are unavailable.')
                  else if (library == null)
                    _directoryStatus('Opening Studio profiles…'),
                ],
              );
            },
          );
        },
      );

  Widget _studioResult(LibraryClip clip) {
    final credit = StudioClipCredit.forClip(clip);
    return _DirectoryProfileRow(
      key: ValueKey(clip.source),
      name: credit.name,
      detail: credit.handle,
      avatar: StudioClipAvatar(clip: clip, size: 42),
      onPressed: () {
        FocusScope.of(context).unfocus();
        openPage(
          context,
          StudioCreatorProfilePage(
            clip: clip,
            practiceBuilder: (clip) => PracticeEditor(initialClip: clip),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
    child: Semantics(
      header: true,
      child: Text(label, style: Theme.of(context).textTheme.titleSmall),
    ),
  );

  Widget _directoryStatus(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Semantics(
      liveRegion: true,
      child: Text(message, style: _profileMeta),
    ),
  );
}

class DancerRow extends StatelessWidget {
  const DancerRow(this.dancer, {super.key});
  final Dancer dancer;
  @override
  Widget build(BuildContext context) => _DirectoryProfileRow(
    name: dancer.name,
    detail: dancer.styles.isEmpty ? null : dancer.styles.join(' · '),
    avatar: SignedAvatar(dancer, size: 42),
    onPressed: () => openPage(context, DancerPage(id: dancer.id)),
  );
}

class _DirectoryProfileRow extends StatelessWidget {
  const _DirectoryProfileRow({
    super.key,
    required this.name,
    required this.detail,
    required this.avatar,
    required this.onPressed,
  });

  final String name;
  final String? detail;
  final Widget avatar;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      foregroundColor: VimiColors.ink,
    ),
    onPressed: onPressed,
    child: Row(
      children: [
        avatar,
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail case final subtitle?)
                Text(subtitle, style: _profileMeta),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const VIcon(Glyph.next, color: VimiColors.muted, size: 16),
      ],
    ),
  );
}

class RelationsPage extends StatefulWidget {
  const RelationsPage({super.key, required this.id, required this.followers});
  final String id;
  final bool followers;
  @override
  State<RelationsPage> createState() => _RelationsPageState();
}

class _RelationsPageState extends State<RelationsPage> {
  CursorPager<Dancer>? pager;
  String? owner;
  int revision = -1;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (owner != app.account || pager == null) {
      pager?.dispose();
      owner = app.account;
      final currentOwner = owner;
      pager = CursorPager(
        fetch: (cursor) => app.repo!.relationPage(
          widget.id,
          followers: widget.followers,
          cursor: cursor,
        ),
        identity: (dancer) => dancer.id,
        isCurrent: () => app.signedIn && app.account == currentOwner,
      );
    }
    if (revision != app.revision) {
      revision = app.revision;
      unawaited(pager!.refresh());
    }
  }

  @override
  void dispose() {
    pager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: widget.followers ? 'Followers' : 'Following',
    actions: [
      VIconButton(
        Glyph.refresh,
        label: 'Refresh dancers',
        onPressed: () => pager!.refresh(),
      ),
    ],
    child: AnimatedBuilder(
      animation: pager!,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (pager!.loaded && pager!.items.isEmpty && pager!.error == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                widget.followers
                    ? 'No followers yet.'
                    : 'No followed dancers yet.',
                style: _profileMeta,
              ),
            ),
          for (final dancer in pager!.items)
            DancerRow(dancer, key: ValueKey(dancer.id)),
          PageFooter(
            pager: pager!,
            moreLabel: 'More dancers',
            loadingLabel: 'Opening dancers…',
          ),
        ],
      ),
    ),
  );
}

class DancerPage extends StatefulWidget {
  const DancerPage({super.key, required this.id});
  final String id;
  @override
  State<DancerPage> createState() => _DancerPageState();
}

class _DancerPageState extends State<DancerPage> {
  Future<Dancer?>? future;
  String? owner;
  int revision = -1;
  bool busy = false;
  bool? checkingVideoCall;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    final nextOwner = app.signedIn ? app.account : null;
    if (owner != nextOwner) {
      owner = nextOwner;
      revision = -1;
      busy = false;
      checkingVideoCall = null;
    }
    if (revision != app.revision) {
      revision = app.revision;
      future = nextOwner == null ? null : app.repo!.dancer(widget.id);
    }
  }

  bool _sameAccount(AppController app, String account) =>
      mounted && app.signedIn && app.account == account;

  Future<void> _follow(Dancer profile) async {
    final app = VimiScope.of(context);
    final account = app.account;
    if (!app.signedIn ||
        profile.id == account ||
        busy ||
        checkingVideoCall != null) {
      return;
    }
    setState(() => busy = true);
    try {
      await app.repo!.follow(profile.id, followed: !profile.isFollowing);
      if (_sameAccount(app, account)) await app.refreshAccount();
    } catch (error) {
      if (_sameAccount(app, account)) feedback(context, readableError(error));
    } finally {
      if (_sameAccount(app, account)) setState(() => busy = false);
    }
  }

  Future<void> _startCall(Dancer profile, {required bool video}) async {
    final app = VimiScope.of(context);
    final account = app.account;
    if (!app.signedIn ||
        profile.id == account ||
        busy ||
        checkingVideoCall != null) {
      return;
    }
    setState(() => checkingVideoCall = video);
    try {
      await startMemberCall(context, profile, video: video);
    } finally {
      if (_sameAccount(app, account)) {
        setState(() => checkingVideoCall = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final calls = DirectCallScope.maybeOf(context);
    return VPage(
      title: '',
      child: FutureBuilder<Dancer?>(
        key: ValueKey(owner),
        future: future,
        builder: (context, snapshot) {
          if (!app.signedIn) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sign in to view this dancer.', style: _profileMeta),
            );
          }
          if (snapshot.hasError)
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorNote(
                readableError(snapshot.error!),
                onRetry: app.changed,
              ),
            );
          if (!snapshot.hasData &&
              snapshot.connectionState != ConnectionState.done)
            return const Center(child: Text('Opening dancer…'));
          final profile = snapshot.data;
          if (profile == null)
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Text('This profile is unavailable.', style: _profileMeta),
            );
          final canInteract = app.signedIn && profile.id != app.account;
          final mutual = profile.isFollowing && profile.followsYou;
          final checkingCall = checkingVideoCall != null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _ProfileIdentity(
                profile: profile,
                actions: [
                  if (canInteract) ...[
                    VIconButton(
                      Glyph.report,
                      label: 'Report dancer',
                      onPressed: () =>
                          reportContent(context, 'user', profile.id),
                    ),
                    VIconButton(
                      Glyph.block,
                      label: 'Block dancer',
                      onPressed: () => blockDancer(context, profile),
                    ),
                  ],
                ],
              ),
              _ProfileRelations(profile: profile),
              if (canInteract) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    VButton(
                      profile.isFollowing ? 'Following' : 'Follow dancer',
                      glyph: profile.isFollowing ? Glyph.check : Glyph.add,
                      tonal: profile.isFollowing,
                      busy: busy,
                      onPressed: checkingCall ? null : () => _follow(profile),
                    ),
                    VIconButton(
                      Glyph.inbox,
                      label: 'Message',
                      color: VimiColors.cyan,
                      filled: true,
                      onPressed: checkingCall
                          ? null
                          : () => openPage(context, ChatPage(peer: profile)),
                    ),
                    VIconButton(
                      Glyph.phone,
                      label: 'Voice call',
                      color: VimiColors.cyan,
                      filled: true,
                      busy: checkingVideoCall == false,
                      onPressed: calls == null || busy || checkingCall
                          ? null
                          : () => _startCall(profile, video: false),
                    ),
                    VIconButton(
                      Glyph.video,
                      label: 'Video call',
                      color: VimiColors.cyan,
                      filled: true,
                      busy: checkingVideoCall == true,
                      onPressed: calls == null || busy || checkingCall
                          ? null
                          : () => _startCall(profile, video: true),
                    ),
                  ],
                ),
                if (!mutual)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Follow each other to message or call.',
                      style: _profileMeta,
                    ),
                  ),
              ],
              const Divider(height: 16, color: VimiColors.tonal),
              const Text('Covers', style: _profileSection),
              PostCollection(
                key: ValueKey('${profile.id}-${app.account}'),
                author: profile.id,
              ),
            ],
          );
        },
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.profile,
    this.initialPortrait,
  });
  final Dancer profile;
  final LibraryPortrait? initialPortrait;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController name, bio;
  late Set<String> styles;
  File? photo;
  LibraryPortrait? libraryPhoto;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.profile.name);
    bio = TextEditingController(text: widget.profile.bio);
    styles = widget.profile.styles.toSet();
    libraryPhoto = widget.initialPortrait;
  }

  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> choose(ImageSource source) async {
    if (busy) return;
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (file != null && mounted) {
        setState(() {
          photo = File(file.path);
          libraryPhoto = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    }
  }

  Future<void> chooseLibraryPhoto() async {
    if (busy) return;
    final selected = await openPage<LibraryPortrait>(
      context,
      const PortraitPickerPage(),
    );
    if (selected != null && mounted) {
      setState(() {
        libraryPhoto = selected;
        photo = null;
      });
    }
  }

  Future<void> save() async {
    if (busy) return;
    if (name.text.trim().length < 2 || styles.isEmpty) {
      setState(() => error = 'Add a name and at least one dance style.');
      return;
    }
    final app = VimiScope.of(context);
    final owner = app.account;
    Directory? temporary;
    setState(() => busy = true);
    try {
      var chosen = photo;
      if (libraryPhoto != null) {
        final portrait = libraryPhoto!;
        final bytes = await portrait.download();
        if (!mounted || app.account != owner) return;
        temporary = await (await getTemporaryDirectory()).createTemp(
          'vimi-avatar-',
        );
        chosen = await File(
          '${temporary.path}/portrait.${portrait.extension}',
        ).writeAsBytes(bytes);
      }
      if (!mounted || app.account != owner) return;
      final path = chosen == null
          ? widget.profile.avatar
          : await app.repo!.upload(chosen, avatar: true, video: false);
      if (!mounted || app.account != owner) return;
      await app.repo!.updateProfile(
        name.text.trim(),
        bio.text.trim(),
        styles.toList(),
        path,
      );
      await app.refreshAccount();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (temporary != null) {
        try {
          await temporary.delete(recursive: true);
        } on FileSystemException {
          // A cache-cleanup failure must not misreport a completed profile save.
        }
      }
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'Edit profile',
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            if (libraryPhoto != null)
              ClipOval(
                child: LibraryImage(
                  libraryPhoto!.thumbnail,
                  compact: true,
                  width: 72,
                  height: 72,
                  label: 'Selected profile photo',
                ),
              )
            else if (photo != null)
              ClipOval(
                child: Image.file(
                  photo!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  semanticLabel: 'Selected profile photo',
                ),
              )
            else
              SignedAvatar(widget.profile, size: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  VIconButton(
                    Glyph.library,
                    label: 'Browse profile images',
                    primary: true,
                    onPressed: busy ? null : chooseLibraryPhoto,
                  ),
                  VIconButton(
                    Glyph.photo,
                    label: 'Choose photo',
                    color: VimiColors.violet,
                    onPressed: busy ? null : () => choose(ImageSource.gallery),
                  ),
                  VIconButton(
                    Glyph.camera,
                    label: 'Take photo',
                    color: VimiColors.cyan,
                    onPressed: busy ? null : () => choose(ImageSource.camera),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          photo != null || libraryPhoto != null
              ? 'Your new photo is visible to members after you save.'
              : (widget.profile.avatar?.trim().isEmpty ?? true)
              ? 'Your default photo comes from the profile image library.'
              : 'Your profile is visible to members.',
          style: _profileMeta,
        ),
        const SizedBox(height: 16),
        VField('Display name', controller: name, maxLength: 40, enabled: !busy),
        VField(
          'A little about your dancing',
          controller: bio,
          enabled: !busy,
          lines: 3,
          maxLength: 280,
        ),
        const Text('Your dance styles'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: DanceStyle.values
              .map(
                (s) => VButton(
                  s.label,

                  quiet: !styles.contains(s.label),
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          if (!styles.add(s.label)) styles.remove(s.label);
                        }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        if (error != null) ErrorNote(error!),
        VButton('Save profile', busy: busy, onPressed: save),
      ],
    ),
  );
}

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: 'Saved covers',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PostCollection(key: ValueKey('saved-${app.account}'), saved: true),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    const support = String.fromEnvironment('SUPPORT_URL');
    const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
    return VPage(
      title: 'Settings',

      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Your space', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          VActionRow(
            'Blocked dancers',
            glyph: Glyph.block,
            onPressed: () => openPage(context, const BlockedDancersPage()),
          ),
          VActionRow(
            'Your reports',
            glyph: Glyph.report,
            onPressed: () => openPage(context, const MyReportsPage()),
          ),
          VActionRow(
            'Help & safety',
            glyph: Glyph.report,
            onPressed: () => openPage(context, const HelpCenterPage()),
          ),
          VActionRow(
            'Change password',
            glyph: Glyph.settings,
            onPressed: () => openPage(context, const ChangePasswordPage()),
          ),
          if (app.isModerator)
            VActionRow(
              'Content review',
              glyph: Glyph.check,
              onPressed: () => openPage(context, const ModerationPage()),
            ),
          const SizedBox(height: 24),
          Text(
            'Safety & policies',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          VActionRow(
            'Community guidelines',
            glyph: Glyph.person,
            onPressed: () => openPage(
              context,
              const LegalPage('Community guidelines', 'community'),
            ),
          ),
          VActionRow(
            'Child safety standards',
            glyph: Glyph.report,
            onPressed: () => openPage(
              context,
              const LegalPage('Child safety standards', 'child-safety'),
            ),
          ),
          VActionRow(
            'Account deletion & data',
            glyph: Glyph.delete,
            onPressed: () => openPage(
              context,
              const LegalPage('Account deletion & data', 'deletion'),
            ),
          ),
          VActionRow(
            'Privacy Policy',
            glyph: Glyph.save,
            onPressed: () =>
                openPage(context, const LegalPage('Privacy Policy', 'privacy')),
          ),
          VActionRow(
            'Terms of Use',
            glyph: Glyph.library,
            onPressed: () =>
                openPage(context, const LegalPage('Terms of Use', 'terms')),
          ),
          if (support.isNotEmpty || supportEmail.isNotEmpty)
            VActionRow(
              'Contact support',
              glyph: Glyph.inbox,
              onPressed: () async {
                final uri = support.isNotEmpty
                    ? Uri.tryParse(support)
                    : Uri(
                        scheme: 'mailto',
                        path: supportEmail,
                        queryParameters: {'subject': 'Vimi support'},
                      );
                if (uri != null &&
                    ['https', 'mailto'].contains(uri.scheme) &&
                    !await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    ) &&
                    context.mounted)
                  feedback(
                    context,
                    'Support could not be opened. Please try again.',
                  );
              },
            ),
          VActionRow(
            'Open-source licenses',
            glyph: Glyph.library,
            onPressed: () => openPage(context, const VimiLicensesPage()),
          ),
          const SizedBox(height: 32),
          VActionRow(
            'Sign out',
            glyph: Glyph.logout,
            onPressed: () async {
              if (await confirmAction(
                    context,
                    title: 'Leave the floor for now?',
                    body: 'Your account and dance archive will stay here.',
                    action: 'Sign out',
                  ) &&
                  context.mounted) {
                try {
                  await app.signOut();
                } catch (e) {
                  if (context.mounted) feedback(context, readableError(e));
                }
              }
            },
          ),
          VActionRow(
            'Delete account',
            glyph: Glyph.delete,
            danger: true,
            onPressed: () => openPage(context, const DeleteAccountPage()),
          ),
          const SizedBox(height: 24),
          const Text(
            'Version 1.0.0',
            style: TextStyle(color: VimiColors.muted),
          ),
        ],
      ),
    );
  }
}

class BlockedDancersPage extends StatefulWidget {
  const BlockedDancersPage({super.key});
  @override
  State<BlockedDancersPage> createState() => _BlockedDancersPageState();
}

class _BlockedDancersPageState extends State<BlockedDancersPage> {
  Future<List<Dancer>>? future;
  final restoring = <String>{};
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      reload();
    }
  }

  void reload() =>
      setState(() => future = VimiScope.of(context).repo!.blocked());

  Future<void> restoreCreator(AppController app, LibraryClip clip) async {
    if (!app.signedIn || !restoring.add(clip.id)) return;
    final owner = app.account;
    setState(() {});
    try {
      await app.studio.setStudioCreatorPreference(
        owner,
        clip.id,
        StudioCreatorPreference.none,
      );
      if (!mounted || app.account != owner) return;
      app.changed();
      feedback(context, 'Creator is visible again.');
    } catch (error) {
      if (mounted && app.account == owner) {
        feedback(context, readableError(error));
      }
    } finally {
      restoring.remove(clip.id);
      if (mounted) setState(() {});
    }
  }

  Widget hiddenCreators(AppController app) => FutureBuilder<MediaLibrary>(
    future: app.avatarLibrary,
    builder: (context, snapshot) {
      final hidden = snapshot.data?.clips.where(
        (clip) =>
            app.studio.studioCreatorPreference(app.account, clip.id) ==
            StudioCreatorPreference.hidden,
      );
      if (hidden == null || hidden.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Hidden Studio creators', style: _profileSection),
            for (final clip in hidden)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    StudioClipAvatar(clip: clip, size: 36),
                    const SizedBox(width: 10),
                    Expanded(child: Text(StudioClipCredit.forClip(clip).name)),
                    const SizedBox(width: 8),
                    VButton(
                      'Show',
                      quiet: true,
                      busy: restoring.contains(clip.id),
                      onPressed: () => restoreCreator(app, clip),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: 'Blocked dancers',
      child: FutureBuilder<List<Dancer>>(
        future: future,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (snapshot.hasError)
              ErrorNote(readableError(snapshot.error!), onRetry: reload)
            else if (!snapshot.hasData)
              const Text('Opening your list…')
            else if (snapshot.data!.isEmpty)
              const EmptyNote(
                'No blocked dancers.',
                'Dancers you block will appear here.',
              )
            else
              for (final dancer in snapshot.data!)
                SurfacePanel(
                  child: Row(
                    children: [
                      Expanded(child: Text(dancer.name)),
                      VButton(
                        'Unblock',
                        quiet: true,
                        onPressed: () async {
                          if (!await confirmAction(
                                context,
                                title: 'Unblock ${dancer.name}?',
                                body:
                                    'You can see each other again. Follows will not be restored automatically.',
                                action: 'Unblock',
                              ) ||
                              !context.mounted)
                            return;
                          try {
                            final app = VimiScope.of(context);
                            await app.repo!.block(dancer.id, false);
                            app.changed();
                            reload();
                          } catch (e) {
                            if (context.mounted)
                              feedback(context, readableError(e));
                          }
                        },
                      ),
                    ],
                  ),
                ),
            if (app.signedIn) hiddenCreators(app),
          ],
        ),
      ),
    );
  }
}

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});
  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  Future<void> remove() async {
    if (busy) return;
    if (password.text.isEmpty) {
      setState(
        () => error = 'Enter your current password to confirm deletion.',
      );
      return;
    }
    final app = VimiScope.of(context);
    final owner = app.account;
    if (!await confirmAction(
          context,
          title: 'Permanently delete your account?',
          body:
              'Your profile, messages, posts and uploaded media will be deleted. Remaining coins cannot be transferred. Financial audit records may be retained without your account link.',
          action: 'Delete my account',
        ) ||
        !mounted)
      return;
    setState(() => busy = true);
    try {
      await app.repo!.client.auth.signInWithPassword(
        email: app.repo!.client.auth.currentUser!.email!,
        password: password.text,
      );
      await app.repo!.client.functions.invoke(
        'delete-account',
        body: {'confirm_user_id': owner},
      );
      await app.studio.clear(owner);
      final preferences = app.studio.preferences;
      for (final key
          in preferences.getKeys().where((k) => k.contains(owner)).toList()) {
        await preferences.remove(key);
      }
      await app.repo!.client.auth.signOut();
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'Delete your account',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'This permanently removes your dance identity, uploaded media, posts and messages. Enter your current password to confirm.',
        ),
        const SizedBox(height: 24),
        VField('Current password', controller: password, obscure: true),
        if (error != null) ErrorNote(error!),
        VButton('Delete account permanently', busy: busy, onPressed: remove),
      ],
    ),
  );
}
