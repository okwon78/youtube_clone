# CLAUDE.md

This is the Flutter client (LIVO) for a video-app prototype project.

## Backend server

The backend server lives in a **separate directory**, not inside this Flutter project:

- Path (relative to this Flutter app): `../server`
- Absolute path: `/Users/obiwan/Dev/flutter-tutorial/server`

It is a **JWT learning server (Go + Gin + PostgreSQL + Redis)** sitting behind an
**Nginx API gateway** — two separated Go modules fronted by a single entry point:

- `gateway/` — **Nginx API gateway (port 8080)**, the client's *only* host-exposed
  entry point. Auth/token endpoints (`/login`, `/register`, `/auth/*`, `/oauth/*`,
  `/email/*`, `/consents/*`, `/users/username`) it proxies straight to `auth`
  without a check. Protected livo endpoints (`/protected`, `/me/*`) it first
  validates via an `auth_request` subrequest to `auth`'s `GET /validate`; on `200`
  it captures `X-User-Id` and forwards the request to `livo` (overwriting any
  client-sent `X-User-Id` to block forgery), on `401` it rejects immediately.
- `auth/` — Authorization Server (container port 8081, **not host-exposed**, only
  behind the gateway). Verifies email/password & social logins (bcrypt), then
  issues our own **JWT access token (stateless, HS256, 1h)** + **opaque refresh
  token (DB-stored as SHA-256 hash, 14d, rotated on refresh)**. Also serves the
  gateway's `GET /validate` (local HS256 signature/expiry check → `X-User-Id`).
  The only service that talks to PostgreSQL and Redis.
- `livo/` — Resource Server (container port 8080, **not host-exposed**, only behind
  the gateway). **No longer validates JWTs and doesn't know `JWT_SECRET`** — the
  gateway centralizes token validation and passes the trusted owner `user_id` in
  the **`X-User-Id` header**, which `livo` reads (rejecting requests without it, so
  it can't be hit directly). No DB, no Redis.
- PostgreSQL — user/refresh-token storage (auth only), run via `docker-compose.yml`.
- Redis — **TTL-expiring temporary data** for email verification (auth only).

The Flutter client sends **all** traffic to the gateway (port 8080): both
`AUTH_BASE_URL` (`lib/services/auth_api.dart`) and `LIVO_BASE_URL`
(`lib/services/livo_api.dart`) default to `:8080`. The gateway routes login
requests to `auth` and validated, protected API calls to `livo`.

Note the historical OAuth2 machinery (auth codes, token introspection, the `api/`
module name, `client_id`/`client_secret`, `oauth_clients`) has been **removed** —
this is now a single 1st-party app talking to a self-issued JWT server.

See `../server/CLAUDE.md` and `../server/README.md` for server details.

## Display name (username) — login → profile

The server distinguishes two identities: `user_id` is the numeric primary key and
the **email** is the login identifier, while **`username`** is the human-facing
display name (generated at signup as `<email-local-part><4 random digits>`, e.g.
`okwon784456`; user-changeable via `PATCH /users/username`). The profile/home/shell
UI must show `username`, never the email.

Wiring (server flows all converge on `respondWithToken`):

- The auth server's token responses (`/login`, `/auth/refresh`, `/oauth/google`,
  `/oauth/naver`) include a **`username`** field alongside `user_id`.
- `lib/services/auth_api.dart` — `_requestTokens` parses `username` into
  `AuthResult.username` (null only if the server omits it).
- `lib/providers/auth_controller.dart` — `_completeLogin` stores
  `result.username ?? fallbackName` into `AuthState.username` and persists it via
  `TokenStorage`. The `fallbackName` (login email / social display name) is used
  only when the server sends no username.
- UI reads `authControllerProvider.select((s) => s.username)`:
  `lib/pages/livo/profile_page.dart`, `lib/pages/livo/livo_shell.dart`,
  `lib/pages/home_page.dart`.

Gotcha: an already-signed-in session keeps whatever name was persisted at login,
so a server-side change to the username flow only takes effect after re-login.

## Email signup — verification code

`lib/pages/livo/signup_pages.dart` (`SignupEmailPage`, a `ConsumerStatefulWidget`)
drives email-based signup. The email-ownership step is wired to the auth server's
two email-verification endpoints:

- `POST /email/verification` `{email}` → `{sent, expires_in}` — sends/stores a
  6-digit code (Redis, 8-min TTL; learning-mode code is always `123456`).
- `POST /email/verification/confirm` `{email, code}` → `{verified}` — consumes the
  code and flags the email verified (~30 min). 400 `code_mismatch` / `code_expired`.

Client wiring:

- `lib/services/auth_api.dart` (`AuthApi`) exposes `requestEmailVerification(email)`
  (returns `expires_in`) and `confirmEmailVerification(email, code)` (maps the
  server's `code_mismatch`/`code_expired` to Korean `AuthApiException` messages).
- `_sendCode()` calls the request endpoint and drives the countdown from the
  server's `expires_in`; `_VerifyButton` shows a busy spinner via `_sending`.
- The code field's `trailing` holds the timer + a **"확인" (confirm) button**
  (`_CodeConfirmButton`, enabled via `_canVerifyCode`). `_verifyCode()` calls the
  confirm endpoint and sets `_codeVerified` only on success; once verified the
  trailing shows a `_CodeVerifiedBadge` ("✓ 인증 완료"). Editing the code or
  re-sending resets `_codeVerified`.
- Gating: `_valid` (the "가입 완료하기" button) requires `_codeVerified` plus a
  valid email, password rules, and the required consents (`_consentsOk`).
- `_submit()` is real: it calls `authController.register(email, password,
  agreedAge14/Terms/Privacy/Marketing)`, which `POST`s to `/register` and then
  logs the user in with the same credentials. On success it pops `true`; an
  `AuthApiException` (e.g. duplicate email → 409) surfaces the server message and
  leaves the form intact.

## Signup consents — collection → storage

The server's `POST /register` records four consent booleans on the new account:
`agreed_age14`, `agreed_terms`, `agreed_privacy` (required) and `agreed_marketing`
(optional). The server only **records** them — the required-consent gating is the
client's job.

- `lib/services/auth_api.dart` — `register(...)` sends the four `agreed_*` flags in
  the `/register` body. The consent item definitions (label, required, version)
  live here and are also fetched/used by the signup UI.
- `lib/pages/livo/signup_pages.dart` — `_consentChecked` holds the user's choices;
  `_consentsOk` gates the submit button on the required ones; `_submit()` forwards
  them through `authController.register`.
- Gotcha: social logins (`/oauth/google`, `/oauth/naver`) auto-create the account
  **without** going through `/register`, so consent choices aren't recorded
  server-side for social accounts (see the comment near `signup_pages.dart:335`).

## Logout — server-side refresh-token revocation

Because the access token is a stateless JWT (valid until it expires), logout's job
is to revoke the **refresh token** so the session can't be renewed.

- `lib/services/auth_api.dart` — `logout(refreshToken)` `POST`s to `/auth/logout`.
  It's **best-effort**: network/server errors are swallowed so a failed call never
  blocks the local sign-out.
- `lib/providers/auth_controller.dart` — `logout()` revokes the refresh token
  server-side, signs out of the social provider (`_social.signOut()`), clears
  `TokenStorage`, and resets `AuthState`. Triggered from the home menu
  (`lib/pages/home_page.dart`).
