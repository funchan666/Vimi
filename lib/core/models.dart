typedef Json = Map<String, dynamic>;

enum DanceStyle {
  kpop('K-pop'),
  girlGroup('Girl group'),
  boyGroup('Boy group'),
  freestyle('Freestyle');

  const DanceStyle(this.label);
  final String label;
}

Json jsonMap(dynamic value) => Map<String, dynamic>.from(value as Map);
List<Json> jsonRows(dynamic value) => (value as List).map(jsonMap).toList();

class Dancer {
  const Dancer({
    required this.id,
    required this.name,
    this.bio = '',
    this.styles = const [],
    this.avatar,
    this.followers = 0,
    this.following = 0,
    this.isFollowing = false,
    this.followsYou = false,
  });
  final String id, name, bio;
  final List<String> styles;
  final String? avatar;
  final int followers, following;
  final bool isFollowing, followsYou;
  factory Dancer.fromJson(Json j) => Dancer(
    id: j['id'] as String,
    name: j['display_name'] as String? ?? 'Dancer',
    bio: j['bio'] as String? ?? '',
    styles: List<String>.from(j['styles'] as List? ?? []),
    avatar: j['avatar_path'] as String?,
    followers: (j['followers_count'] as num?)?.toInt() ?? 0,
    following: (j['following_count'] as num?)?.toInt() ?? 0,
    isFollowing: j['is_following'] == true,
    followsYou: j['follows_you'] == true,
  );
}

class DancePost {
  const DancePost({
    required this.id,
    required this.author,
    required this.caption,
    required this.style,
    required this.mediaPath,
    required this.kind,
    required this.createdAt,
    this.challengeId,
    this.status = 'approved',
    this.likes = 0,
    this.comments = 0,
    this.liked = false,
    this.saved = false,
  });
  final String id, caption, style, mediaPath, kind, status;
  final String? challengeId;
  final Dancer author;
  final DateTime createdAt;
  final int likes, comments;
  final bool liked, saved;
  factory DancePost.fromJson(Json j) => DancePost(
    id: j['id'] as String,
    author: Dancer.fromJson(jsonMap(j['author'])),
    caption: j['caption'] as String,
    style: j['style'] as String,
    mediaPath: j['media_path'] as String,
    kind: j['media_kind'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    challengeId: j['challenge_id'] as String?,
    status: j['status'] as String? ?? 'approved',
    likes: (j['likes_count'] as num?)?.toInt() ?? 0,
    comments: (j['comments_count'] as num?)?.toInt() ?? 0,
    liked: j['liked'] == true,
    saved: j['saved'] == true,
  );
}

class LibraryClipEngagement {
  const LibraryClipEngagement({
    required this.likes,
    required this.comments,
    required this.liked,
    this.author,
  });

  final int likes, comments;
  final bool liked;
  final Dancer? author;

  factory LibraryClipEngagement.fromJson(Json row) => LibraryClipEngagement(
    likes: (row['likes_count'] as num).toInt(),
    comments: (row['comments_count'] as num).toInt(),
    liked: row['liked'] == true,
    author: row['author'] == null
        ? null
        : Dancer.fromJson(jsonMap(row['author'])),
  );
}

class ChoreographyPrompt {
  const ChoreographyPrompt({
    required this.id,
    required this.title,
    required this.style,
    required this.counts,
    required this.description,
    required this.prompts,
  });
  final String id, title, style, description;
  final int counts;
  final List<String> prompts;
  factory ChoreographyPrompt.fromJson(Json j) => ChoreographyPrompt(
    id: j['id'] as String,
    title: j['title'] as String,
    style: j['style'] as String,
    counts: (j['counts'] as num).toInt(),
    description: j['description'] as String,
    prompts: List<String>.from(j['prompts'] as List),
  );
}

class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.routine,
    required this.style,
    required this.minutes,
    required this.counts,
    required this.bpm,
    required this.notes,
    required this.createdAt,
    this.videoPath,
    this.packId,
  });
  final String id, routine, style, notes;
  final int minutes, counts, bpm;
  final DateTime createdAt;
  final String? videoPath, packId;
  factory PracticeSession.fromJson(Json j) => PracticeSession(
    id: j['id'] as String,
    routine: j['routine'] as String,
    style: j['style'] as String,
    minutes: (j['minutes'] as num).toInt(),
    counts: (j['counts'] as num).toInt(),
    bpm: (j['bpm'] as num).toInt(),
    notes: j['notes'] as String,
    createdAt: DateTime.parse(j['created_at'] as String),
    videoPath: j['video_path'] as String?,
    packId: j['pack_id'] as String?,
  );
  Json toJson() => {
    'id': id,
    'routine': routine,
    'style': style,
    'minutes': minutes,
    'counts': counts,
    'bpm': bpm,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'video_path': videoPath,
    'pack_id': packId,
  };
}

class StudioPack {
  const StudioPack(
    this.id,
    this.title,
    this.cost,
    this.description,
    this.drills,
  );
  final String id, title, description;
  final int cost;
  final List<String> drills;
  static const all = [
    StudioPack(
      'chorus-builder',
      'Chorus Builder',
      120,
      'A repeatable four-phrase practice plan.',
      [
        'Mark the ending of each eight-count phrase.',
        'Practice phrase 1 to 2 at half your usual tempo.',
        'Link phrases 2 to 3 without stopping.',
        'Film all four phrases and note one transition to revisit.',
      ],
    ),
    StudioPack(
      'formation-notes',
      'Formation Notes',
      180,
      'Plan spacing, facing and transitions for a group cover.',
      [
        'Write one floor-position cue for every dancer.',
        'Mark front, left and right for each phrase.',
        'Walk every position change before adding movement.',
        'Record a wide take and write one spacing correction.',
      ],
    ),
    StudioPack(
      'comeback-planner',
      'Comeback Planner',
      240,
      'A seven-session cover preparation journal.',
      [
        'Session 1: choose a rights-cleared routine and mark its sections.',
        'Sessions 2–3: practice separate phrases and record tempo.',
        'Sessions 4–5: join transitions, then add performance details.',
        'Session 6: rehearse clothing, space and framing.',
        'Session 7: warm up, record one take, reflect and share.',
      ],
    ),
  ];
}
