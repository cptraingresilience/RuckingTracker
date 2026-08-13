# RuckingTracker

RuckingTracker — RuckingTracker app with backend built in (desktop)

A desktop application for tracking rucks (ruck marches / weighted walks), logging sessions, viewing historical statistics, and exporting or syncing data. The app is built primarily in Swift (desktop client) with a built-in backend component (JavaScript) to provide local API services and persistence.

> NOTE: This README is a detailed draft. Please replace any placeholder values (e.g., Xcode versions, Node versions, DB types, environment variables) with the actual project-specific values if they differ.

## Table of Contents
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Installation — Development](#installation---development)
- [Running the App](#running-the-app)
  - [Running the Local Backend (JS)](#running-the-local-backend-js)
  - [Running the Swift Desktop App](#running-the-swift-desktop-app)
  - [Running the Web Frontend](#running-the-web-frontend)
- [Web Frontend](#web-frontend)
  - [Framework Choice](#framework-choice)
  - [Configuration](#frontend-configuration)
  - [Connecting to the Backend](#connecting-to-the-backend)
  - [Supported CRUD Capabilities](#supported-crud-capabilities)
- [Configuration](#configuration)
- [API Reference (local backend)](#api-reference-local-backend)
- [Data & Persistence](#data--persistence)
- [Testing](#testing)
- [CI / Linting](#ci--linting)
- [Contributing](#contributing)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Credits & License](#credits--license)
- [Contact](#contact)

## Key Features
- Create, edit, and delete ruck sessions.
- Track distance, duration, average pace, elevation, load (weight carried).
- Local built-in backend to manage data and provide a local API.
- Session history, filtering, and basic charts/statistics.
- Export and import sessions (CSV/JSON).
- Optional sync/export to external services (future/optional).

## Architecture
- Desktop client: Swift (macOS) — UI built with SwiftUI / AppKit (update to actual).
- Local backend: JavaScript (Node.js) — small REST API used by the client for persistence and business logic.
- Data store: local persistence (Core Data / SQLite / file-based JSON) — replace with actual DB used.
- Communication: client ↔ local backend via HTTP (localhost) or direct IPC if implemented.

Diagram (high level):
Client (Swift) ↔ Local Backend (Node.js) ↔ Local DB (SQLite / Core Data)  
Optional: Sync to remote server or cloud storage (TBD)

## Requirements
- macOS (version X or later) — replace X with the minimum supported version (e.g., macOS 12+)
- Xcode (version Y or later) — replace Y with required Xcode version (e.g., Xcode 14+)
- Node.js (version Z or later) for the local backend (e.g., Node 18+)
- npm / pnpm / yarn (as appropriate)
- Swift toolchain (if using Swift Package Manager or command-line builds)
- (Optional) Homebrew for installing dependencies

## Installation — Development

1. Clone the repository
   ```bash
   git clone https://github.com/cptraingresilience/RuckingTracker.git
   cd RuckingTracker
   ```

2. Backend dependencies (if the backend is in a `backend/` or `Server/` subfolder)
   ```bash
   cd backend
   npm install
   # or
   yarn install
   ```

3. Open the Swift project in Xcode
   - Double-click `RuckingTracker.xcodeproj` or `RuckingTracker.xcworkspace` (if present), or:
   ```bash
   open RuckingTracker.xcodeproj
   ```

4. Configure environment variables and data directory (see Configuration below).

Notes:
- If the project uses Swift Package Manager, dependencies are fetched automatically by Xcode.
- If the JS backend requires native modules, ensure you rebuild them for your platform.

## Running the App

### Running the Web Frontend

The web frontend lives in the `frontend/` directory. It is plain HTML + CSS + vanilla JS — no build step required.

**Option 1 — Python (simplest, zero dependencies)**
```bash
cd frontend
python3 -m http.server 8080
# Then open http://localhost:8080
```

**Option 2 — Node.js `serve` package**
```bash
npx serve frontend
# Or: cd frontend && npx serve .
```

**Option 3 — VS Code Live Server extension**
Open `frontend/index.html` with Live Server (right-click → "Open with Live Server").

> The frontend is a static site. It has no Node dependencies or build process.

### Running the Local Backend (JS)
If the backend is a Node.js service, start it before launching the client (if the client expects an HTTP API on localhost).

Example:
```bash
cd backend
# development
npm run dev
# or production
npm start
```

Typical environment variable examples (create `.env` in backend folder):
```
PORT=3000
DB_PATH=./data/rucks.db
NODE_ENV=development
AUTH_SECRET=replace-with-secret
```

Confirm the backend API is reachable at http://localhost:3000 (or configured port).

### Running the Swift Desktop App
- In Xcode select the `RuckingTracker` scheme and run (Cmd+R).
- If the app requires the backend, ensure the backend is running on the configured port before launching.
- For command-line builds:
```bash
xcodebuild -scheme RuckingTracker -configuration Debug
open build/Debug/RuckingTracker.app
```
(Replace scheme and paths with real values used by the project.)

## Web Frontend

### Framework Choice

The web frontend uses **plain HTML + CSS + vanilla JavaScript** — no framework or build tool is required. This matches the backend's simple REST API surface (Express/Node.js with JSON responses) and keeps the project lightweight and dependency-free, consistent with the existing codebase philosophy (Swift + JS without heavy tooling).

### Frontend Configuration

Backend connection is configured in **`frontend/config.js`**:

```js
const CONFIG = {
  BASE_URL: "http://172.20.10.8:3000/api",  // ← change this to your backend host
};
```

- For local development: `http://localhost:3000/api`
- For a different host/IP: replace `172.20.10.8` with your machine's LAN IP or hostname.
- No environment variables required — just edit `config.js`.

### Connecting to the Backend

The frontend communicates with the backend REST API over HTTP:

| Action | Endpoint |
|--------|----------|
| Sign In | `POST /api/auth/signin` |
| Sign Up | `POST /api/auth/signup` |
| List Activities | `GET /api/activities` |
| Create Activity | `POST /api/activities` |
| Update Activity | `PUT /api/activities/:id` |
| Delete Activity | `DELETE /api/activities/:id` |
| Aggregated Stats | `GET /api/stats` |

Authentication uses a ****** stored in `localStorage`. The token is attached automatically to all authenticated requests.

**CORS**: Your backend must allow the frontend origin. If serving locally on port 8080, ensure your Node.js backend sets `Access-Control-Allow-Origin: *` or the specific frontend origin.

### Supported CRUD Capabilities

| Entity | Create | Read / List | Update | Delete |
|--------|--------|-------------|--------|--------|
| User Account | ✅ Sign up form | — | — | — |
| Activity (Ruck Session) | ✅ "Log Ruck" modal | ✅ Activities page + Dashboard | ✅ Edit modal | ✅ Delete confirm dialog |
| Stats | — | ✅ Dashboard stat cards | — | — |

**Assumptions:**
- The backend exposes REST endpoints at `BASE_URL` as described above.
- Pace is auto-calculated in the frontend as `duration_minutes / distance_miles` when both are provided.
- Duration input is in **minutes** (converted to seconds when sent to the API to match `ActivitySubmissionRequest`).
- Distance is in **miles** to match the Swift `TrackedActivity` model.
- If `GET /api/stats` is unavailable, stats are derived client-side from the activities list.

## Configuration
Centralized configuration lives in:
- Backend: `.env` or config file in `backend/`
- Client: app Settings, or `Config.plist` / environment variables at build time

Common variables:
- API_BASE_URL — e.g., `http://localhost:3000/api/v1`
- DB_PATH — path to local DB for backend
- LOG_LEVEL — `debug` | `info` | `warn` | `error`
- AUTH_SECRET — secret for signing tokens (if authentication is used)

Placeholders:
- Replace `PORT`, `DB_PATH`, and `AUTH_SECRET` in the backend `.env` with appropriate values.

## API Reference (local backend)
Below are example endpoints. Update these to match the actual backend implementation.

Base URL: http://localhost:3000/api/v1

- GET /rucks
  - Fetch list of ruck sessions
  - Params: ?limit=20&page=1&from=YYYY-MM-DD&to=YYYY-MM-DD
- GET /rucks/:id
  - Fetch one ruck session
- POST /rucks
  - Create a ruck session
  - Body (JSON):
    {
      "date": "2026-08-13T07:30:00Z",
      "distance_km": 8.5,
      "duration_seconds": 3600,
      "load_kg": 15,
      "notes": "Hill repeats"
    }
- PUT /rucks/:id
  - Update a ruck session
- DELETE /rucks/:id
  - Delete a ruck session
- GET /stats
  - Returns aggregated stats: total distance, total duration, average pace, rucks by month

Authentication (if implemented):
- POST /auth/login
- POST /auth/register
- Use Authorization: Bearer <token> for protected routes

Adjust endpoints to reflect actual routes used by the backend.

## Data & Persistence
- The client displays and edits ruck sessions. All write operations are performed via the local backend API.
- Database options used in similar projects:
  - SQLite (file-based) — good for local desktop persistence.
  - Core Data — native Apple persistence (if used directly in Swift).
  - JSON or file-based storage — simple and portable.
- Backup / Export: the app should provide export to CSV / JSON for portability and backup.

## Testing
Swift:
- Run unit/UI tests in Xcode (Cmd+U) or with xcodebuild:
```bash
xcodebuild test -scheme RuckingTracker -destination 'platform=macOS'
```

Backend (JS):
- Run tests:
```bash
cd backend
npm test
```

Add CI steps that run both Swift tests and backend tests.

## CI / Linting
- Swift linting: SwiftLint (recommended). Add a `.swiftlint.yml` and run in CI.
- JS linting: ESLint / Prettier for consistent JavaScript style.
- Add a GitHub Actions workflow to:
  - Build Swift project
  - Run Swift tests
  - Lint and test backend
  - Optionally, build release artifacts

## Contributing
We welcome contributions. Suggested workflow:
1. Fork the repo.
2. Create a descriptive branch: `feature/add-export-csv` or `fix/ui-crash-issue`.
3. Write tests for new behavior.
4. Run linters and formatters.
5. Open a pull request with a clear description of changes.

Commit message conventions:
- feat: new feature
- fix: bug fix
- chore: maintenance
- docs: documentation updates
- refactor: code refactor with no behavior change

Code style:
- Swift: follow the project's Swift style (prefer SwiftLint defaults).
- JavaScript: follow ESLint + Prettier config.

## Troubleshooting
- App won't start / backend not reachable:
  - Ensure backend is running and API URL in app settings points to the correct port.
  - Check logs in the backend console for errors.
- Database errors:
  - Verify DB path is writable.
  - Backup and remove corrupt DB to allow re-initialization (only if no data loss concerns).
- Build fails in Xcode:
  - Verify correct Xcode version and toolchain.
  - Clean build folder: Product → Clean Build Folder, or `xcodebuild clean`.

## Roadmap (suggested)
- Sync with a remote backup (optional cloud integration).
- Add user profiles and authentication.
- Enhance analytics and charts (distance over time, pace histograms).
- Add watchOS companion for live tracking.
- Mobile clients (iOS) and cross-device sync.

## Credits & License
- Author: cptraingresilience
- Third-party libraries:
  - List any Swift packages, CocoaPods, or JS libraries used (e.g., Express, SQLite library).
- License: MIT (replace with your chosen license)

## Contact
- Repository: https://github.com/cptraingresilience/RuckingTracker
- Maintainer: cptraingresilience (GitHub)
- For feature requests or bugs, please open an issue in the repository.

---

If you want, I can:
- Replace placeholders with concrete values if you give me the Xcode version, Node version, database, or actual folder names.
- Commit this README.md to the repository (I’ll need the repo write access confirmation).
- Generate additional docs: CONTRIBUTING.md, CHANGELOG.md, sample .env, or a basic GitHub Actions workflow for CI.
