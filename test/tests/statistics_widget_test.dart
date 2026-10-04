// SCRUM-39: TC-US39-01..06, TC-US39-08, TC-US39-10; SCRUM-48: TC-FEAT48-01..04, TC-FEAT48-06..08, TC-FEAT48-10, TC-FEAT48-11

import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/backend/backend.dart';
import 'package:project_for_management/statistics/statistics_widget.dart';

import 'helpers.dart';

void main() {
  final db = FakeFirebaseFirestore();
  final me = userRef(db, 'me');

  List<UserPostRecord> newestFirst(List<UserPostRecord> posts) =>
      posts.toList()..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

  List<UserPostRecord> history(Map<String, int> counts,
      {Map<String, String> emoji = const {}}) {
    final posts = <UserPostRecord>[];
    var minutesAgo = 0;
    var id = 0;
    final songs = counts.keys.toList();
    final remaining = Map.of(counts);
    while (remaining.values.any((n) => n > 0)) {
      for (final song in songs) {
        if (remaining[song]! == 0) continue;
        remaining[song] = remaining[song]! - 1;
        posts.add(post(me, 'p${id++}',
            song: song,
            emoji: emoji[song] ?? kHappy,
            createdAt: kNow.subtract(Duration(minutes: 10 + minutesAgo++))));
      }
    }
    return newestFirst(posts);
  }

  Map<String, int> distinctCounts(int n) => {
        for (var i = 1; i <= n; i++)
          'Song ${i.toString().padLeft(2, '0')}': n - i + 1,
      };

  Future<void> pumpStats(WidgetTester tester, Stream<List<UserPostRecord>> posts) async {
    useTallScreen(tester);
    await tester.pumpWidget(host(StatisticsWidget(posts: posts)));
    await tester.pump();
    await tester.pump();
  }

  List<String> rankedSongs(WidgetTester tester, {Pattern? pattern}) {
    final re = pattern ?? RegExp(r'^Song ');
    final found = find.byWidgetPredicate(
        (w) => w is Text && w.data != null && w.data!.startsWith(re));
    final widgets = found.evaluate().toList()
      ..sort((a, b) => tester
          .getTopLeft(find.byWidget(a.widget))
          .dy
          .compareTo(tester.getTopLeft(find.byWidget(b.widget)).dy));
    return widgets.map((e) => (e.widget as Text).data!).toList();
  }

  Finder songRow(WidgetTester tester, String song) {
    final rows = find.ancestor(of: find.text(song), matching: find.byType(Row));
    for (var i = 0; i < rows.evaluate().length; i++) {
      final row = rows.at(i);
      if (find.descendant(of: row, matching: find.byType(Image)).evaluate().isNotEmpty ||
          find.descendant(of: row, matching: find.byType(Icon)).evaluate().isNotEmpty) {
        return row;
      }
    }
    return rows.last;
  }

  List<String> texts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .toList();

  final emptyMessage =
      RegExp(r'nothing to show|no data|no posts|empty', caseSensitive: false);
  final errorMessage =
      RegExp(r'error|could not|failed', caseSensitive: false);

  group('SCRUM-39 AC4 / SCRUM-48 AC3 — no or little data', () {
    testWidgets('SCRUM-39 / TC-US39-01 — no posts at all: empty-state message',
        (tester) async {
      await pumpStats(tester, Stream.value(const []));

      expect(tester.takeException(), isNull);
      expect(texts(tester).any(emptyMessage.hasMatch), isTrue,
          reason: 'texts: ${texts(tester)}');
    });

    testWidgets('SCRUM-39 / TC-US39-01 — no posts this month (only last month): empty-state message',
        (tester) async {
      final fs = FakeFirebaseFirestore();
      final user = await addUser(fs, 'me');
      await addPost(fs, user, 'sep20', song: 'September song',
          createdAt: DateTime(2026, 9, 20, 18, 0));

      final fetched = await lastThirtyDaysPosts(user, kNow).first;
      await pumpStats(tester, Stream.value(fetched));

      expect(texts(tester).any(emptyMessage.hasMatch), isTrue,
          reason: 'expected the empty-month message; the screen shows: '
              '${texts(tester).take(8).toList()}');
      expect(find.text('September song'), findsNothing);
    });

    testWidgets('SCRUM-48 / TC-FEAT48-01 — 0 songs in 30 days: shown without an error',
        (tester) async {
      await pumpStats(tester, Stream.value(const []));

      expect(tester.takeException(), isNull);
      expect(texts(tester).any(errorMessage.hasMatch), isFalse);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('SCRUM-48 / TC-FEAT48-02 — 5 songs in 30 days: all 5 shown',
        (tester) async {
      await pumpStats(tester, Stream.value(history(distinctCounts(5))));

      expect(rankedSongs(tester).length, 5);
      expect(texts(tester).any(errorMessage.hasMatch), isFalse);
    });

    testWidgets('SCRUM-48 / TC-FEAT48-11 — exactly one post: one song, count 1',
        (tester) async {
      await pumpStats(tester, Stream.value(history({'Song 01': 1})));

      expect(rankedSongs(tester), ['Song 01']);
      expect(find.descendant(of: songRow(tester, 'Song 01'), matching: find.text('1')),
          findsOneWidget);
    });
  });

  group('SCRUM-39 AC2 — up to 10 songs with title, artist and count', () {
    testWidgets('SCRUM-39 / TC-US39-02 — 5 songs: all shown with title and play count',
        (tester) async {
      final counts = distinctCounts(5);
      await pumpStats(tester, Stream.value(history(counts)));

      expect(rankedSongs(tester), counts.keys.toList());
      for (final MapEntry(key: song, value: count) in counts.entries) {
        expect(
            find.descendant(of: songRow(tester, song), matching: find.text('$count')),
            findsOneWidget,
            reason: '$song should show $count plays');
      }
    });

    testWidgets('SCRUM-39 / TC-US39-02 — each song shows its artist',
        (tester) async {
      await pumpStats(tester, Stream.value(history({'Morning Light': 3})));

      final row = songRow(tester, 'Morning Light');
      expect(find.descendant(of: row, matching: find.textContaining('SoundHelix')),
          findsOneWidget,
          reason: 'SCRUM-39 AC2 lists title, ARTIST and play count; the row '
              'shows: ${tester.widgetList<Text>(find.descendant(of: row, matching: find.byType(Text))).map((t) => t.data).toList()}');
    });

    testWidgets('SCRUM-39 / TC-US39-10 — period "This month" can be selected',
        (tester) async {
      await pumpStats(tester, Stream.value(history(distinctCounts(3))));

      expect(
          find.textContaining(RegExp('this month|\u0161is m\u0117nuo', caseSensitive: false)),
          findsWidgets,
          reason: 'no period choice "This month" on screen; '
              'texts: ${texts(tester).where((t) => !t.startsWith('Song')).toList()}');
    });

    testWidgets('SCRUM-39 / TC-US39-03 — 15 songs: only the 10 most played are shown',
        (tester) async {
      final counts = distinctCounts(15);
      await pumpStats(tester, Stream.value(history(counts)));

      expect(rankedSongs(tester), counts.keys.take(10).toList());
    });

    testWidgets('SCRUM-39 / TC-US39-04 (BVA 9) — 9 songs: all 9 shown',
        (tester) async {
      await pumpStats(tester, Stream.value(history(distinctCounts(9))));

      expect(rankedSongs(tester).length, 9);
    });

    testWidgets('SCRUM-39 / TC-US39-05 (BVA 10) — 10 songs: all 10 shown',
        (tester) async {
      await pumpStats(tester, Stream.value(history(distinctCounts(10))));

      expect(rankedSongs(tester).length, 10);
    });

    testWidgets('SCRUM-39 / TC-US39-06 (BVA 11) — 11 songs: 10 shown, the least played one left out',
        (tester) async {
      final counts = distinctCounts(11);
      await pumpStats(tester, Stream.value(history(counts)));

      final shown = rankedSongs(tester);
      expect(shown.length, 10);
      expect(shown, isNot(contains('Song 11')));
    });
  });

  group('SCRUM-39 AC3 — emotion most often attached to each song', () {
    testWidgets('SCRUM-39 / TC-US39-08 — song tagged 3× with one emotion and 1× with another shows the first',
        (tester) async {
      final posts = newestFirst([
        post(me, 'a', song: 'Song X', emoji: kSad,
            createdAt: kNow.subtract(const Duration(hours: 1))),
        post(me, 'b', song: 'Song X', emoji: kHappy,
            createdAt: kNow.subtract(const Duration(hours: 2))),
        post(me, 'c', song: 'Song X', emoji: kHappy,
            createdAt: kNow.subtract(const Duration(hours: 3))),
        post(me, 'd', song: 'Song X', emoji: kHappy,
            createdAt: kNow.subtract(const Duration(hours: 4))),
      ]);
      await pumpStats(tester, Stream.value(posts));

      expect(imageUrls(tester, songRow(tester, 'Song X')), [kHappy]);
    });
  });

  group('SCRUM-48 AC1/AC4 — TOP-10 chart and its order', () {
    testWidgets('SCRUM-48 / TC-FEAT48-03 — 15 songs: the TOP-10 is charted',
        (tester) async {
      final counts = distinctCounts(15);
      await pumpStats(tester, Stream.value(history(counts)));

      expect(rankedSongs(tester), counts.keys.take(10).toList());
    });

    for (final (n, expected) in [(9, 9), (10, 10), (11, 10)]) {
      testWidgets('SCRUM-48 / TC-FEAT48-04 (BVA $n) — $n songs: $expected charted',
          (tester) async {
        await pumpStats(tester, Stream.value(history(distinctCounts(n))));

        expect(rankedSongs(tester).length, expected);
      });
    }

    testWidgets('SCRUM-48 / TC-FEAT48-06 — A 20, B 10, C 5 plays: order A, B, C',
        (tester) async {
      await pumpStats(
          tester, Stream.value(history({'Song C': 5, 'Song B': 10, 'Song A': 20})));

      expect(rankedSongs(tester), ['Song A', 'Song B', 'Song C']);
    });

    testWidgets('SCRUM-48 / TC-FEAT48-07 — A and B 10 plays each, A played later: A above B',
        (tester) async {
      await pumpStats(tester, Stream.value(history({'Song A': 10, 'Song B': 10})));

      expect(rankedSongs(tester), ['Song A', 'Song B']);
    });

    testWidgets('SCRUM-48 / TC-FEAT48-10 — tie rule still holds with 40 songs of 1 play each',
        (tester) async {
      final counts = {
        for (var i = 1; i <= 40; i++) 'Song ${i.toString().padLeft(2, '0')}': 1,
      };
      await pumpStats(tester, Stream.value(history(counts)));

      expect(rankedSongs(tester), counts.keys.take(10).toList());
    });

    testWidgets('SCRUM-48 / TC-FEAT48-10 — tie below a leader, among 35 songs',
        (tester) async {
      final counts = {
        'Song 00': 3,
        for (var i = 1; i <= 34; i++) 'Song ${i.toString().padLeft(2, '0')}': 1,
      };
      await pumpStats(tester, Stream.value(history(counts)));

      expect(rankedSongs(tester), counts.keys.take(10).toList());
    });
  });

  group('SCRUM-48 AC2 — details of a chart element', () {
    testWidgets('SCRUM-48 / TC-FEAT48-08 — tapping a chart element shows title, play count and top emotion',
        (tester) async {
      await pumpStats(
          tester,
          Stream.value(history({'Song A': 4, 'Song B': 2},
              emoji: {'Song A': kCool, 'Song B': kSad})));

      final row = songRow(tester, 'Song A');
      await tester.tap(row, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.descendant(of: row, matching: find.text('Song A')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('4')), findsOneWidget);
      expect(imageUrls(tester, row), [kCool]);
    });
  });

  group('SCRUM-48 description / SCRUM-39 DoD — recalculation', () {
    testWidgets('SCRUM-48 / TC-FEAT48-11 — a new post is counted as soon as it arrives',
        (tester) async {
      final updates = StreamController<List<UserPostRecord>>();
      addTearDown(updates.close);
      final before = history({'Song A': 2, 'Song B': 1});

      await pumpStats(tester, updates.stream);
      updates.add(before);
      await tester.pump();
      expect(find.descendant(of: songRow(tester, 'Song B'), matching: find.text('1')),
          findsOneWidget);

      updates.add(newestFirst([
        ...before,
        post(me, 'new1', song: 'Song B', emoji: kSad,
            createdAt: kNow.subtract(const Duration(minutes: 1))),
        post(me, 'new2', song: 'Song B', emoji: kSad, createdAt: kNow),
      ]));
      await tester.pump();

      expect(rankedSongs(tester), ['Song B', 'Song A']);
      expect(find.descendant(of: songRow(tester, 'Song B'), matching: find.text('3')),
          findsOneWidget);
    });

    testWidgets('SCRUM-48 / TC-FEAT48-11 — reopening the screen recalculates from fresh data',
        (tester) async {
      await pumpStats(tester, Stream.value(history({'Song A': 1})));
      expect(rankedSongs(tester), ['Song A']);

      await tester.pumpWidget(const SizedBox());
      await pumpStats(tester, Stream.value(history({'Song B': 2, 'Song A': 1})));

      expect(rankedSongs(tester), ['Song B', 'Song A']);
    });
  });

  group('SCRUM-39 / SCRUM-48 error-based — incomplete records', () {
    testWidgets('SCRUM-48 / TC-FEAT48-11 — a post without an emotion is counted and shown without one',
        (tester) async {
      final posts = newestFirst([
        post(me, 'a', song: 'Song A', emoji: null,
            createdAt: kNow.subtract(const Duration(hours: 1))),
        post(me, 'b', song: 'Song A', emoji: null,
            createdAt: kNow.subtract(const Duration(hours: 2))),
      ]);
      await pumpStats(tester, Stream.value(posts));

      expect(tester.takeException(), isNull);
      expect(find.descendant(of: songRow(tester, 'Song A'), matching: find.text('2')),
          findsOneWidget);
    });

    testWidgets('SCRUM-48 / TC-FEAT48-11 — a post without a song name is left out of the ranking',
        (tester) async {
      final posts = newestFirst([
        post(me, 'a', song: '', createdAt: kNow.subtract(const Duration(hours: 1))),
        post(me, 'b', song: 'Song A', createdAt: kNow.subtract(const Duration(hours: 2))),
      ]);
      await pumpStats(tester, Stream.value(posts));

      expect(tester.takeException(), isNull);
      expect(rankedSongs(tester), ['Song A']);
    });
  });
}
