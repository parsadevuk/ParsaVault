# Parsa Vault — Project Todo List

---

## 🔴 Priority 1 — Critical / Blocking

### SSO & Authentication
- [ ] **Microsoft SSO** — Create Azure app registration at portal.azure.com → get Client ID + Client Secret → enable Microsoft provider in Firebase Console → test sign-in flow
- [ ] **Apple SSO** — Complete Services ID setup (use `com.parsadev.parsaVault2.sso`) → enable Sign In with Apple capability in Xcode → configure in Firebase Console → add Google URL scheme to Info.plist → test sign-in flow
- [ ] **Google SSO** — Add SHA-1 fingerprint to Firebase Console (Android) → add REVERSED_CLIENT_ID URL scheme to ios/Runner/Info.plist → test sign-in flow
- [ ] **Email Verification** — Wire up verification banner on Home screen for unverified email/password users → add Resend Email button to Profile page → test full flow

### Media Assets
- [ ] **App Icon** — Design and export all required sizes (iOS + Android). Place at `assets/images/logo_icon.png`. Run `flutter pub run flutter_launcher_icons` after placing.
- [ ] **In-App Logo** — Export logo for splash screen and login/register screens. Place at `assets/images/logo.png` (recommended: 512×512 PNG transparent background).
- [ ] **Transparent Logo** — For adaptive Android icon foreground. Place at `assets/images/logo_transparent.png`.

---

## 🟠 Priority 2 — High Impact / Next Sprint

### Firebase Integration
- [ ] **Firebase Auth migration** — Replace SQLite local auth with Firebase Auth as source of truth (Phase 1 complete — verify on device)
- [ ] **Firestore user profiles** — Migrate user data (cashBalance, xp, level, website, profilePicture) from SQLite to Firestore
- [ ] **Firestore holdings** — Migrate holdings data to Firestore subcollection under each user
- [ ] **Firestore transactions** — Migrate transaction history to Firestore subcollection
- [ ] **Firebase Storage** — Replace base64 profile pictures in SQLite with Firebase Storage URLs
- [ ] **Real leaderboard** — Replace hardcoded ghost competitors with live Firestore query (`users ORDER BY xp DESC`)
- [ ] **Firebase Crashlytics** — Add crash reporting (already installed — verify it's initialised in main.dart)
- [ ] **Firebase Analytics** — Verify analytics events are firing on key actions (trade, deposit, login)

### Navigation & UX
- [ ] **Remove Markets nav duplication** — Trade centre button and Markets tab show same screen. Remove Markets from bottom nav → 4-item nav: Home | Trade | History | Profile
- [ ] **Keyboard Done button** — Verify iOS keyboard dismiss works correctly on all input screens after latest changes

---

## 🟡 Priority 3 — Polish & Future Features

### App Store & Distribution
- [ ] **Google Play content rating** — Fix 18+ age gate → set category to Simulation, answer No to gambling questions
- [ ] **Google Play signing** — Configure `android/app/build.gradle.kts` with release keystore from `key.properties`
- [ ] **TestFlight external testers** — Submit for Beta App Review so external testers can join
- [ ] **Google Play internal testers** — Set up email list and share internal testing link

### Features
- [ ] **Password reset flow** — Wire up "Forgot Password?" to Firebase Auth `sendPasswordResetEmail()`
- [ ] **Push notifications** — Set up Firebase Cloud Messaging for trade alerts, daily login reminders
- [ ] **Web support** — Run `flutterfire configure` again to add web platform
- [ ] **Mac support** — Run `flutterfire configure` again to add macOS platform
- [ ] **Windows support** — Run `flutterfire configure` again to add Windows platform
- [ ] **Asset icons** — Replace placeholder stock/crypto icons with real branded logos
- [ ] **Sample trade data** — Pre-populate demo user with some trade history so the app looks alive on first launch

### Design
- [ ] **Onboarding illustrations** — Replace icon placeholders on onboarding slides with proper illustrations
- [ ] **Dark mode** — Design and implement dark theme toggle

---

## ✅ Completed

- [x] All 10 screens built (Splash, Onboarding, Login, Register, Home, Markets, Trade, History, Profile, Leaderboard)
- [x] 40 mock assets — 20 stocks + 20 crypto with live price simulation
- [x] SQLite local database with migration (v1 → v2)
- [x] Riverpod state management
- [x] XP system — buy, sell, deposit (−10 XP), withdraw (+10 XP), daily login, first trade bonus
- [x] Level system — 10 levels with titles (Apprentice → Vault Master)
- [x] Profile picture — image_picker, base64 stored in SQLite
- [x] Home P&L — shows actual profit/loss based on average buy price
- [x] Trade screen — 3 decimal places, shares/amount toggle, % quick buttons (buy + sell), keyboard dismiss
- [x] History page — filter pills for All / Buys / Sells / Deposits / Withdrawals
- [x] Profile page — red Deposit (−10 XP) / green Withdraw (+10 XP), edit website, logout redesign
- [x] Leaderboard — live XP via ref.watch, UTC/Greenwich time, week starts Monday
- [x] SSO buttons UI — Apple, Google, Microsoft (wired to Firebase, activates when providers enabled)
- [x] Firebase project created — iOS + Android configured, firebase_options.dart generated
- [x] Firebase Auth — email/password registration + login migrated from SQLite
- [x] Encryption export compliance — ITSAppUsesNonExemptEncryption = false in Info.plist
- [x] Photo permissions — NSPhotoLibraryUsageDescription + NSCameraUsageDescription in Info.plist
- [x] iOS TestFlight — first build uploaded and available
- [x] Android AAB built — 44.2MB release bundle ready
- [x] Android wireless debugging — Xiaomi HyperOS 3 connected at 192.168.1.6:5555
