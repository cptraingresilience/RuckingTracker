# Rux privacy policy

**Last updated: 2026-09-12**

Rux ("the app") is a rucking tracker for iOS published by cptraingresilience ("we", "us").
This policy describes exactly what the shipped app does with your data.

## Data stored on your device

- **Ruck sessions** — title, date, distance, duration, pace, pack weight, notes, and the GPS
  route recorded during a tracked ruck. These are written to a JSON file in the app's
  Documents directory.
- **Preferences** — notification, dark mode, and unit settings, stored in `UserDefaults`.
- **Access token** — if you sign in, the token issued by our service is stored in the iOS
  Keychain so you stay signed in.

Deleting the app removes all of this local data.

## Data sent off the device

| Data | Where it goes | Why |
|------|---------------|-----|
| Email address, username, password credential, refresh token | Rux backend, when configured | To create and authenticate your account and keep you signed in |
| Ruck sessions (title, notes, distance, duration, pace, pack weight, start/end time) | Rux backend, when you are signed in and a backend is configured | So your rucks are backed up and available to your account |
| App usage events (screen views, button taps, completed-activity events) and the identifiers Firebase Analytics attaches to them | Firebase Analytics (Google) | To understand which features are used and to fix problems |

We do **not** sell your data, use it for third-party advertising, or use it to track you
across other companies' apps and websites.

## Location

Rux requests **While Using the App** location access. Location is sampled only while a ruck is
actively being tracked, and it is used to draw your route and calculate distance and pace. The
route is stored with the ruck. If you sign in and sync is enabled, the ruck's summary metrics
are sent to the Rux backend. Rux never requests Always/background location and never uses
location for advertising. You can deny or revoke access in iOS Settings; manual ruck logging
continues to work.

## Third-party services

- **Firebase Analytics / Google Analytics for Firebase** — see Google's privacy policy:
  https://policies.google.com/privacy

## Retention

Local data stays until you delete the ruck or the app. Account data and synced rucks are kept
while your account exists and are deleted within 30 days of a verified deletion request.
Firebase Analytics data is retained according to the retention window configured in the
Firebase console.

## Your choices

- Deny or revoke location access in iOS Settings.
- Delete individual rucks in the app.
- Request account and data deletion — see [SUPPORT.md](SUPPORT.md).

## Children

Rux is not directed to children under 13 and we do not knowingly collect their data. If you
believe a child has provided us data, contact us and we will delete it.

## Changes

We will update this page and the "last updated" date when the app's data handling changes, and
we will keep the App Store "App Privacy" answers in sync.

## Contact

Open an issue at https://github.com/cptraingresilience/RuckingTracker/issues or contact
cptraingresilience on GitHub.
