# CodeSync — Phase 2: Real-Time Collaboration Engine

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PHASE 2 STACK                            │
├─────────────────────────────────────────────────────────────────┤
│  Client (Browser)                                               │
│  ├── Monaco Editor (VS Code engine)                             │
│  ├── OT Client Engine (transform + apply operations)            │
│  ├── Socket.IO Client (WebSocket transport)                     │
│  └── Cursor Overlay (real-time remote cursor rendering)         │
│                                                                 │
│  Server (Node.js)                                               │
│  ├── Express HTTP (REST endpoints)                              │
│  ├── Socket.IO Server (WebSocket events)                        │
│  ├── OT Engine — ot.js (Operation, transform, compose, apply)  │
│  └── RoomManager (in-memory state, user sessions, history)     │
└─────────────────────────────────────────────────────────────────┘
```

## OT Event Flow

```
User A types "hello"          User B types "world"
       │                              │
       ▼                              ▼
  opFromDiff()               opFromDiff()
  {insert:"hello"}           {insert:"world"}
       │                              │
       ▼                              ▼
  socket.emit('operation')   socket.emit('operation')
       │                              │
       └──────────► SERVER ◄──────────┘
                      │
              applyOperation()
              OT.transform(a, b)
                      │
             ┌────────┴────────┐
             ▼                 ▼
        ack to A          remote-op to B
        (version++)       (transformed op)
             │                 │
             ▼                 ▼
        pendingOps.shift()  applyOp(doc, transformed)
        updateSyncBadge()   renderCursors()
```

## Setup

### 1. Install server dependencies
```bash
cd server
npm install
```

### 2. Start the server
```bash
npm run dev
# Server runs on http://localhost:3000
```

### 3. Open the client
Open `collaborative-editor-phase2.html` in your browser.
Add `?room=my-room-name` to the URL to join a specific room.

### 4. Test collaboration
Open the same URL in multiple browser tabs/windows to test live collaboration!

## Socket Events Reference

### Client → Server
| Event | Payload | Description |
|-------|---------|-------------|
| `join-room` | `{roomId, userId, username, color}` | Join or create a room |
| `operation` | `{roomId, ops, baseLength, targetLength, clientVersion}` | Send OT operation |
| `cursor-move` | `{roomId, cursor: {line, column, offset}}` | Broadcast cursor position |
| `typing-start` | `{roomId}` | Show typing indicator |
| `typing-stop` | `{roomId}` | Hide typing indicator |
| `change-language` | `{roomId, language}` | Change editor language |
| `chat-message` | `{roomId, text}` | Send chat message |
| `request-sync` | `{roomId}` | Request full document sync |

### Server → Client
| Event | Payload | Description |
|-------|---------|-------------|
| `room-state` | `{document, version, language, users, cursors}` | Full room snapshot on join |
| `user-joined` | `{userId, username, color, cursor}` | New user notification |
| `user-left` | `{userId, username}` | User disconnect |
| `ack` | `{version}` | Operation acknowledged |
| `remote-operation` | `{ops, version, userId, username}` | Transformed op from another user |
| `remote-cursor` | `{userId, line, column, color, username}` | Cursor position update |
| `language-changed` | `{language, changedBy}` | Language change broadcast |
| `chat-message` | `{userId, username, color, text, timestamp}` | Chat message |
| `full-sync` | `{document, version}` | Full resync (OT conflict recovery) |

## File Structure
```
codesync/
├── server/
│   ├── index.js          ← Express + Socket.IO server
│   ├── ot.js             ← Operational Transformation engine
│   ├── roomManager.js    ← Room state & session management
│   └── package.json
└── client/
    └── phase2.html       ← Complete client (no bundler needed)
```

## Phase Roadmap

- [x] **Phase 1** — Monaco Editor UI, file tabs, syntax highlighting
- [x] **Phase 2** — Socket.IO, Operational Transformation, live cursors, chat
- [ ] **Phase 3** — Code execution sandbox (Node.js + language support)
- [ ] **Phase 4** — Auth, rooms, invite system (JWT + bcrypt)
- [ ] **Phase 5** — PostgreSQL persistence (sessions, history, files)
- [ ] **Phase 6** — Docker sandboxing (isolated code execution)
- [ ] **Phase 7** — Polish, performance, deployment (Railway/Fly.io)
