# Security remediation status (Issue #3)

This document records the security controls now enforced across the iOS app and backend.

## 1) Hardcoded secrets removed

- Backend auth no longer falls back to hardcoded/default JWT secrets.
- `JWT_SECRET` and `JWT_REFRESH_SECRET` are required via environment variables.
- Example secure configuration is provided in `rux-backend/.env.example`.

## 2) HTTPS/ATS transport security

- iOS requests now reject non-HTTPS URLs unless the host is loopback (`localhost` or `127.0.0.1`) for local development.
- `Info.plist` ATS now scopes cleartext exceptions to loopback only.
- `GoogleService-Info.plist` no longer overrides ATS with `NSAllowsArbitraryLoads`.

## 3) Sensitive token storage

- Access tokens are stored and read from iOS Keychain.
- Legacy `UserDefaults` token fallback was removed so runtime auth token reads no longer use plaintext local storage.

## 4) Backend input validation/sanitization

- Added Joi-based validation for:
  - `POST /api/auth/signup`
  - `POST /api/auth/signin`
  - `POST /api/auth/refresh`
  - `POST /api/teams`
  - `GET /api/leaderboard?period=...`
- Unknown input properties are stripped during validation.

## 5) Dependency vulnerability scan

- Ran `npm audit --audit-level=high` in `rux-backend` and remediated findings with `npm audit fix`.
- Current backend audit status: **0 vulnerabilities**.

## 6) Sensitive logging protections

- Backend structured logger now redacts keys containing sensitive names such as password, token, secret, authorization, and apiKey.
- iOS analytics debug logging no longer prints event parameters.

## Firebase security hardening (Issue #7)

- `GoogleService-Info.plist` contains Firebase client configuration only (no service-account private key material).
- Baseline deny-by-default Firebase rules have been added:
  - `docs/firebase/firestore.rules`
  - `docs/firebase/storage.rules`
  - `docs/firebase/database.rules.json`
- Apply API key restrictions in Google Cloud Console:
  1. Restrict the iOS key to bundle ID `Com.Rux.Rux`.
  2. Restrict allowed APIs to Firebase SDK-required APIs only.
  3. Disable unused Firebase products and monitor abuse in Firebase/Cloud logs.

## Compliance and privacy references (Issue #6)

- Privacy policy: `docs/PRIVACY.md`
- Support URL content: `docs/SUPPORT.md`
- App Store artifacts:
  - `docs/app-store/metadata.md`
  - `docs/app-store/app-privacy-disclosures.md`
  - `docs/app-store/submission-checklist.md`
