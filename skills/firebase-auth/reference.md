# Firebase Auth — SDK wiring reference

## Choosing an SDK flavour

| Flavour | Load | Use when |
|---|---|---|
| **compat** (`firebase.auth()`) | 3 `<script>` tags from gstatic | Plain HTML/JS pages, no bundler. Simplest to stub in tests. |
| **modular** (`import { getAuth }`) | npm + bundler | React/Next/Vite projects. Tree-shakes; required for new work in a framework. |

Match whatever the project already uses. Don't migrate a working compat page to modular
as a side effect of adding auth.

### compat loading (no bundler)

```html
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.1/firebase-firestore-compat.js"></script>
<script src="/static/firebase-config.js"></script>
```

## Config and initialisation

The web config (apiKey, authDomain, projectId, …) is **public by design** — it ships in
every client bundle. It is not a secret and does not need env-var indirection on a static
page. What must never be committed: service-account JSON, admin SDK credentials, or any
server-side key. Access control belongs in Firestore Security Rules.

Initialise defensively — a missing or misconfigured project must degrade to "auth
unavailable", not a blank page:

```js
const firebaseConfig = { apiKey: "...", authDomain: "...", projectId: "...", appId: "..." };

let auth = null;
let db = null;
let currentUser = null;
let authReady = false;

try {
    firebase.initializeApp(firebaseConfig);
    auth = firebase.auth();
    db = firebase.firestore();
} catch (e) {
    console.warn("Firebase unavailable; running signed-out:", e);
}

if (auth) {
    auth.onAuthStateChanged((user) => {
        currentUser = user;
        authReady = true;
        updateAuthUI();
        if (user) loadUserData(); else clearUserData();
    });
} else {
    authReady = true;
    updateAuthUI();
}
```

`authReady` matters: code that gates on "is the user signed in?" must wait for the first
`onAuthStateChanged` callback, or it will treat a returning signed-in user as anonymous
for the first few hundred milliseconds.

## Auth helpers

Keep them thin, Promise-returning, and null-safe. The UI layer owns messaging; these own
nothing but the call.

```js
function signInWithEmail(email, password) {
    if (!auth) return Promise.reject(new Error("Authentication is not available right now."));
    return auth.signInWithEmailAndPassword(email, password);
}

function signUpWithEmail(email, password) {
    if (!auth) return Promise.reject(new Error("Authentication is not available right now."));
    return auth.createUserWithEmailAndPassword(email, password);
}

function sendPasswordReset(email) {
    if (!auth) return Promise.reject(new Error("Authentication is not available right now."));
    return auth.sendPasswordResetEmail(email);
}

function signInWithGoogle() {
    if (!auth) return Promise.reject(new Error("Authentication is not available right now."));
    // Return the Promise — the caller decides what a cancelled popup means.
    return auth.signInWithPopup(new firebase.auth.GoogleAuthProvider());
}

function signOut() {
    if (auth) auth.signOut();
}
```

**Popup vs. redirect.** `signInWithPopup` is the better UX and is what to use by default.
Fall back to `signInWithRedirect` only for known popup-hostile contexts (in-app browsers,
some mobile Safari configurations). Handle `auth/popup-blocked` either way.

## Error-code map

Never show a raw Firebase message. The `method` argument sharpens the not-enabled case,
which is a Console misconfiguration rather than anything the visitor did wrong.

```js
function friendlyAuthError(err, method) {
    switch (err && err.code) {
        case "auth/invalid-email": return "That doesn't look like a valid email address.";
        case "auth/user-disabled": return "This account has been disabled.";
        case "auth/user-not-found":
        case "auth/wrong-password":
        case "auth/invalid-credential": return "Incorrect email or password.";
        case "auth/email-already-in-use": return "An account with this email already exists. Try signing in instead.";
        case "auth/weak-password": return "Please choose a stronger password.";
        case "auth/too-many-requests": return "Too many attempts. Please wait a moment and try again.";
        case "auth/network-request-failed": return "Network error. Check your connection and try again.";
        case "auth/operation-not-allowed":
            return method === "google"
                ? "Google sign-in isn't enabled for this site yet. (Site owner: enable the Google provider in Firebase Console → Authentication → Sign-in method.)"
                : "Email and password sign-in isn't enabled for this site yet. (Site owner: enable the Email/Password provider in Firebase Console → Authentication → Sign-in method.)";
        case "auth/unauthorized-domain": return "This domain isn't authorized for sign-in. (Site owner: add it under Firebase Console → Authentication → Settings → Authorized domains.)";
        case "auth/popup-blocked": return "Your browser blocked the sign-in popup. Please allow popups and try again.";
        case "auth/account-exists-with-different-credential": return "An account already exists with this email using a different sign-in method.";
        case "auth/missing-email": return "Please enter your email address first.";
        default: return (err && err.message) || "Something went wrong. Please try again.";
    }
}
```

Two codes are **not** errors to display: `auth/popup-closed-by-user` and
`auth/cancelled-popup-request`. The visitor changed their mind; say nothing.

`auth/user-not-found` on a *password reset* is also not an error to display — see
"Account enumeration" below.

## Account enumeration

Password reset must not tell an attacker which addresses are registered:

```js
try {
    await sendPasswordReset(email);
    showAuthNotice(`If an account exists for ${email}, a password reset link is on its way.`);
} catch (err) {
    if (err && err.code === "auth/user-not-found") {
        showAuthNotice(`If an account exists for ${email}, a password reset link is on its way.`);
    } else {
        showAuthError(friendlyAuthError(err, "email"));
    }
}
```

Firebase also has an "Email enumeration protection" setting (Authentication → Settings)
that collapses `user-not-found` / `wrong-password` into `auth/invalid-credential` at the
API level. Turn it on; the mapping above already handles both shapes.

## Per-user data + the sign-out purge

Signed-in data lives under the uid; signed-out data falls back to `localStorage`.

```js
function userDoc() {
    return db.collection("users").doc(currentUser.uid);
}

async function loadUserData() {
    const snap = await userDoc().get();
    const data = snap.exists ? snap.data() : {};
    window._firebaseHistory = data.history || [];
    window._firebaseFavorites = data.favorites || [];
    renderHistory();
    renderFavorites();
}

// Called on sign-out. Without this, the previous account's items stay rendered
// for whoever is at the keyboard next.
function clearUserData() {
    window._firebaseHistory = [];
    window._firebaseFavorites = [];
    renderHistory();
    renderFavorites();
}
```

Optionally merge anonymous `localStorage` data into the account on first sign-in — ask
the user whether they want that before building it; it's a real product decision, not a
detail.

### Firestore rules

Per-user documents need rules, or the data is world-readable:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## Firebase Console checklist (the human has to do these)

State these explicitly when handing off; no code substitutes for them.

1. **Authentication → Sign-in method** — enable **Email/Password**. Enable **Google**
   and set a support email if using Google.
2. **Authentication → Settings → Authorized domains** — add the deployed domain
   (`your-project.vercel.app`, the custom domain, and `localhost` for dev). Required for
   the Google popup; its absence is `auth/unauthorized-domain`.
3. **Authentication → Settings** — turn on email enumeration protection.
4. **Authentication → Templates** — customise the password-reset email sender name and
   subject if the default "noreply@project.firebaseapp.com" looks wrong for the brand.
5. **Firestore → Rules** — publish the per-user rules above before launch. The default
   test-mode rules expire and are open until they do.
