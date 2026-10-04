import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_audio_player.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/demo/demo_data.dart';
import '/index.dart';
import '/ui/app_ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_model.dart';
export 'home_model.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  static String routeName = 'Home';
  static String routePath = '/home';

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  late HomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.userData = await queryUsersRecordOnce(
        queryBuilder: (usersRecord) => usersRecord.where(
          'uid',
          isEqualTo: currentUserUid,
        ),
        singleRecord: true,
      ).then((s) => s.firstOrNull);
      final today = functions.startOfDay(getCurrentTimestamp);
      final lastPostDate = _model.userData?.lastPostDate;
      // No post yesterday or today means the streak is over.
      final streakBroken = lastPostDate != null &&
          lastPostDate
              .isBefore(DateTime(today.year, today.month, today.day - 1));
      if (streakBroken) {
        await _model.userData!.reference.update(createUsersRecordData(
          streakCount: 0,
        ));
      }
      if (!streakBroken &&
          lastPostDate != null &&
          (_model.userData?.streakCount ?? 0) > 0) {
        if (lastPostDate.isBefore(today) &&
            getCurrentTimestamp
                .isAfter(functions.newCustomFunction(getCurrentTimestamp))) {
          _notify(context, 'You haven\'t posted yet! Only 2 hours left!');
        }
      } else {
        _notify(
            context, 'You haven\'t posted yet! Don\'t forget to post today!');
      }
    });
  }

  void _notify(BuildContext context, String message) {
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

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Widget _streakPill(BuildContext context) {
    return AuthUserStreamWidget(
      builder: (context) => Container(
        margin: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, AppUi.gutter, 0.0),
        padding: EdgeInsetsDirectional.fromSTEB(10.0, 6.0, 12.0, 6.0),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 16.0,
              color: FlutterFlowTheme.of(context).error,
            ),
            SizedBox(width: 6.0),
            Text(
              kDemoMode
                  ? '${DemoData.me.streakCount}'
                  : valueOrDefault(currentUserDocument?.streakCount, 0)
                      .toString(),
              style: AppUi.title(context, size: 14.0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'MusicReal',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                ),
          ),
          actions: [
            _streakPill(context),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            context.pushNamed(PostWidget.routeName);
          },
          backgroundColor: FlutterFlowTheme.of(context).primary,
          foregroundColor: Colors.white,
          elevation: 2.0,
          icon: Icon(Icons.add_rounded),
          label: Text(
            'Post',
            style: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  color: Colors.white,
                  letterSpacing: 0.0,
                ),
          ),
        ),
        body: SafeArea(
          top: true,
          child: AuthUserStreamWidget(
            builder: (context) => SingleChildScrollView(
              child: FriendFeed(),
            ),
          ),
        ),
      ),
    );
  }
}

/// SCRUM-49: the feed carries today's posts from confirmed friends only,
/// newest first.
Query friendsFeedQuery(
  Query userPostRecord,
  List<DocumentReference> friends,
  DateTime now,
) =>
    userPostRecord
        .whereIn('post_user', friends)
        .where('created_at', isGreaterThanOrEqualTo: functions.startOfDay(now))
        .orderBy('created_at', descending: true);

/// Where the friend feed reads its data from: Firestore, or the fixed demo
/// data. Widget tests pass their own.
class FeedSource {
  const FeedSource();

  List<DocumentReference> friends() => kDemoMode
      ? DemoData.me.friends.toList()
      : (currentUserDocument?.friends.toList() ?? []);

  Stream<List<UserPostRecord>> todaysPosts(List<DocumentReference> friends) =>
      kDemoMode
          ? Stream.value(DemoData.todaysFeed)
          : queryUserPostRecord(
              queryBuilder: (userPostRecord) => friendsFeedQuery(
                  userPostRecord, friends, getCurrentTimestamp),
            );

  Stream<UsersRecord> author(DocumentReference user) => kDemoMode
      ? Stream.value(DemoData.userFor(user))
      : UsersRecord.getDocument(user);

  Stream<List<MusicRecord>> music(String songName) {
    final demoMusic = DemoData.musicNamed(songName);
    return kDemoMode
        ? Stream.value([if (demoMusic != null) demoMusic])
        : queryMusicRecord(
            queryBuilder: (musicRecord) =>
                musicRecord.where('SongName', isEqualTo: songName),
            singleRecord: true,
          );
  }
}

/// The friends' posts of today, or an empty-feed message.
class FriendFeed extends StatelessWidget {
  const FriendFeed({super.key, this.source = const FeedSource()});

  final FeedSource source;

  /// The track behind a post, when the song exists in the catalogue.
  Widget _player(BuildContext context, String songName) {
    return StreamBuilder<List<MusicRecord>>(
      stream: source.music(songName),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
              height: 48.0, child: AppUi.loader(context, size: 24.0));
        }
        final music = snapshot.data!.firstOrNull;
        // The song may not be in the catalogue any more.
        if (music == null || music.songURL.isEmpty) {
          return SizedBox.shrink();
        }
        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, AppUi.gap, 0.0, 0.0),
          child: FlutterFlowAudioPlayer(
            audio: Audio.network(music.songURL, metas: Metas()),
            titleTextStyle: FlutterFlowTheme.of(context).titleLarge.override(
                  font: GoogleFonts.urbanist(),
                  color: Color(0x00FFFFFF),
                  letterSpacing: 0.0,
                ),
            playbackDurationTextStyle:
                FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.inter(),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 12.0,
                      letterSpacing: 0.0,
                    ),
            fillColor: FlutterFlowTheme.of(context).primaryBackground,
            playbackButtonColor: FlutterFlowTheme.of(context).primary,
            activeTrackColor: FlutterFlowTheme.of(context).primary,
            inactiveTrackColor: FlutterFlowTheme.of(context).alternate,
            elevation: 0.0,
            playInBackground: PlayInBackground.disabledRestoreOnForeground,
          ),
        );
      },
    );
  }

  Widget _postCard(BuildContext context, UserPostRecord post) {
    return StreamBuilder<UsersRecord>(
      stream: source.author(post.postUser!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
                AppUi.gutter, 0.0, AppUi.gutter, AppUi.gap),
            child: SizedBox(height: 92.0, child: AppUi.loader(context)),
          );
        }
        final author = snapshot.data!;

        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
              AppUi.gutter, 0.0, AppUi.gutter, AppUi.gap),
          child: AppUi.card(
            context,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AppUi.avatar(context, author.photoUrl, size: 44.0),
                    SizedBox(width: AppUi.gap),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: AppUi.title(context),
                          ),
                          SizedBox(height: 2.0),
                          Text(
                            post.songName,
                            overflow: TextOverflow.ellipsis,
                            style: AppUi.body(context),
                          ),
                          if (post.createdAt != null) ...[
                            SizedBox(height: 2.0),
                            Text(
                              dateTimeFormat('relative', post.createdAt),
                              style: AppUi.muted(context),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: AppUi.gap),
                    AppUi.squareImage(
                      context,
                      post.emoji,
                      size: 52.0,
                      fallback: Icons.emoji_emotions_outlined,
                    ),
                  ],
                ),
                _player(context, post.songName),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final friends = source.friends();

    if (friends.isEmpty) {
      return AppUi.emptyState(
        context,
        icon: Icons.group_add_outlined,
        title: 'Your feed is empty',
        message: 'Add friends to see the songs and emotions they post.',
        action: FFButtonWidget(
          onPressed: () async {
            context.pushNamed(FriendsListAddFriendWidget.routeName);
          },
          text: 'Find friends',
          options: AppUi.primaryButton(context),
        ),
      );
    }

    return StreamBuilder<List<UserPostRecord>>(
      stream: source.todaysPosts(friends),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: EdgeInsets.only(top: 48.0),
            child: AppUi.loader(context),
          );
        }
        final posts = snapshot.data!;
        if (posts.isEmpty) {
          return AppUi.emptyState(
            context,
            icon: Icons.music_note_outlined,
            title: 'No posts today',
            message:
                'The feed shows what your friends posted today. Nothing yet — check back later.',
          );
        }
        return ListView.builder(
          padding: EdgeInsets.only(top: AppUi.gap, bottom: 96.0),
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) => _postCard(context, posts[index]),
        );
      },
    );
  }
}
