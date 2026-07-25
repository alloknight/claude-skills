---
name: firebase-auth
description: Add Firebase Authentication to a website — email/password sign-up and sign-in, Google sign-in, password reset, a sign-in modal, and per-user data in Firestore. Use when the user wants to add login, sign-in, sign-up, accounts, auth, "let users save their work", Google sign-in, or password reset to a site, or wants an existing Firebase auth flow hardened or tested.
argument-hint: [what to add, e.g. "email + Google sign-in with saved favorites"]
---

# Firebase Auth Skill

You are an expert at shipping a complete, production-grade Firebase Authentication flow on a website: the sign-in UI, the SDK wiring, the per-user data layer, and browser tests that prove it works without a real Firebase project.

Read the reference files in `${CLAUDE_SKILL_DIR}` as you need them:

- `reference.md` — SDK loading and config, auth helper functions, the Firebase error-code → friendly-message map, per-user Firestore data, sign-out cleanup, Firebase Console setup
- `ui-patterns.md` — Sign-in modal markup, sign-in/sign-up mode switching, password strength + confirm + show/hide, error vs. notice, modal dismissal, accessibility
- `testing.md` — The Playwright + fake-SDK harness: how to stub `window.firebase`, the conftest, and the test checklist

## Step 1 — Intake (do this first, always)

**Never start writing auth code before asking.** Use `AskUserQuestion` for anything the
repo can't answer. Read the codebase first, then ask only what's genuinely undecided —
if the project already has a Firebase config, don't ask which provider to use.

Ask these, in one or two `AskUserQuestion` rounds:

1. **Which sign-in methods?** (multi-select) — Email + password / Google / both / anonymous
   fallback. Both is the common answer; each provider must be enabled in the Firebase
   Console separately.
2. **Is sign-in required or optional?** — Hard gate (can't use the app signed out),
   soft gate (prompt at a moment of value, "Continue without signing in" available), or
   sign-in only for saving. A soft gate is usually right for consumer tools.
3. **What user data gets stored, and where does it live for signed-out users?** —
   e.g. history and favorites in Firestore when signed in, `localStorage` when not. This
   decides the read/write path *and* the sign-out purge.
4. **Sign-up password policy?** — Default: 8+ characters with letters and numbers,
   confirm field, live strength meter. Firebase's own floor is only 6 characters.
5. **Email verification / password reset?** — Reset is near-mandatory; ask whether
   unverified emails should be blocked from anything.
6. **Where does the existing UI put the entry point?** — Top-bar button, gated action,
   both. Look for an existing header/modal to match rather than inventing a style.

If the answer to a question is already obvious from the repo or from what the user
typed in `$ARGUMENTS`, state your assumption and move on — don't ask for its own sake.

## Step 2 — Build in this order

1. **Config** — `firebase-config.js` (or equivalent): init, `onAuthStateChanged`, and
   exported helpers `signInWithEmail`, `signUpWithEmail`, `sendPasswordReset`,
   `signInWithGoogle`, `signOut`. Every helper returns a Promise and rejects with a
   clear Error when `auth` failed to initialise — never let a caller hit a TypeError on
   a null `auth`.
2. **Modal markup** — One card that handles both sign-in and sign-up via a mode switch.
   See `ui-patterns.md`.
3. **Wiring** — Form submit, mode toggle, Google button, forgot-password, show/hide
   password, strength meter, confirm-match feedback, loading state on submit.
4. **Error mapping** — Map every `auth/*` code to plain language. Never surface a raw
   Firebase error string to a visitor.
5. **Per-user data** — Load on sign-in; **purge and re-render on sign-out**.
6. **Tests** — Playwright against the real page with a fake Firebase SDK. Not optional.
7. **Docs** — README section listing the exact Firebase Console toggles required.

## Critical Rules

1. **Ask the intake questions before writing code.** Auth touches data model, gating,
   and UX — guessing wastes a full implementation.
2. **Tests are part of the deliverable, not a follow-up.** Ship
   `tests/frontend/` (or the project's equivalent) with a fake SDK, per `testing.md`.
   Tests must skip cleanly, not fail, when Playwright or Chromium is absent.
3. **Never commit real Firebase secrets beyond the public web config.** The web API key
   is public by design; service-account JSON, admin credentials, and `.env` files are not.
   Security lives in Firestore rules, not in hiding the config.
4. **Never write your own password hashing or session handling.** Firebase owns that.
5. **On sign-out, clear the previous account's cached data and re-render.** The classic
   bug is that the last user's saved items stay on screen for the next person.
6. **Every modal must be dismissable** — backdrop click *and* `Escape` — and dismissing
   must still honour whatever action the user was trying to take.
7. **Enforce the password policy client-side before calling Firebase**, and re-mask
   revealed password fields whenever the modal resets.
8. **Don't reveal whether an email is registered.** Password reset shows the same "if an
   account exists…" notice whether or not the address is known.
9. **Provider-not-enabled and unauthorized-domain errors get an actionable message**
   naming the Console setting to flip — those are the site owner's bug, not the visitor's.
10. **Match the existing page's styling and DOM conventions.** Read the current CSS and
    reuse its variables, radii, and button classes.

## Quick Template — auth helpers

```js
// Every helper returns a Promise; a null `auth` rejects with a readable message
// rather than throwing a TypeError inside the caller's try block.
function signInWithEmail(email, password) {
    if (!auth) return Promise.reject(new Error("Authentication is not available right now."));
    return auth.signInWithEmailAndPassword(email, password);
}

function signUpWithEmail(email, password) {
    if (!auth) return Promise.reject(new Error("Authentication is not available right now."));
    return auth.createUserWithEmailAndPassword(email, password);
}

function signInWithGoogle() {
    if (!auth) return Promise.reject(new Error("Authentication is not available right now."));
    return auth.signInWithPopup(new firebase.auth.GoogleAuthProvider());
}
```

## Quick Template — sign-out purge

```js
auth.onAuthStateChanged((user) => {
    currentUser = user;
    updateAuthUI();
    if (user) {
        loadUserData();
    } else {
        // Drop the previous account's cached data and re-render, so the UI falls
        // back to anonymous storage instead of showing the last user's items.
        window._firebaseHistory = [];
        window._firebaseFavorites = [];
        if (typeof renderHistory === "function") renderHistory();
        if (typeof renderFavorites === "function") renderFavorites();
    }
});
```

## Verification Checklist

Before reporting done, confirm each of these — by running the tests, not by reading code:

- [ ] Sign up → signed in, UI updates, pending action runs
- [ ] Sign up with mismatched / weak password → blocked before any Firebase call
- [ ] Duplicate email → "account already exists, try signing in"
- [ ] Sign in with wrong password → friendly error, submit button restored
- [ ] Google sign-in succeeds; dismissing the popup is silent, not an error
- [ ] Disabled provider → message naming the Console setting
- [ ] Reset email sends; unknown address gets the identical notice
- [ ] Eye toggles work per-field; reopening the modal re-masks and clears
- [ ] Sign-out clears rendered per-user data
- [ ] Backdrop click and `Escape` dismiss every modal; clicks inside the card don't
- [ ] The full test suite passes, and skips (not fails) without Chromium

## Final Note

`$ARGUMENTS` describes what the user wants — treat it as the answer to intake question 1
and 2 where it's explicit, and ask about the rest. Finish by telling the user the exact
Firebase Console steps they must perform themselves (enable providers, add the deployed
domain to authorized domains); no amount of code substitutes for those toggles.
