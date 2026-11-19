import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_controller.dart';
import '../../core/dance_repository.dart';
import '../../core/models.dart';
import '../../design/vimi_ui.dart';
import '../auth/auth_pages.dart';
import '../community/community_pages.dart';
import '../messages/inbox_pages.dart';
import '../wallet/wallet_page.dart';
import 'license_page.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});
  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    final profile = app.profile;
    if (!app.signedIn)
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Your dance profile',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          EmptyNote(
            'Your dance story starts here.',
            'Create an account to share your work, follow dancers and keep your coin wallet.',
            action: VButton(
              'Create account',

              onPressed: () => openPage(context, const AuthPage(signUp: true)),
            ),
          ),
        ],
      );
    if (profile == null)
      return Padding(
        padding: EdgeInsets.all(32),
        child: app.cloudError != null
            ? ErrorNote(
                app.cloudError!,
                onRetry: () => unawaited(app.refreshAccount()),
              )
            : const Text('Opening your dance profile…'),
      );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            SignedAvatar(profile, size: 80),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            VIconButton(
              Glyph.settings,
              label: 'Open settings',
              onPressed: () => openPage(context, const SettingsPage()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile.styles.join(' · '),
          style: const TextStyle(color: VimiColors.muted),
        ),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(profile.bio, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            VButton(
              '${profile.followers} followers',
              quiet: true,
              onPressed: () => openPage(
                context,
                RelationsPage(id: profile.id, followers: true),
              ),
            ),
            VButton(
              '${profile.following} following',
              quiet: true,
              onPressed: () => openPage(
                context,
                RelationsPage(id: profile.id, followers: false),
              ),
            ),
            VButton(
              'Edit dance profile',
              quiet: true,
              onPressed: () =>
                  openPage(context, EditProfilePage(profile: profile)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SurfacePanel(
          child: Row(
            children: [
              const VIcon(Glyph.coin, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${app.coins} coins',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              VButton(
                'Wallet',
                quiet: true,
                onPressed: () => openPage(context, const WalletPage()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        VButton(
          'Saved inspiration',
          glyph: Glyph.save,
          quiet: true,
          onPressed: () => openPage(context, const SavedPostsPage()),
        ),
        const SizedBox(height: 24),
        Text(
          'Your dance archive',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        PostCollection(
          key: ValueKey('mine-${app.account}-${app.revision}'),
          author: app.account,
        ),
      ],
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
  Future<List<Dancer>>? future;
  bool started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      search();
    }
  }

  void search() {
    final app = VimiScope.of(context);
    if (app.signedIn)
      setState(() => future = app.repo!.searchDancers(query.text));
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: 'Find your dance people',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          VField('Search dancer names', controller: query),
          VButton('Find dancers', glyph: Glyph.search, onPressed: search),
          const SizedBox(height: 24),
          if (!app.signedIn)
            VButton(
              'Sign in to meet the community',
              onPressed: () => openPage(context, const AuthPage(signUp: false)),
            )
          else
            FutureBuilder<List<Dancer>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return ErrorNote(
                    readableError(snapshot.error!),
                    onRetry: search,
                  );
                if (snapshot.connectionState != ConnectionState.done)
                  return const Text('Finding dancers…');
                final dancers = (snapshot.data ?? [])
                    .where((p) => p.id != app.account)
                    .toList();
                if (dancers.isEmpty)
                  return const EmptyNote(
                    'Room for a new dance circle.',
                    'No dancers found yet. Share your own cover to get the floor started.',
                  );
                return Column(
                  children: dancers.map((p) => DancerRow(p)).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class DancerRow extends StatelessWidget {
  const DancerRow(this.dancer, {super.key});
  final Dancer dancer;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextButton(
      onPressed: () => openPage(context, DancerPage(id: dancer.id)),
      child: Row(
        children: [
          SignedAvatar(dancer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dancer.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  dancer.styles.join(' · '),
                  style: const TextStyle(color: VimiColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class RelationsPage extends StatelessWidget {
  const RelationsPage({super.key, required this.id, required this.followers});
  final String id;
  final bool followers;
  @override
  Widget build(BuildContext context) => VPage(
    title: followers ? 'Followers' : 'Following',
    child: FutureBuilder<List<Dancer>>(
      future: VimiScope.of(context).repo!.relations(id, followers: followers),
      builder: (context, snapshot) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (snapshot.hasError)
            ErrorNote(readableError(snapshot.error!))
          else if (!snapshot.hasData)
            const Text('Opening dancers…')
          else if (snapshot.data!.isEmpty)
            const EmptyNote(
              'The circle starts small.',
              'Follow dancers whose work you want to keep up with.',
            )
          else
            ...snapshot.data!.map((p) => DancerRow(p)),
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
  int revision = -1;
  bool busy = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = VimiScope.of(context);
    if (revision != app.revision) {
      revision = app.revision;
      future = app.repo!.dancer(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = VimiScope.of(context);
    return VPage(
      title: 'Dance profile',

      child: FutureBuilder<Dancer?>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ErrorNote(
                readableError(snapshot.error!),
                onRetry: app.changed,
              ),
            );
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: Text('Opening dancer…'));
          final profile = snapshot.data;
          if (profile == null)
            return const Padding(
              padding: EdgeInsets.all(24),
              child: EmptyNote(
                'This profile is unavailable.',
                'You can return to the floor to discover other dancers.',
              ),
            );
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              SignedAvatar(profile, size: 96),
              const SizedBox(height: 20),
              Text(
                profile.name,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(profile.styles.join(' · ')),
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(profile.bio, style: Theme.of(context).textTheme.bodyLarge),
              ],
              const SizedBox(height: 16),
              Wrap(
                children: [
                  VButton(
                    '${profile.followers} followers',
                    quiet: true,
                    onPressed: () => openPage(
                      context,
                      RelationsPage(id: profile.id, followers: true),
                    ),
                  ),
                  VButton(
                    '${profile.following} following',
                    quiet: true,
                    onPressed: () => openPage(
                      context,
                      RelationsPage(id: profile.id, followers: false),
                    ),
                  ),
                ],
              ),
              if (profile.id != app.account) ...[
                const SizedBox(height: 16),
                VButton(
                  profile.isFollowing
                      ? 'Following · tap to unfollow'
                      : 'Follow dancer',

                  busy: busy,
                  onPressed: () async {
                    if (busy) return;
                    setState(() => busy = true);
                    try {
                      await app.repo!.follow(profile.id);
                      await app.refreshAccount();
                    } catch (e) {
                      if (context.mounted) feedback(context, readableError(e));
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
                ),
                const SizedBox(height: 8),
                VButton(
                  'Message',
                  glyph: Glyph.inbox,
                  onPressed: () => openPage(context, ChatPage(peer: profile)),
                ),
                Wrap(
                  children: [
                    VButton(
                      'Report dancer',
                      quiet: true,
                      onPressed: () =>
                          reportContent(context, 'user', profile.id),
                    ),
                    VButton(
                      'Block dancer',
                      quiet: true,
                      onPressed: () => blockDancer(context, profile),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'On their floor',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              PostCollection(
                key: ValueKey('${profile.id}-${app.revision}'),
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
  const EditProfilePage({super.key, required this.profile});
  final Dancer profile;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController name, bio;
  late Set<String> styles;
  File? photo;
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.profile.name);
    bio = TextEditingController(text: widget.profile.bio);
    styles = widget.profile.styles.toSet();
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
      if (file != null && mounted) setState(() => photo = File(file.path));
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    }
  }

  Future<void> save() async {
    if (busy) return;
    if (name.text.trim().length < 2 || styles.isEmpty) {
      setState(() => error = 'Add a name and at least one dance style.');
      return;
    }
    final app = VimiScope.of(context);
    setState(() => busy = true);
    try {
      final path = photo == null
          ? widget.profile.avatar
          : await app.repo!.upload(photo!, avatar: true, video: false);
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
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => VPage(
    title: 'Your dance identity',

    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (photo == null)
          SignedAvatar(widget.profile, size: 96)
        else
          ClipOval(
            child: Image.file(photo!, width: 96, height: 96, fit: BoxFit.cover),
          ),
        Wrap(
          children: [
            VButton(
              'Choose photo',
              glyph: Glyph.photo,
              quiet: true,
              onPressed: () => choose(ImageSource.gallery),
            ),
            VButton(
              'Take photo',
              glyph: Glyph.camera,
              quiet: true,
              onPressed: () => choose(ImageSource.camera),
            ),
          ],
        ),
        VField('Display name', controller: name, maxLength: 40),
        VField(
          'A little about your dancing',
          controller: bio,
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
                  onPressed: () => setState(() {
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
      title: 'Saved inspiration',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PostCollection(key: ValueKey('saved-${app.revision}'), saved: true),
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
    return VPage(
      title: 'Settings',

      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          VButton(
            'Blocked dancers',
            glyph: Glyph.block,
            quiet: true,
            onPressed: () => openPage(context, const BlockedDancersPage()),
          ),
          VButton(
            'Community guidelines',
            quiet: true,
            onPressed: () => openPage(
              context,
              const LegalPage('Community guidelines', 'community'),
            ),
          ),
          VButton(
            'Privacy Policy',
            quiet: true,
            onPressed: () =>
                openPage(context, const LegalPage('Privacy Policy', 'privacy')),
          ),
          VButton(
            'Terms of Use',
            quiet: true,
            onPressed: () =>
                openPage(context, const LegalPage('Terms of Use', 'terms')),
          ),
          if (support.isNotEmpty)
            VButton(
              'Contact support',
              quiet: true,
              onPressed: () async {
                final uri = Uri.tryParse(support);
                if (uri != null &&
                    uri.scheme == 'https' &&
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
          VButton(
            'Open-source licenses',
            quiet: true,
            onPressed: () => openPage(context, const VimiLicensesPage()),
          ),
          const SizedBox(height: 32),
          VButton(
            'Sign out',
            glyph: Glyph.logout,
            quiet: true,
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
          VButton(
            'Delete account',
            glyph: Glyph.delete,
            quiet: true,
            onPressed: () => openPage(context, const DeleteAccountPage()),
          ),
          const SizedBox(height: 24),
          const Text('Vimi · 1.0.0', style: TextStyle(color: VimiColors.muted)),
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
  @override
  Widget build(BuildContext context) => VPage(
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
              'Your list is clear.',
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
        ],
      ),
    ),
  );
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
    if (busy || password.text.isEmpty) return;
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
