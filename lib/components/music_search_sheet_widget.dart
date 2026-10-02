import '/backend/backend.dart';
import '/demo/demo_data.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/ui/app_ui.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:just_audio/just_audio.dart';
import 'music_search_sheet_model.dart';
export 'music_search_sheet_model.dart';

class MusicSearchSheetWidget extends StatefulWidget {
  const MusicSearchSheetWidget({super.key});

  @override
  State<MusicSearchSheetWidget> createState() => _MusicSearchSheetWidgetState();
}

class _MusicSearchSheetWidgetState extends State<MusicSearchSheetWidget> {
  late MusicSearchSheetModel _model;

  /// The song currently previewing, so the button can show it is playing.
  String? _previewing;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MusicSearchSheetModel());

    _model.searchInputTextController ??= TextEditingController();
    _model.searchInputFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  List<String> get _genres => kDemoMode
      ? (DemoData.music.expand((song) => song.genres).toSet().toList()..sort())
      : ['Blues', 'Pop', 'Movie'];

  Future<void> _preview(MusicRecord song) async {
    _model.soundPlayer ??= AudioPlayer();
    if (_model.soundPlayer!.playing) {
      await _model.soundPlayer!.stop();
    }
    safeSetState(() => _previewing = song.songName);
    _model.soundPlayer!.setVolume(1.0);
    _model.soundPlayer!
        .setUrl(song.songURL)
        .then((_) => _model.soundPlayer!.play());

    await Future.delayed(Duration(milliseconds: 5000));
    await _model.soundPlayer?.stop();
    if (mounted) {
      safeSetState(() => _previewing = null);
    }
  }

  Widget _songTile(BuildContext context, MusicRecord song) {
    final isSelected = FFAppState().CurrentlySelectedSongPost == song.songName;
    final isPlaying = _previewing == song.songName;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          FFAppState().CurrentlySelectedSongPost = song.songName;
          // Tell the page holding this component that a song was chosen.
          _model.updatePage(() {});
          safeSetState(() {});
        },
        child: Container(
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isSelected
                ? FlutterFlowTheme.of(context).accent1
                : FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? FlutterFlowTheme.of(context).primary
                  : AppUi.border(context),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.music_note_rounded,
                size: 22.0,
                color: isSelected
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).secondaryText,
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.songName,
                      overflow: TextOverflow.ellipsis,
                      style: AppUi.title(context, size: 15.0),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      [
                        if (song.author.isNotEmpty) song.author,
                        if (song.genres.isNotEmpty) song.genres.first,
                      ].join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: AppUi.muted(context),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.0),
              // A five second preview of the track.
              IconButton(
                tooltip: isPlaying ? 'Playing preview' : 'Play a 5s preview',
                onPressed: song.songURL.isEmpty ? null : () => _preview(song),
                icon: Icon(
                  isPlaying
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline_rounded,
                  size: 30.0,
                  color: FlutterFlowTheme.of(context).primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = _model.searchInputTextController.text;

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
          child: TextFormField(
            controller: _model.searchInputTextController,
            focusNode: _model.searchInputFocusNode,
            onChanged: (_) => EasyDebounce.debounce(
              '_model.searchInputTextController',
              Duration(milliseconds: 300),
              () => safeSetState(() {}),
            ),
            autofocus: false,
            obscureText: false,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search songs by name...',
              hintStyle: AppUi.muted(context),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    BorderSide(color: AppUi.border(context), width: 1.0),
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
              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
              contentPadding:
                  EdgeInsetsDirectional.fromSTEB(20.0, 12.0, 20.0, 12.0),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 20.0,
              ),
              suffixIcon: search.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.clear_rounded, size: 18.0),
                      color: FlutterFlowTheme.of(context).secondaryText,
                      onPressed: () => safeSetState(
                          () => _model.searchInputTextController?.clear()),
                    ),
            ),
            style: AppUi.body(context),
            validator:
                _model.searchInputTextControllerValidator.asValidator(context),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 8.0),
          child: FlutterFlowDropDown<String>(
            controller: _model.dropDownValueController ??=
                FormFieldController<String>(null),
            options: _genres,
            onChanged: (val) => safeSetState(() => _model.dropDownValue = val),
            width: double.infinity,
            height: 44.0,
            textStyle: AppUi.body(context),
            hintText: 'All genres',
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: FlutterFlowTheme.of(context).secondaryText,
              size: 24.0,
            ),
            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
            elevation: 0.0,
            borderColor: AppUi.border(context),
            borderWidth: 1.0,
            borderRadius: 12.0,
            margin: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 12.0, 0.0),
            hidesUnderline: true,
            isOverButton: false,
            isSearchable: false,
            isMultiSelect: false,
          ),
        ),
        Expanded(
          child: PagedListView<DocumentSnapshot<Object?>?, MusicRecord>(
            pagingController: _model.setListViewController(
              MusicRecord.collection
                  .where(
                    'SongName',
                    isEqualTo: search != '' ? search : null,
                  )
                  .where(
                    'Genres',
                    arrayContains: _model.dropDownValue != ''
                        ? _model.dropDownValue
                        : null,
                  ),
              demoItems: kDemoMode
                  ? DemoData.music.where((song) {
                      final genre = _model.dropDownValue ?? '';
                      final matchesSearch = search.isEmpty ||
                          song.songName
                              .toLowerCase()
                              .contains(search.toLowerCase());
                      final matchesGenre =
                          genre.isEmpty || song.genres.contains(genre);
                      return matchesSearch && matchesGenre;
                    }).toList()
                  : null,
            ),
            padding: EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 8.0),
            shrinkWrap: false,
            reverse: false,
            scrollDirection: Axis.vertical,
            builderDelegate: PagedChildBuilderDelegate<MusicRecord>(
              firstPageProgressIndicatorBuilder: (_) => AppUi.loader(context),
              newPageProgressIndicatorBuilder: (_) =>
                  AppUi.loader(context, size: 24.0),
              noItemsFoundIndicatorBuilder: (_) => AppUi.emptyState(
                context,
                icon: Icons.search_off_rounded,
                title: 'No songs found',
                message: 'Try a different name, or clear the genre filter.',
              ),
              itemBuilder: (context, _, index) => _songTile(
                context,
                _model.listViewPagingController!.itemList![index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
