# App Store submission checklist / runbook

Work top to bottom. Every box must be ticked before tapping **Submit for Review** in
App Store Connect. Copy this list into the release issue for each submission.

## 1. Pre-flight (repository)

- [ ] `main` is green: **iOS CI / iOS quality** passed (SwiftLint strict + Xcode tests).
- [ ] `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` bumped in
      `RuckingTracker/RuckingTracker.xcodeproj/project.pbxproj` (build number must be higher
      than any build already uploaded for this version).
- [ ] `Info.plist` reviewed: `NSLocationWhenInUseUsageDescription` present and accurate,
      `ITSAppUsesNonExemptEncryption` is `false`, `CFBundleURLSchemes` matches the reversed
      client ID in `GoogleService-Info.plist`.
- [ ] `BackendBaseURL` in `Info.plist` points at the **production HTTPS** backend, not
      `http://localhost:3000/api`. A cleartext localhost URL in a shipping build is an App
      Review rejection risk and leaves the app non-functional for users.
- [ ] `NSAppTransportSecurity` cleartext exceptions are limited to loopback hosts only (or
      removed entirely) for release builds.
- [ ] `docs/app-store/app-privacy-disclosures.md` re-verified against `AnalyticsService.swift`,
      `APIClient.swift`, `AuthService.swift`, `LocationManager.swift`.
- [ ] `docs/PRIVACY.md` "last updated" date refreshed if data handling changed.

## 2. Account and capabilities (App Store Connect / Developer portal)

- [ ] Apple Developer Program membership active; agreements, tax, and banking sections show
      no outstanding actions.
- [ ] App record exists with bundle ID `Com.Rux.Rux`.
- [ ] **Sign in with Apple** capability enabled for the App ID and in the Xcode target — it is
      mandatory because the app offers Google sign-in.
- [ ] Push Notifications capability enabled **only if** remote notifications actually ship
      (the Settings toggle today is a local preference only).
- [ ] Distribution certificate and App Store provisioning profile valid.

## 3. Build

```bash
xcodebuild -project RuckingTracker/RuckingTracker.xcodeproj \
  -scheme RuckingTracker -configuration Release \
  -archivePath build/RuckingTracker.xcarchive archive
```

- [ ] Archive succeeds (the `iOS Release Archive` workflow does the unsigned equivalent on
      `release/**` branches and `v*` tags).
- [ ] Signed archive validated and uploaded via Xcode Organizer or `xcrun altool`/
      `xcrun notarytool` equivalent for App Store.
- [ ] Build finished processing and is selectable in App Store Connect.
- [ ] Export compliance question answered **No** (matches `ITSAppUsesNonExemptEncryption`).

## 4. Listing

- [ ] Name, subtitle, promotional text, description, keywords pasted from
      [metadata.md](metadata.md) and within character limits.
- [ ] Categories set to Health & Fitness (primary) and Sports (secondary).
- [ ] Support URL and Privacy Policy URL entered and verified to load in a private browser
      window: `docs/SUPPORT.md` and `docs/PRIVACY.md`.
- [ ] Screenshots uploaded for every required display size, captured per
      [metadata.md](metadata.md), free of real user data.
- [ ] App icon present at every required size in `Assets.xcassets/AppIcon.appiconset`,
      including 1024×1024, with no alpha channel and no transparency.
- [ ] "What's New" text entered.
- [ ] Copyright and contact details completed.

## 5. Compliance answers

- [ ] App Privacy questionnaire completed exactly as specified in
      [app-privacy-disclosures.md](app-privacy-disclosures.md); "Data used to track you" is empty.
- [ ] Age rating questionnaire answered all-None → **4+**.
- [ ] Content rights: confirm the app contains no third-party content (the login background
      image must be owned or licensed for commercial use).
- [ ] Advertising identifier: **No**.
- [ ] Third-party SDK list (Firebase, Google Sign-In, GoogleAppMeasurement) matches the
      privacy manifests bundled by those SDKs.

## 6. Functional review pass on a real device

- [ ] Fresh install: location prompt appears with the expected wording, and denying it still
      allows manual ruck logging without a crash.
- [ ] Start/stop a GPS ruck; route, distance, duration, and pace are recorded and saved.
- [ ] Create, edit, and delete a ruck from the Log tab.
- [ ] Sign up, sign out, sign in with email; Google sign-in; Sign in with Apple.
- [ ] Account deletion path documented in `docs/SUPPORT.md` is reachable and honoured (Apple
      requires account deletion for apps that create accounts).
- [ ] App behaves gracefully with the backend unreachable and in Airplane Mode.
- [ ] Team and Profile tabs render without placeholder or debug text.

## 7. Reviewer information

- [ ] Demo account credentials entered and verified working from a clean device.
- [ ] Review notes explain what rucking is and how to start a tracked session.
- [ ] Contact name, phone, and email filled in.

## 8. Submit

- [ ] Release option chosen (manual release recommended for 1.0).
- [ ] Submit for Review.
- [ ] Record the submission date and build number in the release issue.

## Known blockers to resolve before the first submission

1. `BackendBaseURL` defaults to `http://localhost:3000/api`; a production HTTPS endpoint must
   be configured or backend-dependent features will fail review.
2. In-app account deletion is not implemented; the request-based flow in `docs/SUPPORT.md` is
   the interim answer, and an in-app path should be added to fully satisfy Guideline 5.1.1(v).
3. Sign in with Apple must be enabled as a capability for the shipping build because Google
   sign-in is offered (Guideline 4.8).
4. A demo account for App Review does not yet exist.
