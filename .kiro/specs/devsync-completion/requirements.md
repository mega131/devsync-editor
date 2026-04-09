# Requirements Document

## Introduction

DevSync Editor is a real-time collaborative code editor built with Monaco Editor, Socket.io, and Node.js. Phases 1 and 2 are largely complete — the UI shell, Monaco integration, OT engine, room management, and Socket.io server all exist. This spec covers completing Phases 3–7: secure code execution, user authentication, PostgreSQL persistence, Docker sandboxing, and production deployment polish.

The goal is to take the existing working foundation and ship a fully functional, secure, production-ready collaborative IDE.

## Requirements

### Requirement 1 — Code Execution Sandbox (Phase 3)

**User Story:** As a developer, I want to run my code directly in the editor and see output instantly, so that I can test without switching tools.

#### Acceptance Criteria

1. WHEN a user clicks Run, THEN the system SHALL send the current editor content and selected language to the `/run` endpoint.
2. WHEN the server receives a run request, THEN the system SHALL execute the code in an isolated temporary file and return stdout, stderr, and execution time.
3. WHEN execution exceeds 15 seconds, THEN the system SHALL terminate the process and return a timeout error.
4. WHEN the requested language runtime is not installed, THEN the system SHALL return a clear error message indicating which runtime is missing.
5. WHEN execution completes, THEN the system SHALL display stdout in green, stderr in red, and execution time in the output panel.
6. WHEN the language is HTML/CSS, THEN the system SHALL render a live preview in the preview panel instead of executing server-side.
7. WHEN a run is in progress, THEN the Run button SHALL be disabled and show a loading state.

### Requirement 2 — User Authentication (Phase 4)

**User Story:** As a user, I want to register and log in with a username and password, so that my identity is persistent across sessions.

#### Acceptance Criteria

1. WHEN a user submits a registration form with username and password, THEN the system SHALL hash the password with bcrypt and store the user in the database.
2. WHEN a user logs in with valid credentials, THEN the system SHALL return a signed JWT token valid for 7 days.
3. WHEN a user logs in with invalid credentials, THEN the system SHALL return a 401 error with a generic message.
4. WHEN a JWT token is present in localStorage, THEN the system SHALL skip the auth overlay and auto-join the room.
5. WHEN a JWT token is expired or invalid, THEN the system SHALL clear it and show the auth overlay.
6. WHEN a user skips auth, THEN the system SHALL assign a random guest username and allow joining rooms without persistence.
7. WHEN a user is authenticated, THEN their username and color SHALL be persisted and consistent across sessions.

### Requirement 3 — Room Management & Invite System (Phase 4)

**User Story:** As a room owner, I want to create rooms with optional passwords and share invite links, so that I can control who joins my session.

#### Acceptance Criteria

1. WHEN a user creates a room, THEN the system SHALL generate a unique room ID and optionally store a hashed password.
2. WHEN a room has a password set, THEN the system SHALL verify the password server-side before allowing a socket join.
3. WHEN a user clicks Share, THEN the system SHALL copy a URL with the room ID as a query parameter to the clipboard.
4. WHEN a user opens an invite link, THEN the system SHALL auto-populate the room ID and prompt for a password if required.
5. WHEN a room owner sets a password via the UI, THEN the system SHALL persist it server-side (not just in memory for the session).

### Requirement 4 — PostgreSQL Persistence (Phase 5)

**User Story:** As a developer, I want my code sessions and version history to be saved, so that I can resume work after closing the browser.

#### Acceptance Criteria

1. WHEN a room's document changes, THEN the system SHALL persist the latest document state to PostgreSQL every 30 seconds (debounced).
2. WHEN a user joins a room that has a saved state, THEN the system SHALL load the persisted document from the database.
3. WHEN a user views version history, THEN the system SHALL display the last 50 saved snapshots with timestamps and author info.
4. WHEN a user clicks Restore on a history entry, THEN the system SHALL broadcast the restored document to all users in the room via OT.
5. WHEN a user saves a named snippet, THEN the system SHALL persist it to the database linked to their user account.
6. WHEN the server restarts, THEN active room state SHALL be recoverable from the database.

### Requirement 5 — Docker Sandboxing (Phase 6)

**User Story:** As a platform operator, I want code execution to be isolated in Docker containers, so that malicious code cannot affect the host system.

#### Acceptance Criteria

1. WHEN code is submitted for execution, THEN the system SHALL run it inside a Docker container with no network access.
2. WHEN a Docker container is created for execution, THEN the system SHALL enforce a 128MB memory limit and 1 CPU limit.
3. WHEN execution completes or times out, THEN the system SHALL automatically remove the container.
4. WHEN Docker is not available, THEN the system SHALL fall back to the direct execution method with a warning in the output.
5. WHEN a container is running, THEN the system SHALL prevent filesystem writes outside of /tmp.

### Requirement 6 — AI Assistant Integration (Phase 3/4)

**User Story:** As a developer, I want an AI assistant that can explain, fix, and generate code in context, so that I can get help without leaving the editor.

#### Acceptance Criteria

1. WHEN a user sends a message in the AI panel, THEN the system SHALL proxy the request through the server to the AI API (never expose the API key in the browser).
2. WHEN the AI responds, THEN the system SHALL render markdown including code blocks with syntax highlighting.
3. WHEN a user clicks a quick-action chip (Explain, Fix Bug, etc.), THEN the system SHALL pre-fill the AI prompt with the current editor selection or full code.
4. WHEN the AI returns a code block, THEN the system SHALL show an "Insert into Editor" button next to it.
5. WHEN the server has no AI API key configured, THEN the system SHALL display a clear setup message instead of a cryptic error.

### Requirement 7 — GitHub Integration (Phase 4)

**User Story:** As a developer, I want to load files from GitHub and push changes back, so that I can use the editor as part of my Git workflow.

#### Acceptance Criteria

1. WHEN a user provides a GitHub token, owner, and repo, THEN the system SHALL proxy the request server-side and list repository files.
2. WHEN a user selects a file from the GitHub panel, THEN the system SHALL load its content into the active editor tab.
3. WHEN a user clicks Push, THEN the system SHALL commit the current file content to GitHub via the API.
4. WHEN a GitHub API call fails, THEN the system SHALL display the error message in the GitHub panel.
5. WHEN a GitHub token is stored, THEN it SHALL be stored server-side in the session, not in browser localStorage.

### Requirement 8 — Security Hardening

**User Story:** As a platform operator, I want the application to be secure by default, so that user data and the host system are protected.

#### Acceptance Criteria

1. WHEN any API key (Anthropic, GitHub) is used, THEN it SHALL only exist in server-side environment variables, never sent to the browser.
2. WHEN a user joins a room, THEN the server SHALL validate their JWT before allowing socket operations.
3. WHEN code is executed, THEN the system SHALL sanitize the language parameter against an allowlist before running any shell command.
4. WHEN the server starts, THEN it SHALL read configuration from environment variables with documented defaults.
5. WHEN CORS is configured, THEN the system SHALL restrict allowed origins to the configured frontend URL in production.

### Requirement 9 — Production Deployment (Phase 7)

**User Story:** As a developer, I want to deploy the full stack with a single command, so that I can share the editor publicly.

#### Acceptance Criteria

1. WHEN `docker-compose up` is run, THEN the system SHALL start the Node.js server and PostgreSQL database together.
2. WHEN the application starts, THEN it SHALL run database migrations automatically.
3. WHEN the server is behind a reverse proxy, THEN Socket.io SHALL work correctly with sticky sessions or the configured adapter.
4. WHEN environment variables are missing, THEN the server SHALL log clear startup errors and exit gracefully.
5. WHEN the application is deployed, THEN a `/health` endpoint SHALL return server status, room count, and user count.
