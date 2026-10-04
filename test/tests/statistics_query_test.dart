// SCRUM-48: TC-FEAT48-01, TC-FEAT48-05, TC-FEAT48-11

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_for_management/statistics/statistics_widget.dart';

import 'helpers.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  test('SCRUM-48 / TC-FEAT48-05 (BVA) — 29 and 30 days ago are counted, 31 days ago is not',
      () async {
    final me = await addUser(db, 'me');
    await addPost(db, me, 'x29', song: 'X',
        createdAt: kNow.subtract(const Duration(days: 29)));
    await addPost(db, me, 'y30', song: 'Y',
        createdAt: kNow.subtract(const Duration(days: 30)));
    await addPost(db, me, 'z31', song: 'Z',
        createdAt: kNow.subtract(const Duration(days: 31)));

    final posts = await lastThirtyDaysPosts(me, kNow).first;

    expect(paths(posts), unorderedEquals(['x29', 'y30']));
  });

  test('SCRUM-48 / TC-FEAT48-11 — only the signed-in user\'s own posts are counted',
      () async {
    final me = await addUser(db, 'me');
    final other = await addUser(db, 'other');
    await addPost(db, me, 'mine', song: 'Mine',
        createdAt: kNow.subtract(const Duration(days: 1)));
    await addPost(db, other, 'theirs', song: 'Theirs',
        createdAt: kNow.subtract(const Duration(days: 1)));

    final posts = await lastThirtyDaysPosts(me, kNow).first;

    expect(paths(posts), ['mine']);
  });

  test('SCRUM-48 AC3 / TC-FEAT48-01 — no posts in 30 days gives an empty list, not an error',
      () async {
    final me = await addUser(db, 'me');
    await addPost(db, me, 'old', song: 'Old',
        createdAt: kNow.subtract(const Duration(days: 45)));

    expect(await lastThirtyDaysPosts(me, kNow).first, isEmpty);
  });

  test('SCRUM-48 / TC-FEAT48-11 — no signed-in user gives an empty list, not a crash',
      () async {
    expect(await lastThirtyDaysPosts(null, kNow).first, isEmpty);
  });
}
