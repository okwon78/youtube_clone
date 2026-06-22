# CLAUDE.md

This is the Flutter client for a YouTube clone tutorial project.

## Backend server

The backend server lives in a **separate directory**, not inside this Flutter project:

- Path (relative to this Flutter app): `../../../server`
- Absolute path: `/Users/obiwan/Dev/flutter-tutorial/server`

It is an **OAuth2 learning server (Go + Gin + PostgreSQL)** with two separated Go modules:

- `auth/` — Authorization Server (issues/validates auth codes & access tokens, token introspection; the only service that talks to the DB).
- `api/` — Resource Server (protects endpoints with Bearer tokens, validates them via the auth server's introspection endpoint).
- PostgreSQL — user/client/token storage, run via `docker-compose.yml`.

See `../../../server/CLAUDE.md` and `../../../server/README.md` for server details.
