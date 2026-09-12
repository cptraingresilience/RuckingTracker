# App Privacy disclosures (App Store Connect answers)

These answers are derived from the code that actually ships. Each row cites the source so the
disclosure can be re-verified whenever data handling changes.

## Evidence in the codebase

| Behaviour | Source |
|-----------|--------|
| Precise location sampled only while a ruck is tracked; **When In Use** authorization only; tracking stops when the app leaves the foreground | `RuckingTracker/RuckingTracker/LocationManager.swift` (`requestWhenInUseAuthorization`, `startUpdatingLocation` gated by `isTracking`, `stopTrackingBecauseAppLeftForeground`) |
| Email, password, and username sent to the backend for sign-up / sign-in | `RuckingTracker/RuckingTracker/APIClient.swift` (`SignupRequest`, `SigninRequest`, `UserDTO`) |
| Access token stored in the Keychain and attached to authenticated requests | `RuckingTracker/RuckingTracker/APIClient.swift` (Keychain helpers) |
| Google / Apple sign-in is disabled until backend token exchange exists | `RuckingTracker/RuckingTracker/AuthService.swift`, `RuckingTracker/RuckingTracker/LoginView.swift` |
| The app launches to the login screen; there is no guest mode in the shipping build | `RuckingTracker/RuckingTracker/RuckingTrackerApp.swift`, `RuckingTracker/RuckingTracker/LoginView.swift` |
| Analytics events: `screen_view`, `button_tap`, `activity_completed` (with activity id, distance, duration); no analytics user ID is set in app code | `RuckingTracker/RuckingTracker/AnalyticsService.swift` |
| Firebase configured at launch | `RuckingTracker/RuckingTracker/AppDelegate.swift`, `GoogleService-Info.plist` |
| Ruck sessions persisted locally as JSON | `RuckingTracker/RuckingTracker/ActivityStore.swift` |
| Ruck routes stay on-device; backend sync covers activity summary fields when a token exists | `RuckingTracker/RuckingTracker/ActivityStore.swift`, `RuckingTracker/RuckingTracker/APIClient.swift` (`ActivitySubmissionRequest`) |

No HealthKit, Contacts, Photos, Camera, Microphone, Motion, or advertising SDK usage exists in
the project; those categories are therefore answered "not collected".

## Answers to give in App Store Connect

Question 1 — *Do you or your third-party partners collect data from this app?* **Yes.**

### Contact Info → Email Address
- Collected: **Yes**
- Linked to the user: **Yes**
- Used for tracking: **No**
- Purposes: **App Functionality** (account creation and sign-in)

### Contact Info → Name
- Collected: **Yes** (username)
- Linked to the user: **Yes**
- Used for tracking: **No**
- Purposes: **App Functionality** (account creation and team leaderboard)

### Location → Precise Location
- Collected: **Yes**
- Linked to the user: **Yes**
- Used for tracking: **No**
- Purposes: **App Functionality** (recording the route, distance, and pace of a ruck while the app stays open and unlocked)

### Health & Fitness → Fitness
- Collected: **Yes** (distance, duration, pace, pack weight of each ruck)
- Linked to the user: **Yes**
- Used for tracking: **No**
- Purposes: **App Functionality**, **Analytics** (the `activity_completed` event includes
  distance and duration)

### User Content → Other User Content
- Collected: **Yes** (ruck title and notes, when synced)
- Linked to the user: **Yes**
- Used for tracking: **No**
- Purposes: **App Functionality**

### Identifiers → User ID
- Collected: **Yes** (backend account identifier)
- Linked to the user: **Yes**
- Used for tracking: **No**
- Purposes: **App Functionality**

### Identifiers → Device ID
- Collected: **Yes** (Firebase Analytics app instance ID)
- Linked to the user: **No**
- Used for tracking: **No**
- Purposes: **Analytics**

### Usage Data → Product Interaction
- Collected: **Yes** (screen views and button taps)
- Linked to the user: **No**
- Used for tracking: **No**
- Purposes: **Analytics**

### Diagnostics
- Collected: **No** — no Crashlytics or performance SDK is integrated. Add this category if
  Crashlytics is ever enabled.

### Everything else
Not collected: Financial Info, Physical Address, Phone Number, Other Contact Info, Contacts,
Browsing History, Search History, Purchases, Photos or Videos, Audio Data, Gameplay Content,
Customer Support, Sensitive Info, Coarse Location, Advertising Data, Other Data.

## Tracking and ATT

Firebase Analytics is used for first-party analytics only; the project integrates no ad
network or attribution SDK. `AppTrackingTransparency` is therefore **not** required and no
`NSUserTrackingUsageDescription` is present. If advertising, IDFA access, or Google Ads
conversion measurement is ever enabled, this document, the App Privacy answers, and the ATT
prompt must all be added before that build ships.

To keep this accurate, set `GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED`/ad-personalization off in
the Firebase console unless the disclosures above are updated.

## Purpose strings shipped in the app

| Key | Value | Where |
|-----|-------|-------|
| `NSLocationWhenInUseUsageDescription` | "Rux uses your location while you are actively tracking a ruck to record route, distance, and pace. For this MVP, tracking only works while the app stays open and the iPhone remains unlocked." | `RuckingTracker/RuckingTracker/Info.plist` |
| `ITSAppUsesNonExemptEncryption` | `false` — the app only uses exempt system cryptography such as HTTPS and Keychain | `RuckingTracker/RuckingTracker/Info.plist` |

## Re-verification

Re-check this document whenever `AnalyticsService.swift`, `APIClient.swift`,
`AuthService.swift`, `LocationManager.swift`, or the Firebase configuration changes, and before
every App Store submission (see [submission-checklist.md](submission-checklist.md)).
