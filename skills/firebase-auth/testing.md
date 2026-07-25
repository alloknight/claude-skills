# Testing the auth flow

The goal: drive the **real** `index.html` + `script.js` + `firebase-config.js` in a real
browser, with the Firebase SDK replaced by an in-memory stub. No network, no Firebase
project, no test account, fully deterministic. Every auth error can be forced on demand.

Do not test by mocking your own helper functions — that proves nothing about the wiring,
which is where the bugs are.

## The approach

1. Serve the repo over plain HTTP so absolute `/static/...` paths resolve.
2. Intercept every request to the Firebase CDN and answer with `fake_firebase.js`.
3. Load the page, wait for `onAuthStateChanged` to settle, then drive the DOM.
4. Fail the test on any uncaught page error — a broken handler must never pass silently.

For a bundler project (modular SDK), the equivalent is aliasing `firebase/auth` to a
stub module in the test build config; the fake below ports over with minor renaming.

## `tests/frontend/fake_firebase.js`

`window.__fb` is the control surface: seed accounts, force the next call to fail with any
`auth/*` code, and inspect what was called.

```js
(function () {
    const users = {};      // email -> password
    const store = {};      // uid -> user doc
    let current = null;
    let listener = null;

    window.__fb = { users, store, failNext: null, lastReset: null };

    function emit() { if (listener) listener(current); }
    function err(code) { const e = new Error(code); e.code = code; return e; }

    // Honour (and clear) a queued failure so a test can force any auth error.
    function maybeFail() {
        const code = window.__fb.failNext;
        if (!code) return null;
        window.__fb.failNext = null;
        return Promise.reject(err(code));
    }

    function userFor(email) {
        return { uid: "uid-" + email, email, displayName: null, photoURL: null };
    }

    const auth = {
        onAuthStateChanged(cb) { listener = cb; setTimeout(() => cb(current), 0); },
        signInWithEmailAndPassword(email, password) {
            const failed = maybeFail(); if (failed) return failed;
            if (!/\S+@\S+/.test(email))   return Promise.reject(err("auth/invalid-email"));
            if (!(email in users))         return Promise.reject(err("auth/user-not-found"));
            if (users[email] !== password) return Promise.reject(err("auth/wrong-password"));
            current = userFor(email); emit();
            return Promise.resolve({ user: current });
        },
        createUserWithEmailAndPassword(email, password) {
            const failed = maybeFail(); if (failed) return failed;
            if (!/\S+@\S+/.test(email)) return Promise.reject(err("auth/invalid-email"));
            if (email in users)          return Promise.reject(err("auth/email-already-in-use"));
            if (String(password).length < 6) return Promise.reject(err("auth/weak-password"));
            users[email] = password;
            current = userFor(email); emit();
            return Promise.resolve({ user: current });
        },
        sendPasswordResetEmail(email) {
            const failed = maybeFail(); if (failed) return failed;
            if (!(email in users)) return Promise.reject(err("auth/user-not-found"));
            window.__fb.lastReset = email;
            return Promise.resolve();
        },
        signInWithPopup() {
            const failed = maybeFail(); if (failed) return failed;
            current = { uid: "uid-google", email: "g@example.com", displayName: "Google User", photoURL: "" };
            emit();
            return Promise.resolve({ user: current });
        },
        signOut() { current = null; emit(); return Promise.resolve(); },
    };

    function docRef(uid) {
        return {
            get:    () => Promise.resolve({ exists: uid in store, data: () => store[uid] }),
            set:    (d) => { store[uid] = d; return Promise.resolve(); },
            update: (d) => { store[uid] = Object.assign({}, store[uid], d); return Promise.resolve(); },
        };
    }

    window.firebase = {
        initializeApp() {},
        auth: Object.assign(() => auth, { GoogleAuthProvider: function () {} }),
        firestore: Object.assign(() => ({ collection: () => ({ doc: docRef }) }), {
            FieldValue: { serverTimestamp: () => "ts" },
        }),
    };
})();
```

The fake deliberately mirrors real Firebase semantics — same error codes, same
`{ user }` resolution shape, async `onAuthStateChanged` — so a test passing here means
the production wiring is right.

## `tests/frontend/conftest.py`

```python
pytest.importorskip("playwright.sync_api", reason="playwright is not installed")

ROOT = pathlib.Path(__file__).resolve().parents[2]
FAKE_SDK = (pathlib.Path(__file__).parent / "fake_firebase.js").read_text()
FIREBASE_CDN = "**gstatic.com/**"


@pytest.fixture(scope="session")
def base_url():
    """Serve the repo over HTTP so the page's absolute /static paths resolve."""
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(ROOT))
    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)   # port 0 = free port
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    try:
        yield f"http://127.0.0.1:{httpd.server_address[1]}"
    finally:
        httpd.shutdown()


@pytest.fixture(scope="module")
def browser():
    # Module scope, not session: Playwright's sync API keeps an asyncio loop alive
    # in the main thread, which breaks any asyncio.run() elsewhere in the suite.
    with sync_playwright() as pw:
        b = _launch(pw)
        try:
            yield b
        finally:
            b.close()


@pytest.fixture
def page(browser, base_url):
    pg = browser.new_page(viewport={"width": 900, "height": 1000})
    served = {"sdk": False}

    def serve_sdk(route):
        # The page pulls several compat bundles; the first carries the stub and the
        # rest are emptied so nothing overwrites window.firebase.
        body = "" if served["sdk"] else FAKE_SDK
        served["sdk"] = True
        route.fulfill(status=200, content_type="application/javascript", body=body)

    pg.route(FIREBASE_CDN, serve_sdk)

    errors = []
    pg.on("pageerror", lambda e: errors.append(str(e)))

    pg.goto(f"{base_url}/static/index.html")
    pg.wait_for_selector("#auth-modal", state="attached")
    pg.wait_for_timeout(150)   # let onAuthStateChanged settle

    yield pg

    assert not errors, f"uncaught page errors: {errors}"
    pg.close()
```

Each test gets a fresh browser context, so `localStorage` and auth state never leak
between tests.

## Skipping, not failing

The suite must run for someone who hasn't installed Playwright or a browser:

- `pytest.importorskip("playwright.sync_api")` at module import.
- A `_launch()` helper that falls back to any preinstalled Chromium and calls
  `pytest.skip("no Chromium build available for Playwright")` if there is none.
- Declare it as an optional extra, not a hard dependency:

```toml
[project.optional-dependencies]
# playwright drives the browser-based auth tests in tests/frontend/. Those tests
# skip themselves if it (or a Chromium build) is missing, so the rest of the
# suite still runs without it.
dev = ["pytest>=8.0.0", "playwright>=1.40.0"]
```

```bash
pip install -e ".[dev]"
playwright install chromium
pytest tests/frontend
```

## Test checklist

Cover all of these; the parenthetical is what the test drives.

**Modal basics**
- Opens in sign-in mode, confirm field hidden
- Switching to sign-up reveals the confirm field and the hint

**Sign-up**
- Mismatched passwords blocked (no account created in `__fb.users`)
- Too-short password blocked *before* any Firebase call
- Letters-only / digits-only password blocked
- Success signs in and updates the UI
- Duplicate email → "already exists" message

**Sign-in**
- Wrong password → friendly error, and the submit button is restored (not "Please wait…")
- Success updates the UI
- `failNext = "auth/operation-not-allowed"` → message naming the **Email/Password** provider

**Google**
- Success signs in
- `auth/popup-closed-by-user` produces **no** visible error
- `failNext = "auth/operation-not-allowed"` → message naming the **Google** provider

**Password reset**
- Empty email → prompt to enter one, no call made
- Success → notice shown, `__fb.lastReset` is the address
- Unknown address → *identical* notice (no enumeration)

**Password visibility**
- Toggle reveals and re-masks
- Each field toggles independently
- Reopening the modal re-masks and clears both fields

**Sign-out** (the stale-data regression)
- Rendered history is cleared
- Rendered favorites are cleared

**Dismissal** (the dead-backdrop regression)
- Backdrop click dismisses
- `Escape` dismisses
- A click *inside* the card does not dismiss
- Every other modal on the page dismisses the same way

**The gate**
- A gated action while signed out opens the modal
- Skipping auth runs the pending action
- Signing up runs the pending action
- `Escape` runs the pending action

## Forcing an error from a test

```python
def test_provider_disabled_message_names_email_provider(page):
    page.evaluate("window.__fb.failNext = 'auth/operation-not-allowed'")
    page.fill("#auth-email", "a@example.com")
    page.fill("#auth-password", "abcd1234")
    page.click("#auth-submit")
    assert "Email/Password" in page.inner_text("#auth-error")
```

## Seeding an existing account

```python
page.evaluate("window.__fb.users['known@example.com'] = 'abcd1234'")
```
