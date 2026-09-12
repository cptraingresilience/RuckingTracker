# RuckingTracker

A native **iOS app** for tracking rucks (weighted walks / ruck marches), built with SwiftUI. Sign in with the Rux backend, log sessions, view history, track stats, and sync account-backed activity data.

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
- [Release pipeline](#release-pipeline)
- [App Store compliance](#app-store-compliance)
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
- **Backend-backed account flow** — email sign-up/sign-in, token refresh, team data, and activity sync use the Node.js REST API.

## Architecture
- **iOS client**: Swift + SwiftUI — all screens are native SwiftUI views.
- **Local persistence**: File-based JSON storage via `ActivityStore` (documents directory).
- **Backend API**: Node.js REST API (`APIClient.swift`) — required for sign-up, email sign-in, token refresh, team data, and authenticated activity sync.
- **Social sign-in**: Google / Apple sign-in is intentionally disabled until the backend supports exchanging social identities for Rux JWTs.

```
iOS App (SwiftUI)
  ├── ActivityStore   ← local JSON persistence (source of truth)
  └── APIClient       ← auth, team data, and HTTP sync to Node.js backend
        └── Node.js backend ↔ JSON data files
```

## Requirements
- macOS with Xcode 16+ (required for `PBXFileSystemSynchronizedRootGroup` support)
- iOS 18.6+ deployment target
- Node.js 18+ (required for local authenticated testing against `rux-backend/`)
- Firebase project configured (see `GoogleService-Info.plist`)

## Installation — Development

1. Clone the repository
   ```bash
   git clone https://github.com/cptraingresilience/RuckingTracker.git
   cd RuckingTracker
   ```

2. Install backend dependencies
   ```bash
   cd rux-backend
   npm install
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

> The app stores rucks locally on the device (JSON files in the Documents directory), but the current build launches to `LoginView` and requires a reachable backend for sign-up/sign-in before a user can enter the main tabs.

### Running the Local Backend (JS)

The backend is required for the current authenticated app flow. Start it before trying to sign up, sign in, refresh tokens, or load live team data. Once you are in the app, create/edit/delete rucks still write locally even if later sync attempts fail.

```bash
cd rux-backend
npm install
npm run dev      # development
# or
npm start        # production
```

Create a `.env` file in the `rux-backend/` folder:
```
PORT=3000
DATA_DIR=./data
JWT_SECRET=replace-with-local-access-secret
JWT_REFRESH_SECRET=replace-with-local-refresh-secret
```

`npm run dev` forces development mode. `npm start` forces production mode, so use strong,
different `JWT_SECRET` / `JWT_REFRESH_SECRET` values and an explicit comma-separated
`ALLOWED_ORIGINS` list before any release deployment. Local development can leave
`ALLOWED_ORIGINS` unset.

Verify the backend is reachable at `http://127.0.0.1:3000/health` and the API root at
`http://127.0.0.1:3000/api/health` (simulator) or your configured LAN IP (physical device).

## iOS App — UI & CRUD Capabilities

### Screens Overview

| Tab | Screen | Description |
|-----|--------|-------------|
| 🗺 Activity | `MapView` | Live GPS ruck tracking — tap Start/Stop to record a session |
| 📊 Log | `LogView` | Full activity history with stats, add/edit/delete rucks |
| 👥 Team | `TeamView` | Group leaderboard loaded from the backend |
| 👤 Profile | `ProfileView` | Placeholder profile summary (not yet account-backed) |
| ⚙️ Settings | `SettingsView` | Notifications, dark mode, unit preference, plus placeholder account/support rows |

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

The iOS app now uses a release-safe split configuration:
- **Release builds** → `RuckingTracker/RuckingTracker/Info.plist` → `BackendProductionBaseURL`
- **Debug simulator builds** → `RuckingTracker/RuckingTracker/Info-Debug.plist` → `BackendSimulatorBaseURL` (defaults to `http://127.0.0.1:3000/api`)
- **Debug physical-device builds** → `RuckingTracker/RuckingTracker/Info-Debug.plist` → `BackendLocalNetworkBaseURL`
- **Debug-only runtime override** → `UserDefaults` key `rt_backend_url`

Rules:
- Release builds require an **HTTPS** production API and will not fall back to localhost or any LAN IP.
- Physical devices must use your Mac's LAN address (for example `http://192.168.1.20:3000/api`), never `localhost`.
- Debug builds keep the ATS local-network exception in `Info-Debug.plist`; the release plist does not.

The app stores the access token received from sign-in/sign-up in the iOS Keychain and attaches it automatically to authenticated API requests.

**Local data remains available when the backend is unreachable after sign-in.** The app still lets you create, edit, and delete rucks locally, then attempts backend sync when an API token is available. A fresh install still needs a reachable backend to complete sign-up/sign-in.


## Configuration
- **Backend base URL**: set `BackendProductionBaseURL` for release, `BackendLocalNetworkBaseURL` for on-device debug, or use the debug-only `rt_backend_url` override
- **Backend `.env`**: `PORT`, `JWT_SECRET`, `JWT_REFRESH_SECRET` (legacy `AUTH_SECRET` / `AUTH_REFRESH_SECRET` still work)

## API Reference (local backend)

Base URL:
- Simulator debug: `http://127.0.0.1:3000/api`
- Device debug: `http://<your-mac-ip>:3000/api`
- Release: `https://<your-production-host>/api`

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/signup` | Create account → returns `accessToken`, `refreshToken`, `user` | No |
| POST | `/auth/signin` | Sign in → returns `accessToken`, `refreshToken`, `user` | No |
| POST | `/auth/refresh` | Exchange a refresh token for a new access/refresh token pair | No |
| GET | `/activities` | List all activities | Yes |
| POST | `/activities` | Create a new activity | Yes |
| PUT | `/activities/:id` | Update an activity | Yes |
| DELETE | `/activities/:id` | Delete an activity | Yes |
| GET | `/activities/stats/summary` | Aggregated stats | Yes |
| GET | `/teams` | List teams for the Team tab picker | No |
| GET | `/leaderboard?period=weekly|monthly|all` | Load ranked leaderboard entries | No |

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
- The client writes rucks to on-device JSON files via `ActivityStore`; backend writes are a follow-up sync path when the user has valid API tokens.
- Database options used in similar projects:
  - SQLite (file-based) — good for local desktop persistence.
  - Core Data — native Apple persistence (if used directly in Swift).
  - JSON or file-based storage — simple and portable.
- Backup / Export: the app should provide export to CSV / JSON for portability and backup.

## Testing
Swift (iOS):
- Run unit/UI tests in Xcode with **Cmd+U**, or from the command line:
```bash
xcodebuild test -project RuckingTracker/RuckingTracker.xcodeproj -scheme RuckingTracker -destination 'platform=iOS Simulator,name=iPhone 16'
```

Backend (JS):
- `rux-backend/package.json` does not ship an automated backend test suite yet; `npm test` is a placeholder script that exits with an error.

## CI / Linting
- Pull requests targeting `main` and pushes to `main` run the **iOS CI / iOS quality** check. It installs SwiftLint, lints the Swift sources, and runs the `RuckingTracker` Xcode test scheme on an available iOS Simulator.
- The test log is uploaded as the `xcodebuild-test-log` artifact, including when the job fails.
- Release branches (`release/**`) and `v*` tags also run **iOS Release Archive**, which performs an unsigned `xcodebuild archive` and uploads the archive/log artifacts.
- Repository administrators must make **iOS CI / iOS quality** a required status check in the `main` branch protection rule. This is what prevents merging a pull request until the quality gate passes.

Run the same checks locally:
```bash
brew install swiftlint
swiftlint lint --strict
xcodebuild test -project RuckingTracker/RuckingTracker.xcodeproj -scheme RuckingTracker -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Release pipeline

Pushing a `release/**` branch or a version tag matching `v*` (for example, `v1.2.0`) runs **iOS Release Archive**. The workflow archives the Release configuration without code signing and uploads a reproducible `RuckingTracker.xcarchive.zip` plus `xcodebuild-archive.log` as a workflow artifact. Download the artifact from the branch or tag's workflow run for debugging or a subsequent signed distribution step.

## App Store compliance

Submission artifacts live in [`docs/app-store/`](docs/app-store/):

- [`metadata.md`](docs/app-store/metadata.md) — final name, subtitle, description, keywords, URLs, age rating answers, and the screenshot capture plan.
- [`app-privacy-disclosures.md`](docs/app-store/app-privacy-disclosures.md) — the App Privacy questionnaire answers, each mapped to the code that produces the behaviour.
- [`submission-checklist.md`](docs/app-store/submission-checklist.md) — the end-to-end submission runbook plus the known blockers to clear before the first submission.

User-facing compliance pages: [privacy policy](docs/PRIVACY.md) (App Store *Privacy Policy URL*) and [support](docs/SUPPORT.md) (App Store *Support URL*).

The app requests **When In Use** location only, and `NSLocationWhenInUseUsageDescription` in `RuckingTracker/RuckingTracker/Info.plist` explains that location is used only during an active ruck while the app stays open and the iPhone remains unlocked. Update the privacy docs whenever `LocationManager`, `AnalyticsService`, `AuthService`, or `APIClient` change what data is collected or sent.

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
  - Ensure backend is running and the build is using the right base URL (`BackendSimulatorBaseURL`, `BackendLocalNetworkBaseURL`, `BackendProductionBaseURL`, or the debug-only `rt_backend_url` override).
  - Check logs in the backend console for errors.
- Backend data-store errors:
  - Verify `DATA_DIR` is writable.
  - Inspect `rux-backend/data/*.json` (or your configured data directory) for corrupt JSON and restore from backup if needed.
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
