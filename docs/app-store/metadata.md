# App Store metadata

Final copy for the App Store Connect listing. Values are ready to paste; anything marked
**TODO (account owner)** requires information that only the Apple Developer account holder can supply.

## Identity

| Field | Value |
|-------|-------|
| App name (30 char max) | `Rux: Rucking Tracker` (20) |
| Subtitle (30 char max) | `Log rucks, pace & weight` (24) |
| Bundle identifier | `Com.Rux.Rux` (`PRODUCT_BUNDLE_IDENTIFIER` in `RuckingTracker.xcodeproj`) |
| SKU | `RUX-IOS-001` |
| Primary language | English (U.S.) |
| Primary category | Health & Fitness |
| Secondary category | Sports |
| Marketing version | `MARKETING_VERSION` in the Xcode project (currently `1.0`) |
| Minimum iOS version | iOS 18.6 |
| Price | Free |
| Availability | All territories |

## Promotional text (170 char max)

> Track every ruck: live GPS route, distance, pace, and pack weight. Review your history,
> watch your stats climb, and compare progress with your team.

## Description (4000 char max)

> Rux turns every weighted walk into measurable progress.
>
> Start a ruck and Rux follows along with live GPS, recording your route, distance, elapsed
> time, and pace while you move. Stop the session and it saves to your log automatically —
> no forms to fill in unless you want to.
>
> Prefer to log after the fact? Add a ruck by hand with title, date, distance, duration, pack
> weight, and notes. Every entry can be edited or deleted at any time.
>
> WHAT YOU GET
> • Live GPS ruck tracking with map view
> • Manual logging for rucks you did not record
> • Full activity history with distance and duration at a glance
> • Detail view with all metrics and your own notes
> • Stats dashboard: total miles, total time, average pace, and best distance
> • Team leaderboard to see how your group is stacking up
> • Imperial or metric units, dark mode, and notification preferences
> • Email account sign-in with backend-backed sync for saved rucks
>
> YOUR DATA
> Rucks are stored on your device and, after you sign in, synced to the Rux service so they are
> available to your account across devices.
> Location data is used to record the route of the ruck you are tracking; it is not sold and
> is not used for advertising.
>
> Rux is built for ruckers, hikers, and anyone training under load. Put the pack on, hit
> Start, and let the log do the talking.

## Keywords (100 char max, comma separated, no spaces)

```
ruck,rucking,rucksack,march,weighted,hike,walk,gps,pace,distance,fitness,training,log,tracker
```

(94 characters.)

## What's New in This Version (1.0)

> First release of Rux. Track rucks with live GPS, log them manually, review your full history
> and stats, and check the team leaderboard.

## URLs

| Field | Value |
|-------|-------|
| Support URL | https://github.com/cptraingresilience/RuckingTracker/blob/main/docs/SUPPORT.md |
| Marketing URL | https://github.com/cptraingresilience/RuckingTracker |
| Privacy policy URL | https://github.com/cptraingresilience/RuckingTracker/blob/main/docs/PRIVACY.md |

Both URLs are public, load without authentication, and are hosted from this repository so they
stay in sync with the shipped behaviour. If a custom domain is adopted later, update the URLs
here, in App Store Connect, and in `docs/PRIVACY.md`.

## Age rating and content settings

Answer every App Store Connect age-rating question **None** / **No**. The app contains no
violence, no sexual content, no profanity, no gambling, no drug references, no horror themes,
no contests, and no unrestricted web access. The team leaderboard shows names and aggregate
ruck stats supplied by the account holder; it has no free-form chat or user-generated media,
so "user generated content" is **No**.

Resulting rating: **4+**.

| Setting | Answer |
|---------|--------|
| Made for Kids | No |
| Kids Category | Not selected |
| Contains ads | No |
| In-app purchases | No |
| Third-party analytics | Yes (Firebase Analytics) |
| Sign in with Apple offered | No (social sign-in is disabled until backend token exchange exists) |

## Screenshots

Required sizes (App Store Connect accepts these and scales down for smaller devices):

| Display | Device | Pixels |
|---------|--------|--------|
| 6.9" | iPhone 16 Pro Max | 1320 × 2868 |
| 6.5" | iPhone 11 Pro Max / XS Max | 1242 × 2688 |
| 13" (only if iPad is supported at submission) | iPad Pro 13" | 2064 × 2752 |

Capture five screenshots, in this order, on the iPhone 16 Pro Max simulator with a seeded demo
account and the status bar cleaned up (`xcrun simctl status_bar <udid> override --time 9:41
--batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3`):

1. **Activity / MapView** mid-ruck, showing the live route and Stop & Save button.
2. **LogView** with the stats cards at the top and at least six logged rucks.
3. **ActivityDetailView** for a single ruck showing all metrics and notes.
4. **TeamView** leaderboard.
5. **SettingsView** showing units, dark mode, and notification toggles.

Rules to respect: no pricing claims, no placeholder/lorem text, and no personal data of real
users in the captures. App Preview videos are optional and not part of the 1.0 submission. Do
not capture Profile/Settings until placeholder content has been replaced or removed from the
shipping build.

## App Review information

| Field | Value |
|-------|-------|
| Sign-in required | Yes |
| Demo account | **TODO (account owner)** — create a permanent demo account in the Rux backend and enter the email/password here |
| Contact | **TODO (account owner)** — first name, last name, phone, email |
| Notes to reviewer | "Rucking is walking or hiking while carrying a weighted pack. Sign in with the demo account first, then tap the Activity tab and press Start Ruck to begin GPS tracking; allow the location prompt to see the route draw. Rucks can also be added manually from the Log tab with the + button. The Team tab reads live backend leaderboard data for the seeded demo account." |

## Open release-metadata blockers

- **TODO (account owner):** fill in the App Review demo account and contact details above.
- **Before screenshots/review:** seed the demo backend account with team membership and enough
  activity data to populate Log and Team screens.
- **Before screenshots/review:** replace or hide placeholder Profile/Settings content in the app.
- **Before upload:** replace `Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` with an
  opaque no-alpha export.
