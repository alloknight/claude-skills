# Sign-in modal — UI patterns

One card handles both sign-in and sign-up. A `authMode` variable ("signin" | "signup")
drives every label, the confirm field, the hint, and the "Forgot password?" link. Don't
build two modals.

## Markup skeleton

```html
<div class="auth-modal" id="auth-modal" style="display:none">
  <div class="auth-card">
    <div class="auth-icon"><img src="/static/logo.png" alt=""></div>
    <h2 id="auth-title">Sign in</h2>
    <p id="auth-subtitle">Save your history and favorites across devices.</p>

    <button type="button" id="google-sign-in-btn" class="btn-modal-sign-in">
      <svg class="google-icon" viewBox="0 0 24 24"><!-- 4-colour G --></svg>
      Continue with Google
    </button>

    <div class="auth-divider"><span>or</span></div>

    <form id="auth-form" class="auth-form" novalidate>
      <div class="auth-field">
        <label for="auth-email">Email</label>
        <input type="email" id="auth-email" autocomplete="email"
               placeholder="you@example.com" required>
      </div>

      <div class="auth-field">
        <div class="auth-label-row">
          <label for="auth-password">Password</label>
          <button type="button" id="forgot-password-btn" class="auth-link-btn">Forgot password?</button>
        </div>
        <div class="auth-input-wrap">
          <input type="password" id="auth-password" autocomplete="current-password" required>
          <button type="button" class="pw-toggle" data-toggle-for="auth-password"
                  aria-label="Show password" aria-pressed="false">
            <svg class="eye-open" …></svg><svg class="eye-closed" …></svg>
          </button>
        </div>
        <div class="pw-strength" id="pw-strength" style="display:none">
          <div class="pw-strength-track"><span class="pw-strength-fill" id="pw-strength-fill"></span></div>
          <span class="pw-strength-label" id="pw-strength-label"></span>
        </div>
        <div class="pw-hint" id="pw-hint" style="display:none">At least 8 characters, including letters and numbers.</div>
      </div>

      <div class="auth-field" id="confirm-field" style="display:none">
        <label for="auth-password-confirm">Confirm password</label>
        <div class="auth-input-wrap">
          <input type="password" id="auth-password-confirm" autocomplete="new-password">
          <button type="button" class="pw-toggle" data-toggle-for="auth-password-confirm"
                  aria-label="Show password" aria-pressed="false"><!-- eyes --></button>
        </div>
        <div class="pw-match" id="pw-match" style="display:none"></div>
      </div>

      <div class="auth-error"  id="auth-error"  style="display:none"></div>
      <div class="auth-notice" id="auth-notice" style="display:none"></div>
      <button type="submit" class="btn-auth-submit" id="auth-submit">Sign in</button>
    </form>

    <p class="auth-switch">
      <span id="auth-switch-text">Don't have an account?</span>
      <button type="button" id="auth-switch-btn" class="auth-link-btn">Sign up</button>
    </p>
    <button type="button" id="skip-auth-btn" class="btn-skip-auth">Continue without signing in</button>
  </div>
</div>
```

`novalidate` on the form is deliberate: the browser's native bubble can't be styled and
fires before the custom policy check. Validate in JS and render into `#auth-error`.

Drop `#skip-auth-btn` if the intake said sign-in is a hard gate.

## Mode switching

```js
function setAuthMode(mode) {
    authMode = mode === "signup" ? "signup" : "signin";
    const signup = authMode === "signup";
    authTitle.textContent  = signup ? "Create your account" : "Sign in";
    authSubmit.textContent = signup ? "Create account" : "Sign in";
    authPassword.setAttribute("autocomplete", signup ? "new-password" : "current-password");
    confirmField.style.display       = signup ? "flex" : "none";
    pwHint.style.display             = signup ? "block" : "none";
    forgotPasswordBtn.style.display  = signup ? "none" : "inline";
    authSwitchText.textContent = signup ? "Already have an account?" : "Don't have an account?";
    authSwitchBtn.textContent  = signup ? "Sign in" : "Sign up";
    authPasswordConfirm.value = "";
    hideAuthError(); hideAuthNotice();
    updatePwStrength(); updatePwMatch();
}
```

The `autocomplete` swap matters — it's what makes password managers offer "save new
password" on sign-up and "fill" on sign-in.

## Password policy, strength, and match

Policy is enforced *before* calling Firebase, so a rejected password costs no round trip
and gives a specific message. Firebase's own floor is 6 characters, which is too low.

```js
const MIN_PASSWORD_LENGTH = 8;

function passwordMeetsPolicy(pw) {
    return pw.length >= MIN_PASSWORD_LENGTH && /[A-Za-z]/.test(pw) && /\d/.test(pw);
}

// Length + character-class variety. Advisory only — the meter never blocks.
function evaluatePassword(pw) {
    let score = 0;
    if (pw.length >= MIN_PASSWORD_LENGTH) score++;
    if (pw.length >= 12) score++;
    if (/[a-z]/.test(pw) && /[A-Z]/.test(pw)) score++;
    if (/\d/.test(pw)) score++;
    if (/[^A-Za-z0-9]/.test(pw)) score++;
    if (score >= 4) return { score, label: "Strong", cls: "strong" };
    if (score >= 2) return { score, label: "Fair",   cls: "fair" };
    return { score, label: "Weak", cls: "weak" };
}
```

The meter and the match indicator only render in sign-up mode and only once the field is
non-empty. Match feedback is live on every keystroke of *either* field:

```js
function updatePwMatch() {
    if (authMode !== "signup" || !authPasswordConfirm.value) { pwMatch.style.display = "none"; return; }
    const matches = authPassword.value === authPasswordConfirm.value;
    pwMatch.style.display = "block";
    pwMatch.textContent = matches ? "✓ Passwords match" : "✗ Passwords don't match";
    pwMatch.className = `pw-match ${matches ? "ok" : "bad"}`;
}

authPassword.addEventListener("input", () => { updatePwStrength(); updatePwMatch(); });
authPasswordConfirm.addEventListener("input", updatePwMatch);
```

## Show/hide password

One delegated handler covers every field. Each toggle owns only its own input, via
`data-toggle-for`, so revealing the password doesn't reveal the confirmation.

```js
document.querySelectorAll(".pw-toggle").forEach((btn) => {
    const input = document.getElementById(btn.dataset.toggleFor);
    if (!input) return;
    btn.addEventListener("click", () => {
        const reveal = input.type === "password";
        input.type = reveal ? "text" : "password";
        btn.classList.toggle("revealed", reveal);
        btn.setAttribute("aria-pressed", String(reveal));
        btn.setAttribute("aria-label", reveal ? "Hide password" : "Show password");
    });
});

// Called from resetAuthForm(): a revealed password must never survive a modal close.
function maskPasswordFields() {
    document.querySelectorAll(".pw-toggle").forEach((btn) => {
        const input = document.getElementById(btn.dataset.toggleFor);
        if (input) input.type = "password";
        btn.classList.remove("revealed");
        btn.setAttribute("aria-pressed", "false");
        btn.setAttribute("aria-label", "Show password");
    });
}
```

CSS shows one of the two eye SVGs based on `.revealed`, so there's no icon swapping in JS:

```css
.pw-toggle .eye-closed,          .pw-toggle.revealed .eye-open   { display: none; }
.pw-toggle.revealed .eye-closed, .pw-toggle .eye-open            { display: block; }
```

## Error vs. notice

Two channels, mutually exclusive — showing one hides the other. Errors are red and mean
"you must fix something"; notices are neutral and mean "we did a thing" (reset email
sent). Never leave both on screen.

```js
function showAuthError(msg)  { authError.textContent = msg;  authError.style.display = "block";  hideAuthNotice(); }
function showAuthNotice(msg) { authNotice.textContent = msg; authNotice.style.display = "block"; hideAuthError(); }
```

## Submit flow

```js
authForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    hideAuthError();
    const email = authEmail.value.trim();
    const password = authPassword.value;
    if (!email)    { showAuthError("Please enter your email.");    return; }
    if (!password) { showAuthError("Please enter your password."); return; }
    if (authMode === "signup") {
        if (!passwordMeetsPolicy(password)) {
            showAuthError(`Password must be at least ${MIN_PASSWORD_LENGTH} characters and include both letters and numbers.`);
            return;
        }
        if (password !== authPasswordConfirm.value) {
            showAuthError("Passwords don't match. Please re-enter them.");
            authPasswordConfirm.focus();
            return;
        }
    }
    setAuthLoading(true);                       // disable submit, "Please wait…"
    try {
        if (authMode === "signup") await signUpWithEmail(email, password);
        else                       await signInWithEmail(email, password);
        hideAuthModal();
        resetAuthForm();
        runPendingAction();                     // the thing they were trying to do
    } catch (err) {
        showAuthError(friendlyAuthError(err, "email"));
    } finally {
        setAuthLoading(false);                  // always restore, even on failure
    }
});
```

`finally` is load-bearing: a failed sign-in that leaves the button stuck on "Please wait…"
looks like a hang.

## Dismissal and the pending action

A soft gate that interrupts an action must resume that action on dismissal — otherwise
the visitor's click was silently swallowed.

```js
function dismissAuthModal() {
    hideAuthModal();
    if (pendingGeneration) { doGenerate(pendingGeneration); pendingGeneration = null; }
}
```

Three dismissal paths, all required: the "Continue without signing in" button, a backdrop
click, and `Escape`.

```js
// `.auth-modal` covers the viewport and sits above `.auth-overlay`, so the backdrop
// click has to be caught on the modal itself — a click landing on the container
// rather than the card is a click outside the dialog.
authModal.addEventListener("click", (e) => { if (e.target === authModal) dismissAuthModal(); });
authOverlay.addEventListener("click", dismissAuthModal);

document.addEventListener("keydown", (e) => {
    if (e.key !== "Escape") return;
    if (authModalOpen()) dismissAuthModal();
    else if (upgradeModalOpen()) hideUpgradeModal();
});
```

That stacking caveat is the single most common bug here: an overlay-only click handler
appears to work in review and does nothing in the browser, because the modal container
is what actually receives the click. If the page has other modals, they need the same
treatment — fix them all at once.

## Opening and resetting

```js
function showAuthModal() {
    resetAuthForm();                 // clears fields, errors, notices; re-masks passwords
    setAuthMode("signin");           // always open in sign-in mode
    authModal.style.display = "flex";
    authOverlay.style.display = "block";
    setTimeout(() => authEmail.focus(), 50);   // after the display flip
}
```

## Accessibility

- `aria-pressed` + a changing `aria-label` on each eye toggle.
- `aria-hidden="true"` on decorative SVGs; `alt=""` on the logo.
- `role="dialog"` + `aria-modal="true"` + `aria-labelledby="auth-title"` on the card.
- Focus the email field on open; return focus to the trigger button on close.
- Errors in a `role="alert"` container so screen readers announce them.
- The submit button must stay reachable by keyboard when the confirm field appears.
