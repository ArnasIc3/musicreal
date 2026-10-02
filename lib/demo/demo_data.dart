
import '/backend/backend.dart';

/// Demo mode runs the app on fixed in-memory data with no Firebase reads or
/// writes, so every screen can be shown and screenshotted without signing in.
///
/// Build it with:
///   flutter build web --dart-define=DEMO=true
const bool kDemoMode = bool.fromEnvironment('DEMO');

const List<String> _emotions = [
  'https://static.vecteezy.com/system/resources/thumbnails/059/420/483/small/cool-smiley-face-with-sunglasses-giving-thumbs-up-png.png',
  'https://static.vecteezy.com/system/resources/thumbnails/059/420/444/small/laughing-emoji-with-joyful-expression-and-tears-png.png',
  'https://png.pngtree.com/png-vector/20241102/ourmid/pngtree-crying-sad-emoji-png-image_14216691.png',
];

class DemoData {
  static DocumentReference _doc(String path) =>
      FirebaseFirestore.instance.doc(path);

  static String _avatar(String name) =>
      'https://api.dicebear.com/7.x/initials/png?seed=${Uri.encodeComponent(name)}';

  static DateTime get _now => DateTime.now();

  // ---------------------------------------------------------------- people

  static final DocumentReference meRef = _doc('users/demo_me');
  static final DocumentReference aisteRef = _doc('users/demo_aiste');
  static final DocumentReference tomasRef = _doc('users/demo_tomas');
  static final DocumentReference gabijaRef = _doc('users/demo_gabija');
  static final DocumentReference lukasRef = _doc('users/demo_lukas');

  static UsersRecord _user(
    DocumentReference ref,
    String name,
    String email, {
    int streak = 0,
    List<DocumentReference> friends = const [],
  }) =>
      UsersRecord.getDocumentFromData({
        'uid': ref.id,
        'email': email,
        'display_name': name,
        'photo_url': _avatar(name),
        'created_time': _now.subtract(Duration(days: 120)),
        'streak_count': streak,
        'last_post_date': _now.subtract(Duration(hours: 3)),
        'friends': friends,
      }, ref);

  static UsersRecord get me => _user(
        meRef,
        'Rokas (demo)',
        'demo@musicreal.app',
        streak: 7,
        friends: [aisteRef, tomasRef, gabijaRef],
      );

  static List<UsersRecord> get friends => [
        _user(aisteRef, 'Aistė Demo', 'aiste@demo.invalid',
            streak: 12, friends: [meRef]),
        _user(tomasRef, 'Tomas Demo', 'tomas@demo.invalid',
            streak: 4, friends: [meRef]),
        _user(gabijaRef, 'Gabija Demo', 'gabija@demo.invalid',
            streak: 9, friends: [meRef]),
      ];

  /// Everyone the search screen can find: friends plus one stranger.
  static List<UsersRecord> get allUsers => [
        ...friends,
        _user(lukasRef, 'Lukas Demo', 'lukas@demo.invalid', streak: 2),
      ];

  static UsersRecord userFor(DocumentReference ref) =>
      [me, ...allUsers].firstWhere(
        (user) => user.reference.id == ref.id,
        orElse: () => _user(ref, 'Demo user', 'demo@demo.invalid'),
      );

  // ----------------------------------------------------------------- music

  static const List<List<String>> _songs = [
    ['Morning Light', 'SoundHelix', 'Chill', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'],
    ['City Lines', 'SoundHelix', 'Electronic', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'],
    ['Slow Rivers', 'SoundHelix', 'Ambient', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'],
    ['Night Drive', 'SoundHelix', 'Electronic', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3'],
    ['Paper Planes', 'SoundHelix', 'Pop', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3'],
    ['Open Window', 'SoundHelix', 'Chill', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3'],
    ['Long Way Home', 'SoundHelix', 'Rock', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3'],
    ['Quiet Hours', 'SoundHelix', 'Ambient', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3'],
  ];

  static List<MusicRecord> get music => _songs
      .asMap()
      .entries
      .map((entry) => MusicRecord.getDocumentFromData({
            'SongName': entry.value[0],
            'Author': entry.value[1],
            'Genres': [entry.value[2]],
            'SongURL': entry.value[3],
          }, _doc('Music/demo_song_${entry.key + 1}')))
      .toList();

  static MusicRecord? musicNamed(String songName) {
    for (final record in music) {
      if (record.songName == songName) return record;
    }
    return null;
  }

  // ----------------------------------------------------------------- posts

  static UserPostRecord _post(
    DocumentReference author,
    String id,
    String song,
    int emotion,
    DateTime when,
  ) =>
      UserPostRecord.getDocumentFromData({
        'song_name': song,
        'emoji': _emotions[emotion % _emotions.length],
        'post_user': author,
        'created_at': when,
      }, author.collection('userPost').doc(id));

  /// What the friends posted today — the home feed.
  static List<UserPostRecord> get todaysFeed {
    final now = _now;
    return [
      _post(aisteRef, 'p1', 'Morning Light', 0,
          now.subtract(Duration(minutes: 25))),
      _post(tomasRef, 'p2', 'Night Drive', 1,
          now.subtract(Duration(hours: 2, minutes: 10))),
      _post(gabijaRef, 'p3', 'Paper Planes', 2,
          now.subtract(Duration(hours: 4, minutes: 35))),
      _post(aisteRef, 'p4', 'Quiet Hours', 1,
          now.subtract(Duration(hours: 6, minutes: 50))),
    ];
  }

  /// 30 days of the demo account's own posts — the statistics screen.
  static List<UserPostRecord> get myLastMonth {
    final posts = <UserPostRecord>[];
    for (var day = 0; day < 30; day++) {
      if (day % 4 == 3) continue; // gaps, so the chart is not flat
      final song = _songs[(day * 3) % _songs.length][0];
      posts.add(_post(
        meRef,
        'h$day',
        song,
        day % 3,
        _now.subtract(Duration(days: day, hours: 2)),
      ));
    }
    return posts;
  }

  // -------------------------------------------------------------- requests

  static List<FriendRequestsRecord> get pendingRequests => [
        FriendRequestsRecord.getDocumentFromData({
          'sender': lukasRef,
          'receiver': meRef,
          'status': 'pending',
          'created_at': _now.subtract(Duration(hours: 5)),
        }, _doc('friend_requests/demo_request_1')),
      ];
}
