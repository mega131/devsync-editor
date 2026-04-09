# DevSync — Real-Time Collaborative Code Editor

> A full-stack, production-grade collaborative code editor with live cursors, OT-based sync, AI assistant, and multi-language code execution.

![DevSync](https://img.shields.io/badge/version-6.0-blue) ![Node](https://img.shields.io/badge/node-%3E%3D18-green) ![License](https://img.shields.io/badge/license-ISC-lightgrey)

---

## ✨ Features

| Feature | Details |
|---|---|
| **Real-Time Collaboration** | Operational Transform (OT) engine — no conflicts, like Google Docs |
| **Live Cursors** | See every collaborator's cursor and selections in real-time |
| **Code Execution** | 12 languages: JS, TS, Python, Java, C, C++, Go, Rust, PHP, Ruby, Bash |
| **stdin Support** | Input box for programs that read from stdin (`input()`, `scanf`, etc.) |
| **AI Assistant** | Powered by Claude or GPT (server or client-side key) |
| **GitHub Integration** | Pull and push files directly to any GitHub repository |
| **Version History** | Local snapshot timeline + DB-backed restore |
| **Diff Viewer** | Compare any two history snapshots side-by-side |
| **Snippets** | Save and share code snippets across the room |
| **Live Chat** | @mention, inline code formatting, typing indicators |
| **Room Passwords** | bcrypt-hashed, persisted to PostgreSQL |
| **Analytics** | Keystroke tracking per collaborator |
| **HTML/CSS Preview** | Instant live preview pane for web code |
| **Multi-File Tabs** | Open local files, manage multiple tabs |
| **Export** | Save code as JSON snapshot including history |
| **Auth** | JWT-based sessions with username + room auth |
| **Mobile** | Responsive layout with mobile nav bar |

---

## 🚀 Quick Start

### Option 1 — Double-click (Windows)
```
start.bat
```

### Option 2 — PowerShell
```powershell
.\start.ps1
```

### Option 3 — Manual
```powershell
# Install server deps (first time only)
cd server && npm install && cd ..

# Start the server
node server/index.js
```

Then open: **http://localhost:3000**

---

## 🧪 Test Multi-User Collaboration

Open **two browser tabs** to the same room URL:
```
http://localhost:3000?room=my-project
```
Type in one tab — changes appear instantly in the other.

---

## ⚙️ Configuration (Optional)

Copy the template and edit:
```powershell
Copy-Item server\.env.example server\.env
```

```env
# server/.env

PORT=3000
JWT_SECRET=your-super-secret-key

# PostgreSQL — optional, falls back to in-memory without it
DATABASE_URL=postgresql://postgres:password@localhost:5432/devsync

# AI Assistant — set one to enable server-side AI proxy
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
```

**Without PostgreSQL**: everything works — room history and snippets are in-memory only (lost on restart).

---

## 🐳 Docker Compose (Full Stack with PostgreSQL)

```powershell
docker-compose up --build
```

This starts:
- **DevSync server** on port 3000
- **PostgreSQL 16** database with persistent volume

---

## 📂 Project Structure

```
project4/
├── codesync.html          ← Full frontend (Monaco + OT + Chat + AI + GitHub)
├── socket.io.min.js       ← Bundled Socket.io client
├── monaco/                ← Monaco Editor (VS Code engine)
├── start.bat              ← Windows one-click start
├── start.ps1              ← PowerShell start script
├── docker-compose.yml     ← Full stack with PostgreSQL
├── Dockerfile             ← App container
├── package.json           ← Root scripts
└── server/
    ├── index.js           ← Express + Socket.IO server
    ├── roomManager.js     ← OT engine + room state + DB persistence
    ├── auth.js            ← JWT + bcrypt helpers
    ├── db.js              ← PostgreSQL pool (graceful no-DB fallback)
    ├── migrations.js      ← Idempotent schema setup
    ├── ot.js              ← OT algorithm reference
    ├── package.json       ← Server dependencies
    └── .env.example       ← Config template
```

---

## 🌐 API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/auth/register` | Register user |
| `POST` | `/auth/login` | Login user |
| `POST` | `/auth/check` | Check if room has password |
| `POST` | `/auth/verify` | Verify room password |
| `POST` | `/auth/set-password` | Set/update room password |
| `POST` | `/run` | Execute code (12 languages) |
| `POST` | `/github/repo` | List GitHub repo files |
| `POST` | `/github/file` | Fetch single file content |
| `POST` | `/github/push` | Push file to GitHub |
| `GET`  | `/api/ai/status` | Check if server AI key is set |
| `POST` | `/api/ai` | Server-side AI proxy |
| `GET`  | `/health` | Server health + stats |

---

## 🔌 Socket.IO Events

| Event (client→server) | Description |
|---|---|
| `join-room` | Join a room |
| `operation` | OT operation (insert/delete) |
| `cursor-move` | Cursor position update |
| `typing-start/stop` | Typing indicator |
| `change-language` | Switch editor language |
| `chat-message` | Send chat message |
| `snippet-save/delete` | Manage snippets |
| `get-history` | Load DB version history |
| `restore-version` | Restore a DB snapshot |
| `request-sync` | Request full document sync |

---

## 🔑 AI Assistant

The AI works in two modes (tries server first, falls back to client):

1. **Server-side** (recommended) — Set `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` in `server/.env`
2. **Client-side** — Click **⚙ Key** in the AI panel and paste your Anthropic key

Quick actions: **Explain**, **Fix Bugs**, **Optimize**, **Add Comments**, **Write Tests**, **Convert Language**

---

## ⌨️ Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Ctrl+Enter` | Run code |
| `Ctrl+Shift+P` | Push to room (force sync) |
| `Escape` | Close modal |
| `Enter` | Submit all auth forms |

---

## 📋 Phase Checklist

| Phase | Status |
|---|---|
| Phase 1 — Foundation & UI | ✅ Premium dark UI, Monaco, file tabs, sidebar |
| Phase 2 — Real-Time Collab | ✅ OT, live cursors, typing indicators, chat |
| Phase 3 — Code Execution | ✅ 12 languages, stdin, exit codes, time limits |
| Phase 4 — Auth & Rooms | ✅ Create/join, password protect, share links |
| Phase 5 — DB & Persistence | ✅ PostgreSQL schema, graceful fallback |
| Phase 6 — Docker Sandbox | ✅ docker-compose with PostgreSQL |
| Phase 7 — Polish & Deploy | ✅ Mobile, export, shortcuts, notifications |
