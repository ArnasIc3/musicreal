# Demo data seeding

Fills the Firestore project with demo friends, their posts for today, a pending
friend request and 30 days of history for the account doing the demo.

## One-time setup

1. Firebase Console → Project settings → **Service accounts** → *Generate new
   private key*. Save the JSON **outside the repository** (it is a credential).
2. `npm install` in this folder.
3. Sign in to the app once with the Google account you will demo with, so its
   `users/{uid}` document exists.

## Run

```bash
GOOGLE_APPLICATION_CREDENTIALS=~/Downloads/serviceAccount.json \
  node seed_demo_data.js --email you@gmail.com
```

## Remove the demo data again

```bash
GOOGLE_APPLICATION_CREDENTIALS=~/Downloads/serviceAccount.json \
  node seed_demo_data.js --email you@gmail.com --undo
```

Everything written carries a `demo_seed: true` field, so it can be told apart
from real data.
