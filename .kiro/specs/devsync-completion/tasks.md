# Implementation Plan

- [x] 1. Set up database module and run migrations on startup



  - Create `server/db.js` exporting a `pg` Pool and a `query(sql, params)` helper
  - Create `server/migrations.js` that creates `users`, `rooms`, `room_snapshots`, and `snippets` tables idempotently
  - Call `runMigrations()` at the top of `server/index.js` before `server.listen()`
  - Add `pg` to `server/package.json` dependencies





  - _Requirements: 4.1, 4.6, 9.2_

- [x] 2. Implement authentication module and routes


- [ ] 2.1 Create `server/auth.js` with JWT and bcrypt helpers
  - Implement `hashPassword`, `verifyPassword`, `signToken`, `verifyToken`, and `authMiddleware`
  - Read `JWT_SECRET` from `process.env`, throw on startup if missing


  - _Requirements: 2.1, 2.2, 2.5, 8.1_

- [ ] 2.2 Add `/auth/register` and `/auth/login` REST endpoints to `server/index.js`
  - `POST /auth/register` — validate input, hash password, insert user, return JWT
  - `POST /auth/login` — look up user, verify password, return JWT or 401










  - _Requirements: 2.1, 2.2, 2.3_







- [ ] 2.3 Add JWT middleware to Socket.io in `server/index.js`
  - Use `io.use()` to read `socket.handshake.auth.token`, call `verifyToken`, attach to `socket.data.user`




  - Guests (no token) are still allowed — middleware calls `next()` regardless
  - _Requirements: 2.4, 2.6, 8.2_

- [ ]* 2.4 Write unit tests for auth helpers
  - Test hash/verify round-trip, signToken/verifyToken, expired token returns null
  - _Requirements: 2.1, 2.2_

- [ ] 3. Extend RoomManager with PostgreSQL persistence
- [ ] 3.1 Add `loadRoom(roomId)` to `RoomManager` that fetches the latest snapshot from DB
  - In `getOrCreate()`, after creating a new Room, call `loadRoom` to hydrate document and version from DB
  - _Requirements: 4.2, 4.6_

- [ ] 3.2 Add `persistRoom(roomId)` and debounced auto-save to `RoomManager`
  - After each `applyOp()` call, schedule a debounced (30s) `persistRoom` that inserts a row into `room_snapshots`
  - _Requirements: 4.1, 4.3_

- [ ] 3.3 Wire version history Socket event to DB snapshots
  - Add `get-history` socket event that queries last 50 `room_snapshots` for a room and emits them back
  - Fix `restoreVersion()` — after restoring, emit a full-document replace operation to all users in the room via the existing OT `operation` event
  - _Requirements: 4.3, 4.4_

- [ ] 4. Add secure AI proxy endpoint
- [ ] 4.1 Add `POST /api/ai` route to `server/index.js`
  - Read `ANTHROPIC_API_KEY` (or `OPENAI_API_KEY`) from `process.env`
  - Forward the user's message + current code context to the AI API and stream/return the response
  - _Requirements: 6.1, 6.5, 8.1_

- [ ] 4.2 Add `GET /api/ai/status` route
  - Returns `{ configured: true/false }` based on whether the API key env var is set
  - _Requirements: 6.5_

- [ ] 5. Extract and harden code executor
- [ ] 5.1 Create `server/executor.js` with `runDirect(code, language)` function
  - Move the existing inline `/run` logic from `server/index.js` into this module
  - Validate `language` against the LANGS allowlist before any exec call
  - _Requirements: 1.2, 1.3, 1.4, 8.3_

- [ ] 5.2 Add `runInDocker(code, language, cfg)` to `server/executor.js`
  - Build a `docker run --rm --network none --memory 128m --cpus 0.5` command
  - Use language-specific Docker images (node:20-alpine, python:3.12-alpine, etc.)
  - On Docker error/unavailability, catch and return `null` so caller falls back
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 5.3 Export `execute(code, language)` from `executor.js` that tries Docker first, falls back to direct
  - Update `/run` route in `server/index.js` to use `executor.execute()`
  - Include `method: "docker"|"direct"` in the response
  - _Requirements: 5.4, 1.2_

- [ ]* 5.4 Write unit tests for executor allowlist and timeout handling
  - Test that unsupported languages return an error without executing
  - Test that the timeout path returns the correct error message
  - _Requirements: 1.3, 1.4, 8.3_

- [ ] 6. Patch frontend for security and bug fixes
- [ ] 6.1 Wire auth overlay to real backend in `codesync.html`
  - On login/register form submit, call `POST /auth/login` or `POST /auth/register`
  - Store the returned JWT in `localStorage` (token only — no secrets)
  - Pass the token in the Socket.io handshake: `io(url, { auth: { token } })`
  - On page load, if a valid token exists, skip the overlay
  - _Requirements: 2.4, 2.5, 2.7_

- [ ] 6.2 Replace direct Anthropic calls with `/api/ai` proxy in `codesync.html`
  - Remove any `localStorage.getItem('anthropic_key')` usage
  - Change the AI send function to `fetch('/api/ai', { method: 'POST', body: JSON.stringify({message, code}) })`
  - On page load, call `GET /api/ai/status` and show a setup message if not configured
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 8.1_

- [ ] 6.3 Fix `restoreVersion()` in `codesync.html` to broadcast to all users
  - After restoring, emit a socket `operation` event that replaces the full document
  - _Requirements: 4.4_

- [ ] 7. Update Docker Compose and environment configuration
- [ ] 7.1 Add PostgreSQL service to `docker-compose.yml`
  - Add `postgres:16-alpine` service with a named volume
  - Set `DATABASE_URL` env var on the `codesync` service pointing to the postgres container
  - Add `depends_on: postgres` with a health check
  - _Requirements: 9.1, 9.2_

- [ ] 7.2 Create `.env.example` with all required environment variables documented
  - Include `JWT_SECRET`, `DATABASE_URL`, `ANTHROPIC_API_KEY`, `PORT`, `NODE_ENV`, `CORS_ORIGIN`
  - Add startup validation in `server/index.js` that logs missing required vars and exits
  - _Requirements: 8.4, 9.4_

- [ ] 7.3 Harden CORS and add rate limiting to `/run` in `server/index.js`
  - Read `CORS_ORIGIN` from env, default to `*` in development only
  - Add `express-rate-limit` middleware on `/run` — max 10 requests per minute per IP
  - _Requirements: 8.5, 9.3_
