# Design Document — DevSync Editor Completion

## Overview

DevSync is a browser-based collaborative code editor. The existing codebase has a solid Phase 1/2 foundation: Monaco Editor frontend in a single HTML file (`codesync.html`), a Node.js/Express/Socket.io server (`server/index.js`), an OT engine (`server/ot.js`), and in-memory room management (`server/roomManager.js`).

This design covers the incremental additions needed to complete Phases 3–7 without rewriting what already works. The strategy is **additive** — new files and modules are added alongside existing ones, and the existing `codesync.html` frontend is patched to use secure server-side proxies instead of direct API calls.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  Browser (codesync.html)                                            │
│  ├── Monaco Editor + OT Client                                      │
│  ├── Socket.io Client                                               │
│  ├── Auth UI (JWT stored in localStorage — token only, no secrets)  │
│  └── AI / GitHub panels (proxy calls to /api/*)                     │
└────────────────────────┬────────────────────────────────────────────┘
                         │ HTTP + WebSocket
┌────────────────────────▼────────────────────────────────────────────┐
│  Node.js Server (server/index.js — extended)                        │
│  ├── Express REST                                                   │
│  │   ├── POST /auth/register  POST /auth/login                      │
│  │   ├── POST /run            (code execution)                      │
│  │   ├── POST /api/ai         (AI proxy — key in env)               │
│  │   ├── POST /github/*       (GitHub proxy — token in session)     │
│  │   └── GET  /health                                               │
│  ├── Socket.io (existing events + JWT middleware)                   │
│  ├── server/auth.js           (JWT + bcrypt helpers)                │
│  ├── server/db.js             (PostgreSQL pool via pg)              │
│  ├── server/migrations.js     (auto-run on startup)                 │
│  ├── server/executor.js       (Docker-first, fallback direct exec)  │
│  └── server/roomManager.js    (extended: DB persistence)            │
└────────────────────────┬────────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────────┐
│  PostgreSQL (via docker-compose or external)                        │
│  ├── users                                                          │
│  ├── rooms                                                          │
│  ├── room_snapshots  (version history)                              │
│  └── snippets                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Components and Interfaces

### 1. `server/auth.js` — Authentication Module

Handles JWT signing/verification and bcrypt password hashing.

```js
// Exports:
hashPassword(plain)           → Promise<hash>
verifyPassword(plain, hash)   → Promise<boolean>
signToken(payload)            → string          // JWT, 7d expiry
verifyToken(token)            → payload | null
authMiddleware(req, res, next) // Express middleware — sets req.user
```

Environment variables: `JWT_SECRET` (required), `BCRYPT_ROUNDS` (default 10).

### 2. `server/db.js` — Database Module

Thin wrapper around `pg` Pool. Exports a `query(sql, params)` helper and the pool itself.

```js
query(text, params) → Promise<Result>
pool                → pg.Pool
```

Environment variables: `DATABASE_URL` or individual `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`.

### 3. `server/migrations.js` — Schema Migrations

Runs on server startup. Creates tables if they don't exist (idempotent).

Tables:
- `users(id, username, password_hash, color, created_at)`
- `rooms(id, name, password_hash, owner_id, created_at, last_active)`
- `room_snapshots(id, room_id, document, version, saved_by, created_at)`
- `snippets(id, user_id, room_id, name, language, code, created_at)`

### 4. `server/executor.js` — Code Execution

Replaces the inline `/run` handler in `index.js`. Tries Docker first, falls back to direct `child_process.exec`.

```js
// Docker execution
runInDocker(code, language, cfg) → Promise<{stdout, stderr, ms}>

// Direct execution (existing logic, extracted)
runDirect(code, language, cfg)   → Promise<{stdout, stderr, ms}>

// Main export — tries Docker, falls back
execute(code, language)          → Promise<{stdout, stderr, ms, method}>
```

Docker config per execution:
- Image: `node:20-alpine` for JS/TS, `python:3.12-alpine` for Python, etc.
- `--network none` — no internet access
- `--memory 128m --cpus 0.5`
- `--rm` — auto-remove on exit
- Timeout: 15s via `--stop-timeout`

### 5. Extended `server/index.js`

New routes added to the existing file:

```
POST /auth/register   → auth.js + db.js
POST /auth/login      → auth.js + db.js
POST /api/ai          → proxies to Anthropic/OpenAI using server env key
GET  /api/ai/status   → returns whether AI is configured
```

Socket.io middleware added:
```js
io.use((socket, next) => {
  const token = socket.handshake.auth.token;
  if (token) socket.data.user = verifyToken(token);
  next(); // guests allowed, token optional
});
```

### 6. Extended `server/roomManager.js`

Added DB persistence:
- `persistRoom(roomId)` — saves current document + version to `room_snapshots`
- `loadRoom(roomId)` — loads latest snapshot from DB on first access
- Auto-persist debounced every 30s when document changes

### 7. Frontend patches in `codesync.html`

The following changes are made to the existing single-file frontend:

| Current (broken/insecure) | Fixed |
|---|---|
| `localStorage.getItem('anthropic_key')` sent directly to Anthropic | `fetch('/api/ai', {body: {message}})` — key stays on server |
| GitHub token in `localStorage` sent directly to GitHub API | `fetch('/github/repo', {body: {token}})` — already proxied, just remove localStorage exposure |
| Auth overlay is purely cosmetic | On login/register, call `/auth/login` or `/auth/register`, store JWT, pass token in socket handshake |
| `restoreVersion()` only sets local editor | After restore, emit an `operation` that replaces the full document for all users |

---

## Data Models

### User
```json
{
  "id": "uuid",
  "username": "string (unique)",
  "password_hash": "string (bcrypt)",
  "color": "string (hex)",
  "created_at": "timestamp"
}
```

### Room
```json
{
  "id": "string (nanoid)",
  "password_hash": "string | null",
  "owner_id": "uuid | null",
  "created_at": "timestamp",
  "last_active": "timestamp"
}
```

### RoomSnapshot
```json
{
  "id": "serial",
  "room_id": "string",
  "document": "text",
  "version": "integer",
  "saved_by": "string (username)",
  "created_at": "timestamp"
}
```

### Snippet
```json
{
  "id": "serial",
  "user_id": "uuid | null",
  "room_id": "string",
  "name": "string",
  "language": "string",
  "code": "text",
  "created_at": "timestamp"
}
```

---

## Error Handling

| Scenario | Handling |
|---|---|
| DB connection fails on startup | Log error, exit with code 1 (fail fast) |
| DB query fails at runtime | Log error, return 500 with generic message |
| JWT missing/invalid on protected route | Return 401 |
| Code execution timeout | Kill process/container, return `{stderr: "⏱ Timeout after 15s"}` |
| Docker not available | Log warning, fall back to direct exec, include `method: "direct"` in response |
| AI API key not set | `/api/ai/status` returns `{configured: false}`, frontend shows setup message |
| Language not in allowlist | Return `{stderr: "Language not supported"}` without executing anything |
| Room password wrong | Socket emits `auth-error` event, client shows modal error |

---

## Testing Strategy

- Unit tests for `auth.js` (hash/verify/sign/verify token)
- Unit tests for `executor.js` (language allowlist, timeout handling)
- Unit tests for OT engine `ot.js` (transform, compose, apply — already has solid logic)
- Integration test: register → login → join room → send operation → verify document state
- Integration test: submit JS code to `/run` → verify stdout matches expected output
- Manual smoke test checklist for Docker sandboxing

---

## Phased Implementation Order

1. **DB + Auth** — `db.js`, `migrations.js`, `auth.js`, auth routes, socket JWT middleware
2. **Persistence** — extend `roomManager.js` to load/save from DB
3. **Secure AI proxy** — `/api/ai` route, patch frontend to use it
4. **Executor module** — extract `/run` logic, add Docker path
5. **Frontend patches** — fix `restoreVersion`, remove localStorage secrets, wire auth
6. **Docker Compose** — add PostgreSQL service, env vars, health check
7. **Security sweep** — CORS config, input validation, rate limiting on `/run`
