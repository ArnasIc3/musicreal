import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/pages/post/post_widget.dart' show kEmotions;
import '/ui/app_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_model.dart';
export 'profile_model.dart';

class ProfileWidget extends StatefulWidget {
  const ProfileWidget({super.key});

  static String routeName = 'profile';
  static String routePath = '/profile';

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  late ProfileModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Color? color,
    Widget? trailing,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.0),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon,
                size: 20.0,
                color: color ?? FlutterFlowTheme.of(context).secondaryText),
            SizedBox(width: AppUi.gap),
            Expanded(
              child: Text(
                label,
                style: color == null
                    ? AppUi.body(context)
                    : AppUi.body(context).copyWith(color: color),
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.0,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
          ],
        ),
      ),
    );
  }

  /// Demo tracks, used when the Music collection is empty. The audio is
  /// SoundHelix's publicly hosted sample music, so playback needs a network
  /// connection.
  static const List<Map<String, String>> _demoSongs = [
    {
      'name': 'Morning Light',
      'author': 'SoundHelix',
      'genre': 'Chill',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
    },
    {
      'name': 'City Lines',
      'author': 'SoundHelix',
      'genre': 'Electronic',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3'
    },
    {
      'name': 'Slow Rivers',
      'author': 'SoundHelix',
      'genre': 'Ambient',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3'
    },
    {
      'name': 'Night Drive',
      'author': 'SoundHelix',
      'genre': 'Electronic',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3'
    },
    {
      'name': 'Paper Planes',
      'author': 'SoundHelix',
      'genre': 'Pop',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3'
    },
    {
      'name': 'Open Window',
      'author': 'SoundHelix',
      'genre': 'Chill',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3'
    },
    {
      'name': 'Long Way Home',
      'author': 'SoundHelix',
      'genre': 'Rock',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3'
    },
    {
      'name': 'Quiet Hours',
      'author': 'SoundHelix',
      'genre': 'Ambient',
      'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3'
    },
  ];

  /// Puts demo tracks into the shared Music catalogue when it is empty, so
  /// posts can reference songs that actually exist.
  Future<List<String>> _ensureSongs(BuildContext context) async {
    final existing = await queryMusicRecordOnce(limit: 10);
    final names = existing
        .map((m) => m.songName)
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isNotEmpty) return names;

    _showMessage(context, 'Music catalogue is empty, adding demo songs...');
    for (var i = 0; i < _demoSongs.length; i++) {
      final song = _demoSongs[i];
      await MusicRecord.collection.doc('demo_song_${i + 1}').set({
        ...createMusicRecordData(
          songName: song['name'],
          songURL: song['url'],
          author: song['author'],
        ),
        ...mapToFirestore({
          'Genres': [song['genre']],
        }),
        'demo_seed': true,
      });
    }
    return _demoSongs.map((song) => song['name']!).toList();
  }

  /// Writes 30 days of the signed-in user's own posts, so the statistics
  /// screen and the streak have something to show in a demo. Only the user's
  /// own data is touched, which the current Firestore rules already allow.
  Future<void> _fillDemoData(BuildContext context) async {
    final user = currentUserReference;
    if (user == null) return;

    final songs = await _ensureSongs(context);
    if (songs.isEmpty) {
      _showMessage(context, 'Could not prepare demo songs.');
      return;
    }

    if (!context.mounted) return;
    _showMessage(context, 'Adding demo posts...');
    final now = getCurrentTimestamp;
    var written = 0;
    for (var day = 0; day < 30; day++) {
      if (day % 4 == 3) continue; // gaps, so the chart is not flat
      await user.collection('userPost').doc('demo_history_$day').set({
        ...createUserPostRecordData(
          songName: songs[(day * 3) % songs.length],
          emoji: kEmotions[day % kEmotions.length],
          postUser: user,
          createdAt: now.subtract(Duration(days: day, hours: 1)),
        ),
        'demo_seed': true,
      });
      written++;
    }
    await user.update(createUsersRecordData(
      streakCount: 7,
      lastPostDate: now,
    ));

    if (!context.mounted) return;
    _showMessage(context, 'Demo data added: $written posts over 30 days.');
  }

  Future<void> _clearDemoData(BuildContext context) async {
    final user = currentUserReference;
    if (user == null) return;

    final posts = await user
        .collection('userPost')
        .where('demo_seed', isEqualTo: true)
        .get();
    for (final doc in posts.docs) {
      await doc.reference.delete();
    }

    if (!context.mounted) return;
    _showMessage(context, 'Demo data removed: ${posts.docs.length} posts.');
  }

  Widget _divider(BuildContext context) => Divider(
        height: 1.0,
        thickness: 1.0,
        color: AppUi.border(context),
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: StreamBuilder<List<UsersRecord>>(
        stream: queryUsersRecord(
          queryBuilder: (usersRecord) => usersRecord.where(
            'email',
            isEqualTo: currentUserEmail,
          ),
          singleRecord: true,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Scaffold(
              backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
              body: AppUi.loader(context),
            );
          }
          final profileUsersRecord = snapshot.data!.firstOrNull;

          return Scaffold(
            key: scaffoldKey,
            backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
            appBar: AppBar(
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              automaticallyImplyLeading: false,
              title: Text(
                'Profile',
                style: FlutterFlowTheme.of(context).headlineMedium.override(
                      font: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 22.0,
                      letterSpacing: 0.0,
                    ),
              ),
              actions: [],
              centerTitle: false,
              elevation: 0.0,
            ),
            body: SafeArea(
              top: true,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    AppUi.gutter, AppUi.gutter, AppUi.gutter, 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Identity
                    AppUi.card(
                      context,
                      padding: EdgeInsets.all(AppUi.gutter),
                      child: Column(
                        children: [
                          AppUi.avatar(context, profileUsersRecord?.photoUrl,
                              size: 88.0),
                          SizedBox(height: AppUi.gap),
                          Text(
                            valueOrDefault<String>(
                              profileUsersRecord?.displayName,
                              'No name',
                            ),
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .override(
                                  font: GoogleFonts.urbanist(
                                      fontWeight: FontWeight.w600),
                                  letterSpacing: 0.0,
                                ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            valueOrDefault<String>(
                              profileUsersRecord?.email,
                              '',
                            ),
                            textAlign: TextAlign.center,
                            style: AppUi.muted(context),
                          ),
                          SizedBox(height: AppUi.gutter),
                          AuthUserStreamWidget(
                            builder: (context) => Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 10.0),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                borderRadius: BorderRadius.circular(20.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('🔥', style: TextStyle(fontSize: 16.0)),
                                  SizedBox(width: 8.0),
                                  Text(
                                    '${valueOrDefault(currentUserDocument?.streakCount, 0)} day streak',
                                    style: AppUi.title(context, size: 15.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    AppUi.sectionTitle(context, 'Account'),
                    AppUi.card(
                      context,
                      padding: EdgeInsets.symmetric(horizontal: AppUi.gap),
                      child: Column(
                        children: [
                          _row(
                            context,
                            icon: Icons.bar_chart_rounded,
                            label: 'Statistics',
                            onTap: () =>
                                context.pushNamed(StatisticsWidget.routeName),
                          ),
                          _divider(context),
                          _row(
                            context,
                            icon: Icons.group_outlined,
                            label: 'Friends',
                            onTap: () =>
                                context.pushNamed(FriendsListWidget.routeName),
                          ),
                          _divider(context),
                          _row(
                            context,
                            icon: isDark
                                ? Icons.wb_sunny_rounded
                                : Icons.nights_stay,
                            label: isDark
                                ? 'Switch to light mode'
                                : 'Switch to dark mode',
                            onTap: () => setDarkModeSetting(context,
                                isDark ? ThemeMode.light : ThemeMode.dark),
                            trailing: SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    AppUi.sectionTitle(context, 'Demo data'),
                    AppUi.card(
                      context,
                      padding: EdgeInsets.all(AppUi.gutter),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adds demo songs to the catalogue if it is empty, then fills your own account with 30 days of posts, so statistics and the streak can be demonstrated. It does not create friends or their posts.',
                            style: AppUi.muted(context),
                          ),
                          SizedBox(height: AppUi.gap),
                          Row(
                            children: [
                              Expanded(
                                child: FFButtonWidget(
                                  onPressed: () => _fillDemoData(context),
                                  text: 'Fill demo data',
                                  options: AppUi.primaryButton(context),
                                ),
                              ),
                              SizedBox(width: AppUi.gap),
                              Expanded(
                                child: FFButtonWidget(
                                  onPressed: () => _clearDemoData(context),
                                  text: 'Remove',
                                  options: AppUi.quietButton(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    AppUi.sectionTitle(context, 'Session'),
                    SizedBox(
                      width: double.infinity,
                      child: FFButtonWidget(
                        onPressed: () async {
                          GoRouter.of(context).prepareAuthEvent();
                          await authManager.signOut();
                          GoRouter.of(context).clearRedirectLocation();

                          context.goNamedAuth(
                              LogInPageWidget.routeName, context.mounted);
                        },
                        text: 'Log out',
                        options: AppUi.quietButton(context),
                      ),
                    ),
                    SizedBox(height: AppUi.gap),
                    SizedBox(
                      width: double.infinity,
                      child: FFButtonWidget(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text('Delete your account?'),
                              content: Text(
                                  'Your profile, posts and friend links are removed permanently. This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                        color:
                                            FlutterFlowTheme.of(context).error),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) {
                            return;
                          }

                          // The onUserDeleted Cloud Function removes the
                          // profile, posts and friend links.
                          await authManager.deleteUser(context);
                          if (FirebaseAuth.instance.currentUser != null) {
                            return;
                          }

                          context.goNamed(LogInPageWidget.routeName);
                        },
                        text: 'Delete account',
                        options: AppUi.quietButton(
                          context,
                          textColor: FlutterFlowTheme.of(context).error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
      ),
      duration: Duration(milliseconds: 4000),
      backgroundColor: FlutterFlowTheme.of(context).secondary,
    ),
  );
}
