import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/demo/demo_data.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'friends_list_model.dart';
export 'friends_list_model.dart';

/// The friends circle: who you follow, and who asked to follow you.
class FriendsListWidget extends StatefulWidget {
  const FriendsListWidget({super.key});

  static String routeName = 'FriendsList';
  static String routePath = '/friendsList';

  @override
  State<FriendsListWidget> createState() => _FriendsListWidgetState();
}

class _FriendsListWidgetState extends State<FriendsListWidget>
    with TickerProviderStateMixin {
  late FriendsListModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FriendsListModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  bool get _readOnly => kDemoMode;

  Future<void> _removeFriend(BuildContext context, UsersRecord friend) async {
    if (_readOnly) {
      _showMessage(context, 'The demo data cannot be changed.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${friend.displayName}?'),
        content: Text(
            'You stop seeing each other\'s posts. You can send a new request later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Remove',
              style: TextStyle(color: FlutterFlowTheme.of(context).error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await currentUserReference!.update({
      ...mapToFirestore({
        'friends': FieldValue.arrayRemove([friend.reference]),
      }),
    });
    await friend.reference.update({
      ...mapToFirestore({
        'friends': FieldValue.arrayRemove([currentUserReference]),
      }),
    });
    if (context.mounted) {
      _showMessage(context, '${friend.displayName} removed.');
    }
  }

  Future<void> _accept(
      BuildContext context, FriendRequestsRecord request) async {
    if (_readOnly) {
      _showMessage(context, 'The demo data cannot be changed.');
      return;
    }
    await request.reference
        .update(createFriendRequestsRecordData(status: 'accepted'));
    await currentUserReference!.update({
      ...mapToFirestore({
        'friends': FieldValue.arrayUnion([request.sender]),
      }),
    });
    await request.sender!.update({
      ...mapToFirestore({
        'friends': FieldValue.arrayUnion([currentUserReference]),
      }),
    });
  }

  Future<void> _decline(
      BuildContext context, FriendRequestsRecord request) async {
    if (_readOnly) {
      _showMessage(context, 'The demo data cannot be changed.');
      return;
    }
    await request.reference.delete();
  }

  Widget _personCard(
    BuildContext context, {
    required UsersRecord user,
    required Widget trailing,
  }) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
          AppUi.gutter, 0.0, AppUi.gutter, AppUi.gap),
      child: AppUi.card(
        context,
        child: Row(
          children: [
            AppUi.avatar(context, user.photoUrl, size: 44.0),
            SizedBox(width: AppUi.gap),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: AppUi.title(context),
                  ),
                  if (user.streakCount > 0) ...[
                    SizedBox(height: 2.0),
                    Text(
                      '${user.streakCount} day streak',
                      style: AppUi.muted(context),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.0),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _friendsTab(BuildContext context) {
    final search = _model.textController.text.trim().toLowerCase();
    final friendRefs = kDemoMode
        ? DemoData.me.friends.toList()
        : (currentUserDocument?.friends.toList() ?? []);

    if (friendRefs.isEmpty) {
      return AppUi.emptyState(
        context,
        icon: Icons.group_add_outlined,
        title: 'No friends yet',
        message: 'Search for people and send them a request.',
        action: FFButtonWidget(
          onPressed: () async {
            context.pushNamed(FriendsListAddFriendWidget.routeName);
          },
          text: 'Find friends',
          options: AppUi.primaryButton(context),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.only(top: AppUi.gap, bottom: 24.0),
      itemCount: friendRefs.length,
      itemBuilder: (context, index) {
        final friendRef = friendRefs[index];
        return StreamBuilder<UsersRecord>(
          stream: kDemoMode
              ? Stream.value(DemoData.userFor(friendRef))
              : UsersRecord.getDocument(friendRef),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Padding(
                padding: EdgeInsets.all(AppUi.gutter),
                child: AppUi.loader(context, size: 24.0),
              );
            }
            final friend = snapshot.data!;
            // Filtering happens here, so the search box actually searches.
            if (search.isNotEmpty &&
                !friend.displayName.toLowerCase().contains(search)) {
              return SizedBox.shrink();
            }
            return _personCard(
              context,
              user: friend,
              trailing: IconButton(
                tooltip: 'Remove friend',
                icon: Icon(
                  Icons.person_remove_rounded,
                  color: FlutterFlowTheme.of(context).error,
                  size: 20.0,
                ),
                onPressed: () => _removeFriend(context, friend),
              ),
            );
          },
        );
      },
    );
  }

  Widget _requestsTab(BuildContext context) {
    return StreamBuilder<List<FriendRequestsRecord>>(
      stream: kDemoMode
          ? Stream.value(DemoData.pendingRequests)
          : queryFriendRequestsRecord(
              queryBuilder: (friendRequestsRecord) => friendRequestsRecord
                  .where('receiver', isEqualTo: currentUserReference)
                  .where('status', isEqualTo: 'pending'),
            ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: EdgeInsets.only(top: 48.0),
            child: AppUi.loader(context),
          );
        }
        final requests = snapshot.data!;
        if (requests.isEmpty) {
          return AppUi.emptyState(
            context,
            icon: Icons.mark_email_read_outlined,
            title: 'No pending requests',
            message: 'Requests from other people show up here.',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(top: AppUi.gap, bottom: 24.0),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return StreamBuilder<UsersRecord>(
              stream: kDemoMode
                  ? Stream.value(DemoData.userFor(request.sender!))
                  : UsersRecord.getDocument(request.sender!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Padding(
                    padding: EdgeInsets.all(AppUi.gutter),
                    child: AppUi.loader(context, size: 24.0),
                  );
                }
                final sender = snapshot.data!;
                return _personCard(
                  context,
                  user: sender,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FFButtonWidget(
                        onPressed: () => _accept(context, request),
                        text: 'Accept',
                        options: AppUi.primaryButton(context, height: 36.0),
                      ),
                      SizedBox(width: 8.0),
                      FFButtonWidget(
                        onPressed: () => _decline(context, request),
                        text: 'Decline',
                        options: AppUi.quietButton(context, height: 36.0),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: FlutterFlowTheme.of(context).primaryText,
            ),
            onPressed: () => context.pushNamed(ProfileWidget.routeName),
          ),
          title: Text(
            'Friends',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.urbanist(fontWeight: FontWeight.bold),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                ),
          ),
          actions: [
            IconButton(
              tooltip: 'Add a friend',
              icon: Icon(
                Icons.person_add_alt_1_rounded,
                color: FlutterFlowTheme.of(context).primary,
              ),
              onPressed: () =>
                  context.pushNamed(FriendsListAddFriendWidget.routeName),
            ),
            SizedBox(width: 8.0),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: AuthUserStreamWidget(
            builder: (context) => Column(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                      AppUi.gutter, AppUi.gap, AppUi.gutter, AppUi.gap),
                  child: TextFormField(
                    controller: _model.textController,
                    focusNode: _model.textFieldFocusNode,
                    onChanged: (_) => safeSetState(() {}),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search your friends...',
                      hintStyle: AppUi.muted(context),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: AppUi.border(context), width: 1.0),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      filled: true,
                      fillColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      contentPadding: EdgeInsetsDirectional.fromSTEB(
                          20.0, 12.0, 20.0, 12.0),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 20.0,
                      ),
                    ),
                    style: AppUi.body(context),
                    validator:
                        _model.textControllerValidator.asValidator(context),
                  ),
                ),
                TabBar(
                  controller: _model.tabBarController,
                  labelColor: FlutterFlowTheme.of(context).primaryText,
                  unselectedLabelColor:
                      FlutterFlowTheme.of(context).secondaryText,
                  indicatorColor: FlutterFlowTheme.of(context).primary,
                  indicatorWeight: 2.0,
                  labelStyle: AppUi.title(context, size: 15.0),
                  unselectedLabelStyle: AppUi.body(context),
                  tabs: [
                    Tab(text: 'Friends'),
                    Tab(text: 'Requests'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _model.tabBarController,
                    children: [
                      _friendsTab(context),
                      _requestsTab(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
