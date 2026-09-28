/**
 * Fills the Firestore project with demo data so the app can be shown with
 * content: demo friends, their posts for today, a pending friend request,
 * and 30 days of posts for the account doing the demo.
 *
 * Usage:
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json \
 *     node seed_demo_data.js --email you@gmail.com
 *
 *   node seed_demo_data.js --email you@gmail.com --undo    (removes demo data)
 *
 * The account you name must have signed in to the app at least once, so that
 * its users/{uid} document exists.
 */
const admin = require("firebase-admin");

const args = process.argv.slice(2);
const argOf = (name) => {
  const i = args.indexOf(`--${name}`);
  return i === -1 ? null : args[i + 1];
};
const undo = args.includes("--undo");
const email = argOf("email");
const uidArg = argOf("uid");

if (!email && !uidArg) {
  console.error("Pass --email you@gmail.com (or --uid <uid>) for the demo account.");
  process.exit(1);
}

admin.initializeApp({ projectId: argOf("project") || "project-for-management-sugxvo" });
const db = admin.firestore();

// Demo people. They exist only as Firestore profiles: they never sign in,
// so no Authentication accounts are created for them.
const DEMO_USERS = [
  { id: "demo_aiste", name: "Aistė Demo", email: "aiste@demo.invalid" },
  { id: "demo_tomas", name: "Tomas Demo", email: "tomas@demo.invalid" },
  { id: "demo_gabija", name: "Gabija Demo", email: "gabija@demo.invalid" },
  // Sends a friend request instead of being a friend, so the accept flow
  // can be demonstrated.
  { id: "demo_lukas", name: "Lukas Demo", email: "lukas@demo.invalid", requestsOnly: true },
];

const EMOTIONS = [
  "https://static.vecteezy.com/system/resources/thumbnails/059/420/483/small/cool-smiley-face-with-sunglasses-giving-thumbs-up-png.png",
  "https://static.vecteezy.com/system/resources/thumbnails/059/420/444/small/laughing-emoji-with-joyful-expression-and-tears-png.png",
  "https://png.pngtree.com/png-vector/20241102/ourmid/pngtree-crying-sad-emoji-png-image_14216691.png",
];

const avatar = (name) =>
  `https://api.dicebear.com/7.x/initials/png?seed=${encodeURIComponent(name)}`;

const startOfDay = (d) => new Date(d.getFullYear(), d.getMonth(), d.getDate());

async function findTargetUser() {
  if (uidArg) {
    const snap = await db.collection("users").doc(uidArg).get();
    if (!snap.exists) throw new Error(`No users/${uidArg} document.`);
    return snap;
  }
  const found = await db.collection("users").where("email", "==", email).limit(1).get();
  if (found.empty) {
    throw new Error(
      `No user with email ${email}. Sign in to the app once with that account first.`
    );
  }
  return found.docs[0];
}

async function songNames() {
  const music = await db.collection("Music").limit(10).get();
  const names = music.docs.map((d) => d.get("SongName")).filter(Boolean);
  if (names.length === 0) {
    throw new Error(
      "The Music collection is empty, so posts would reference songs that do not exist."
    );
  }
  return names;
}

async function removeDemoData(targetRef) {
  const writer = db.bulkWriter();
  for (const person of DEMO_USERS) {
    const ref = db.collection("users").doc(person.id);
    const posts = await ref.collection("userPost").get();
    posts.forEach((doc) => writer.delete(doc.ref));
    writer.delete(ref);

    for (const field of ["sender", "receiver"]) {
      const reqs = await db.collection("friend_requests").where(field, "==", ref).get();
      reqs.forEach((doc) => writer.delete(doc.ref));
    }
    writer.update(targetRef, {
      friends: admin.firestore.FieldValue.arrayRemove(ref),
    });
  }
  const own = await targetRef.collection("userPost").where("demo_seed", "==", true).get();
  own.forEach((doc) => writer.delete(doc.ref));
  await writer.close();
  console.log("Demo data removed.");
}

async function main() {
  const target = await findTargetUser();
  const targetRef = target.ref;
  console.log(`Demo account: ${target.get("display_name") || email} (${targetRef.id})`);

  if (undo) {
    await removeDemoData(targetRef);
    return;
  }

  const songs = await songNames();
  const now = new Date();
  const writer = db.bulkWriter();

  for (const person of DEMO_USERS) {
    const ref = db.collection("users").doc(person.id);
    writer.set(
      ref,
      {
        uid: person.id,
        email: person.email,
        display_name: person.name,
        photo_url: avatar(person.name),
        created_time: admin.firestore.Timestamp.fromDate(now),
        streak_count: 3 + DEMO_USERS.indexOf(person),
        last_post_date: admin.firestore.Timestamp.fromDate(startOfDay(now)),
        friends: person.requestsOnly ? [] : [targetRef],
        demo_seed: true,
      },
      { merge: true }
    );

    if (person.requestsOnly) {
      writer.set(db.collection("friend_requests").doc(`demo_req_${person.id}`), {
        sender: ref,
        receiver: targetRef,
        status: "pending",
        created_at: admin.firestore.Timestamp.fromDate(now),
        demo_seed: true,
      });
      continue;
    }

    writer.update(targetRef, {
      friends: admin.firestore.FieldValue.arrayUnion(ref),
    });

    // Two posts today each, so the feed has content.
    for (let i = 0; i < 2; i++) {
      const when = new Date(now.getTime() - (i * 3 + 1) * 60 * 60 * 1000);
      writer.set(ref.collection("userPost").doc(`demo_post_${i}`), {
        song_name: songs[(DEMO_USERS.indexOf(person) * 2 + i) % songs.length],
        emoji: EMOTIONS[(DEMO_USERS.indexOf(person) + i) % EMOTIONS.length],
        post_user: ref,
        created_at: admin.firestore.Timestamp.fromDate(when),
        demo_seed: true,
      });
    }
  }

  // 30 days of history for the demo account, so its statistics are filled.
  for (let day = 0; day < 30; day++) {
    if (day % 4 === 3) continue; // a few gaps, so the chart is not flat
    const when = new Date(now.getTime() - day * 24 * 60 * 60 * 1000 - 60 * 60 * 1000);
    writer.set(targetRef.collection("userPost").doc(`demo_history_${day}`), {
      song_name: songs[(day * 3) % songs.length],
      emoji: EMOTIONS[day % EMOTIONS.length],
      post_user: targetRef,
      created_at: admin.firestore.Timestamp.fromDate(when),
      demo_seed: true,
    });
  }

  writer.update(targetRef, {
    streak_count: 7,
    last_post_date: admin.firestore.Timestamp.fromDate(startOfDay(now)),
  });

  await writer.close();
  console.log(
    `Seeded ${DEMO_USERS.length - 1} friends, 1 pending request, today's feed and 30 days of history.`
  );
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
