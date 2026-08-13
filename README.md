# RuckingTracker

A native **iOS app** for tracking rucks (weighted walks / ruck marches), built with SwiftUI. Log sessions, view history, track stats, and optionally sync with a local Node.js backend.

## Table of Contents
- [Key Features](#key-features)
- [Architecture](#architecture)
- [Requirements](#requirements)
- [Installation — Development](#installation---development)
- [Running the App](#running-the-app)
  - [Running the Swift iOS App](#running-the-swift-ios-app)
  - [Running the Local Backend (JS)](#running-the-local-backend-js)
- [iOS App — UI & CRUD Capabilities](#ios-app--ui--crud-capabilities)
  - [Screens Overview](#screens-overview)
  - [Supported CRUD Operations](#supported-crud-operations)
  - [Backend Connection Configuration](#backend-connection-configuration)
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
- **Log rucks manually** — title, date, distance (mi), duration (min), pack weight (lb), notes.
- **Live GPS tracking** — start/stop a ruck session from the Activity tab; saves automatically.
- **Activity history** — scroll through all logged rucks with distance and duration at a glance.
- **Detail view** — tap any ruck to see all metrics, notes, and manage the record.
- **Edit rucks** — update any field on a saved ruck.
- **Delete rucks** — swipe-to-delete in the list or tap Delete on the detail screen.
- **Stats dashboard** — total miles, average pace, total time, and personal best distance.
- **Team leaderboard** — view group rankings and scores.
- **Settings** — notifications, dark mode, unit preference (Imperial/Metric).
- **Optional backend sync** — activities can be submitted to a Node.js REST API (configurable).

## Architecture
- **iOS client**: Swift + SwiftUI — all screens are native SwiftUI views.
- **Local persistence**: File-based JSON storage via `ActivityStore` (documents directory).
- **Optional backend**: Node.js REST API (`APIClient.swift`) — used for account creation, sign-in, and optional activity sync. Requires a running backend server.
- **Firebase Auth**: Used for email/Google sign-in on the device.

```
iOS App (SwiftUI)
  ├── ActivityStore   ← local JSON persistence (source of truth)
  └── APIClient       ← optional HTTP sync to Node.js backend
        └── Node.js backend ↔ Database
```

## Requirements
- macOS with Xcode 16+ (required for `PBXFileSystemSynchronizedRootGroup` support)
- iOS 15+ deployment target
- Node.js 18+ (only required if running the optional local backend)
- Firebase project configured (see `GoogleService-Info.plist`)

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

### Running the Swift iOS App

1. Open `RuckingTracker/RuckingTracker.xcodeproj` in Xcode 16+.
2. Select the `RuckingTracker` scheme and an iOS Simulator (or a connected device).
3. Press **Cmd+R** to build and run.

> The app stores activity data locally on the device (JSON files in the Documents directory). The optional backend is not required to use the core features.

### Running the Local Backend (JS)

The backend is optional. Start it if you want account creation / activity sync over the network.

```bash
cd backend
npm install
npm run dev      # development
# or
npm start        # production
```

Create a `.env` file in the `backend/` folder:
```
PORT=3000
DB_PATH=./data/rucks.db
NODE_ENV=development
AUTH_SECRET=replace-with-secret
```

Verify the backend is reachable at `http://localhost:3000` (or your configured port/IP).

## iOS App — UI & CRUD Capabilities

### Screens Overview

| Tab | Screen | Description |
|-----|--------|-------------|
| 🗺 Activity | `MapView` | Live GPS ruck tracking — tap Start/Stop to record a session |
| 📊 Log | `LogView` | Full activity history with stats, add/edit/delete rucks |
| 👥 Team | `TeamView` | Group leaderboard |
| 👤 Profile | `ProfileView` | User stats summary |
| ⚙️ Settings | `SettingsView` | Notifications, dark mode, unit preference |

### Supported CRUD Operations

| Operation | How |
|-----------|-----|
| **Create** | `LogView` → tap **+** in the top-right → fill in the form → Save |
| **Create (GPS)** | `MapView` → tap **Start Ruck** → tap **Stop & Save** |
| **Read / List** | `LogView` scrollable list; stats cards at the top |
| **Read (detail)** | Tap any ruck card → `ActivityDetailView` (all metrics + notes) |
| **Update** | Tap any ruck card → **Edit** button (top-right) → edit form → Save |
| **Delete** | Swipe left on a ruck in the list → Delete, **or** open detail → Delete Ruck button |
| **Sign Up** | `LoginView` → **Create one** link → `SignUpView` form |

### Backend Connection Configuration

The iOS app reads the backend base URL from:
- `Info.plist` → `BackendBaseURL`
- or `UserDefaults` → `rt_backend_url` (runtime override)

Change this value to match your backend host before building:
- Local simulator: `http://localhost:3000/api`
- Device on same network: `http://<your-mac-ip>:3000/api`

The app stores the access token received from sign-in/sign-up in `UserDefaults` (`rt_access_token`) and attaches it automatically to all authenticated API requests.

**Local data remains available when the backend is unreachable.** The app still lets you create, edit, and delete rucks locally, then attempts backend sync when an API token is available.


## Configuration
- **Backend base URL**: set `BackendBaseURL` in `RuckingTracker/RuckingTracker/Info.plist`, or override at runtime with `UserDefaults` key `rt_backend_url`
- **Backend `.env`**: `PORT`, `DB_PATH`, `AUTH_SECRET` (see Running the Local Backend above)

## API Reference (local backend)

Base URL: `http://<host>:3000/api` (configure `BackendBaseURL` in `Info.plist` or `rt_backend_url` in `UserDefaults`)

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/signup` | Create account → returns `accessToken` | No |
| POST | `/auth/signin` | Sign in → returns `accessToken` | No |
| GET | `/activities` | List all activities | Yes |
| POST | `/activities` | Create a new activity | Yes |
| PUT | `/activities/:id` | Update an activity | Yes |
| DELETE | `/activities/:id` | Delete an activity | Yes |
| GET | `/activities/stats/summary` | Aggregated stats | Yes |

**Auth**: include a bearer access token in the `Authorization` header on authenticated routes.

Request body for create/update:
```json
{
  "title": "Morning Ruck",
  "notes": "Hill repeats",
  "distance": 4.5,
  "duration": 3600,
  "pace": 13.3,
  "packWeight": 35,
  "startedAt": "2026-08-13T07:30:00Z",
  "endedAt": "2026-08-13T08:30:00Z"
}
```

## Data & Persistence
- The client displays and edits ruck sessions. All write operations are performed via the local backend API.
- Database options used in similar projects:
  - SQLite (file-based) — good for local desktop persistence.
  - Core Data — native Apple persistence (if used directly in Swift).
  - JSON or file-based storage — simple and portable.
- Backup / Export: the app should provide export to CSV / JSON for portability and backup.

## Testing
Swift (iOS):
- Run unit/UI tests in Xcode with **Cmd+U**, or from the command line:
```bash
xcodebuild test -scheme RuckingTracker -destination 'platform=iOS Simulator,name=iPhone 16'
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
