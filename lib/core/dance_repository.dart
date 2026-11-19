import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'pagination.dart';

class DanceRepository {
  DanceRepository(this.client);
  final SupabaseClient client;
  final _signed = <String, ({String url, DateTime until})>{};
  String get account => client.auth.currentUser!.id;
  Future<Dancer?> dancer(String id) async {
    final data = await client.rpc('get_dancer', params: {'p_id': id});
    return data == null ? null : Dancer.fromJson(jsonMap(data));
  }

  Future<List<DancePost>> feed({
    String? style,
    String? author,
    bool saved = false,
    int offset = 0,
    String? challenge,
  }) async => jsonRows(
    await client.rpc(
      'get_feed',
      params: {
        'p_style': style,
        'p_author': author,
        'p_saved': saved,
        'p_offset': offset,
        'p_challenge': challenge,
      },
    ),
  ).map(DancePost.fromJson).toList();
  Future<DancePost?> post(String id) async {
    final data = await client.rpc('get_post', params: {'p_id': id});
    return data == null ? null : DancePost.fromJson(jsonMap(data));
  }

  Future<List<Dancer>> searchDancers(String query) async {
    final safe = query.replaceAll(RegExp(r'[%_\\]'), '').trim();
    var request = client.from('profiles').select();
    if (safe.isNotEmpty) request = request.ilike('display_name', '%$safe%');
    return jsonRows(
      await request.order('created_at', ascending: false).limit(30),
    ).map(Dancer.fromJson).toList();
  }

  Future<List<Dancer>> relations(String id, {required bool followers}) async {
    final rows = jsonRows(
      await client
          .from('follows')
          .select()
          .eq(followers ? 'following_id' : 'follower_id', id)
          .limit(100),
    );
    final ids = rows
        .map((r) => r[followers ? 'follower_id' : 'following_id'] as String)
        .toList();
    if (ids.isEmpty) return [];
    return jsonRows(
      await client.from('profiles').select().inFilter('id', ids),
    ).map(Dancer.fromJson).toList();
  }

  Future<String> mediaUrl(String path) async {
    final cached = _signed[path];
    if (cached != null && cached.until.isAfter(DateTime.now()))
      return cached.url;
    final url = await client.storage
        .from('dance-media')
        .createSignedUrl(path, 300);
    _signed[path] = (
      url: url,
      until: DateTime.now().add(const Duration(minutes: 4)),
    );
    return url;
  }

  void clearMediaCache() => _signed.clear();
  Future<String> upload(
    File file, {
    required bool avatar,
    required bool video,
    String? mediaId,
  }) async {
    if (await file.length() > 50 * 1024 * 1024)
      throw const FileSystemException('Choose a file smaller than 50 MB.');
    final original = file.path.toLowerCase();
    final extension = video
        ? (original.endsWith('.mov') ? 'mov' : 'mp4')
        : (original.endsWith('.png')
              ? 'png'
              : original.endsWith('.webp')
              ? 'webp'
              : 'jpg');
    final mime = video
        ? (extension == 'mov' ? 'video/quicktime' : 'video/mp4')
        : (extension == 'jpg' ? 'image/jpeg' : 'image/$extension');
    final path =
        '$account/${avatar ? 'avatar' : 'posts'}/${mediaId ?? const Uuid().v4()}.$extension';
    try {
      await client.storage
          .from('dance-media')
          .upload(
            path,
            file,
            fileOptions: FileOptions(contentType: mime, upsert: false),
          );
    } on StorageException catch (e) {
      if (mediaId == null || (e.statusCode != '409' && e.error != 'Duplicate'))
        rethrow;
      // An upload may finish before its response is lost. Retry the same owned
      // draft object only after checking that its metadata matches the file.
      final existing = await client.storage.from('dance-media').info(path);
      if (existing.size != await file.length() || existing.contentType != mime)
        rethrow;
    }
    return path;
  }

  Future<void> removeMedia(String path) async {
    await client.storage.from('dance-media').remove([path]);
    _signed.remove(path);
  }

  Future<void> updateProfile(
    String name,
    String bio,
    List<String> styles,
    String? avatar,
  ) async => client.rpc(
    'update_dancer',
    params: {
      'p_name': name,
      'p_bio': bio,
      'p_styles': styles,
      'p_avatar': avatar,
    },
  );
  Future<void> follow(String peer, {required bool followed}) async => client
      .rpc('set_follow', params: {'p_peer': peer, 'p_followed': followed});
  Future<void> block(String peer, bool blocked) async {
    await client.rpc(
      'set_block',
      params: {'p_peer': peer, 'p_blocked': blocked},
    );
    clearMediaCache();
  }

  Future<List<Dancer>> blocked() async =>
      jsonRows(await client.rpc('get_blocked')).map(Dancer.fromJson).toList();
  Future<void> postAction(
    String id,
    String action, {
    required bool selected,
  }) async => client.rpc(
    'set_post_action',
    params: {'p_post': id, 'p_action': action, 'p_selected': selected},
  );
  Future<String> publish({
    required String caption,
    required String style,
    required String path,
    required bool video,
    required String clientId,
    String? challenge,
  }) async =>
      await client.rpc(
            'submit_post',
            params: {
              'p_caption': caption,
              'p_style': style,
              'p_media_path': path,
              'p_kind': video ? 'video' : 'image',
              'p_client_id': clientId,
              'p_challenge': challenge,
            },
          )
          as String;
  Future<void> deletePost(DancePost post) async {
    await client
        .from('posts')
        .delete()
        .eq('id', post.id)
        .eq('author_id', account);
    // Removing the row immediately revokes other members' Storage authorization.
    await removeMedia(post.mediaPath);
  }

  Future<List<Json>> comments(String id) async => jsonRows(
    await client
        .from('comments')
        .select('*,author:profiles!author_id(*)')
        .eq('post_id', id)
        .order('created_at')
        .limit(100),
  );
  Future<void> comment(String post, String body, String clientId) async =>
      client.rpc(
        'submit_comment',
        params: {'p_post': post, 'p_body': body, 'p_client_id': clientId},
      );
  Future<void> deleteComment(String id) async =>
      client.from('comments').delete().eq('id', id).eq('author_id', account);
  Future<void> report(String type, String id, String reason) async {
    await client.rpc(
      'report_content',
      params: {'p_type': type, 'p_target': id, 'p_reason': reason},
    );
    clearMediaCache();
  }

  Future<List<Json>> inbox() async => jsonRows(await client.rpc('get_inbox'));
  Future<List<Json>> reports() async => jsonRows(
    await client
        .from('reports')
        .select('id,target_type,target_id,reason,status,created_at')
        .eq('reporter_id', account)
        .order('created_at', ascending: false)
        .limit(100),
  );
  Future<List<Json>> thread(String peer) async => jsonRows(
    await client
        .from('messages')
        .select()
        .or(
          'and(sender_id.eq.$account,recipient_id.eq.$peer),and(sender_id.eq.$peer,recipient_id.eq.$account)',
        )
        .order('created_at', ascending: false)
        .limit(100),
  ).reversed.toList();
  Future<bool> canMessage(String peer) async =>
      await client.rpc('can_message', params: {'p_peer': peer}) == true;
  Future<void> send(String peer, String body, String clientId) async =>
      client.rpc(
        'send_message',
        params: {'p_peer': peer, 'p_body': body, 'p_client_id': clientId},
      );
  Future<void> markRead(String peer) async =>
      client.rpc('mark_read', params: {'p_peer': peer});
  Future<int> reversalDebt() async {
    final row = await client
        .from('wallets')
        .select('reversal_debt')
        .eq('user_id', account)
        .single();
    return (row['reversal_debt'] as num).toInt();
  }

  Future<int> balance() async {
    final row = await client
        .from('wallets')
        .select('balance')
        .eq('user_id', account)
        .single();
    return (row['balance'] as num).toInt();
  }

  Future<List<Json>> ledger() async => jsonRows(
    await client
        .from('wallet_ledger')
        .select()
        .eq('user_id', account)
        .order('created_at', ascending: false)
        .limit(100),
  );
  Future<Set<String>> unlocks() async => jsonRows(
    await client.from('pack_unlocks').select('pack_id').eq('user_id', account),
  ).map((r) => r['pack_id'] as String).toSet();

  Future<CursorPage<DancePost>> feedPage({
    String? style,
    String? author,
    bool saved = false,
    String? challenge,
    TimelineCursor? cursor,
  }) async => CursorPage.rows(
    jsonRows(
      await client.rpc(
        'get_feed_page',
        params: {
          'p_style': style,
          'p_author': author,
          'p_saved': saved,
          'p_challenge': challenge,
          ...?cursor?.beforeParameters,
        },
      ),
    ),
    DancePost.fromJson,
    size: 20,
  );

  Future<CursorPage<Dancer>> dancerPage(
    String query, {
    TimelineCursor? cursor,
  }) async {
    final safe = query.replaceAll(RegExp(r'[%_\\]'), '').trim();
    var request = client.from('profiles').select().neq('id', account);
    if (safe.isNotEmpty) request = request.ilike('display_name', '%$safe%');
    if (cursor != null) request = request.or(cursor.filter());
    return CursorPage.rows(
      jsonRows(
        await request
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(26),
      ),
      Dancer.fromJson,
    );
  }

  Future<CursorPage<Dancer>> relationPage(
    String id, {
    required bool followers,
    TimelineCursor? cursor,
  }) async {
    final field = followers ? 'follower_id' : 'following_id';
    final foreignKey = 'follows_${field}_fkey';
    var request = client
        .from('follows')
        .select('created_at,$field,peer:profiles!$foreignKey!inner(*)')
        .eq(followers ? 'following_id' : 'follower_id', id);
    if (cursor != null) request = request.or(cursor.filter(idField: field));
    return CursorPage.rows(
      jsonRows(
        await request
            .order('created_at', ascending: false)
            .order(field, ascending: false)
            .limit(26),
      ),
      (row) => Dancer.fromJson(jsonMap(row['peer'])),
      idField: field,
    );
  }

  Future<CursorPage<Json>> commentPage(
    String post, {
    TimelineCursor? cursor,
  }) async {
    var request = client
        .from('comments')
        .select('*,author:profiles!author_id(*)')
        .eq('post_id', post);
    if (cursor != null) request = request.or(cursor.filter());
    return CursorPage.rows(
      jsonRows(
        await request
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(26),
      ),
      (row) => row,
    );
  }

  Future<CursorPage<Json>> reportPage({TimelineCursor? cursor}) async {
    var request = client
        .from('reports')
        .select('id,target_type,target_id,reason,status,created_at')
        .eq('reporter_id', account);
    if (cursor != null) request = request.or(cursor.filter());
    return CursorPage.rows(
      jsonRows(
        await request
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(26),
      ),
      (row) => row,
    );
  }

  Future<CursorPage<Json>> ledgerPage({TimelineCursor? cursor}) async {
    var request = client.from('wallet_ledger').select().eq('user_id', account);
    if (cursor != null) request = request.or(cursor.filter());
    return CursorPage.rows(
      jsonRows(
        await request
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(26),
      ),
      (row) => row,
    );
  }

  Future<CursorPage<Json>> inboxPage({TimelineCursor? cursor}) async =>
      CursorPage.rows(
        jsonRows(
          await client.rpc(
            'get_inbox_page',
            params: {...?cursor?.beforeParameters},
          ),
        ),
        (row) => row,
      );

  Future<CursorPage<Json>> threadPage(
    String peer, {
    TimelineCursor? cursor,
  }) async => CursorPage.rows(
    jsonRows(
      await client.rpc(
        'get_thread_page',
        params: {'p_peer': peer, ...?cursor?.beforeParameters},
      ),
    ),
    (row) => row,
    size: 50,
  );

  Future<CursorPage<Json>> reviewPage(
    String section, {
    TimelineCursor? cursor,
    bool childSafetyOnly = false,
  }) async {
    final response = await client.functions.invoke(
      'moderate-content',
      body: {
        'action': 'queue',
        'section': section,
        'child_safety_only': childSafetyOnly,
        if (cursor != null)
          'after_created': cursor.createdAt.toUtc().toIso8601String(),
        if (cursor != null) 'after_id': cursor.id,
      },
    );
    return CursorPage.rows(
      jsonRows(jsonMap(response.data)['items']),
      (row) => row,
    );
  }

  Future<void> unlock(String pack) async =>
      client.rpc('unlock_studio_pack', params: {'p_pack': pack});
}

String readableError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) {
    if (error.code == 'P0001') return error.message;
    if (error.code == '23514') return 'Check your entries and try again.';
    return 'This action could not be saved. Please try again.';
  }
  if (error is FileSystemException) return error.message;
  if (error is SocketException)
    return 'You are offline. Reconnect and try again.';
  if (error is StorageException)
    return 'Your media could not be loaded or saved. Please try again.';
  if (error is FunctionException)
    return 'This action is unavailable right now. Please try again.';
  return 'Something interrupted this action. Please try again.';
}
