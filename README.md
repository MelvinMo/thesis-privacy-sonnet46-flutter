# Sleep Tracker — Claude Sonnet 4.6 → Flutter Migration

> This is repo 5 of 7 from my M.Sc. thesis at McMaster University, *"Who Moved My Button?": A Usability Evaluation of LLM-Assisted Cross-Platform Migration*. I had two AI coding agents (Claude Sonnet 4.6 and GPT-5.5) each migrate a real mobile health app to three different frameworks, then evaluated all 7 resulting apps for usability. This repo is Claude Sonnet 4.6's rewrite in Flutter. The other six are linked below.

Flutter/Dart rewrite of the original React Native "Sleep Tracker" privacy-transparency app, produced by **Claude Sonnet 4.6** under a shared 15-rule migration prompt I wrote. It talks to the same Node.js/Express backend as the original app (see [thesis-privacy-baseline](https://github.com/MelvinMo/thesis-privacy-baseline)).

**UI fidelity target:** pixel-for-pixel match to the React Native source — layouts, text, font sizes, colors, padding, icons, and navigation flows were all checked against the original. SpaceMono is used app-wide as the font, matching the source app's bundled font.

---

## Usability findings (from my thesis)

This migration was evaluated with Nielsen's ten usability heuristics across six standardized tasks by a single assessor (severity 0–4, lower is better). Full detail is in **Chapter 4** of my thesis (App 2).

| Metric | Value |
|---|---|
| Aggregate severity total | **18** |
| vs. baseline (React Native, total 16) | **+2** |
| Rank among all 7 implementations | **3rd of 7 (mid-tier)** |

Three regressions, each rated severity 3, account for the gap above baseline — two originate in the sleep screen's save handlers: `_saveBedtime` triggers a privacy-risk re-analysis after saving but the sibling `_saveAlarmTime` omits the equivalent call, and `_saveBedtime`'s analysis call silently swallows failures (`.catchError((_){})`). The third is in onboarding navigation, where forward navigation uses `context.go()` instead of `context.push()`, which prevents the back button from returning to previous consent steps. See the thesis for the full per-heuristic breakdown and screenshots.

---

## Related repositories

| Repo | Description |
|---|---|
| [thesis-privacy-baseline](https://github.com/MelvinMo/thesis-privacy-baseline) | Original React Native app (unmodified snapshot) |
| [thesis-privacy-sonnet46-kmp](https://github.com/MelvinMo/thesis-privacy-sonnet46-kmp) | Claude Sonnet 4.6 → KMP |
| **thesis-privacy-sonnet46-flutter** | **This repo** — Claude Sonnet 4.6 → Flutter |
| [thesis-privacy-sonnet46-maui](https://github.com/MelvinMo/thesis-privacy-sonnet46-maui) | Claude Sonnet 4.6 → .NET MAUI |
| [thesis-privacy-gpt55-kmp](https://github.com/MelvinMo/thesis-privacy-gpt55-kmp) | GPT-5.5 → KMP |
| [thesis-privacy-gpt55-flutter](https://github.com/MelvinMo/thesis-privacy-gpt55-flutter) | GPT-5.5 → Flutter |
| [thesis-privacy-gpt55-maui](https://github.com/MelvinMo/thesis-privacy-gpt55-maui) | GPT-5.5 → .NET MAUI |

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter SDK | 3.3.0 or later | https://docs.flutter.dev/get-started/install |
| Dart SDK | >=3.3.0 (bundled with Flutter) | — |
| Android Studio | latest | for Android emulator + SDK |

Verify your setup:
```bash
flutter doctor
```
All required items should show a green checkmark before continuing.

---

## 1. Install dependencies

```bash
flutter pub get
```

---

## 2. Connect a physical device (recommended for sensors)

Sensors (microphone, accelerometer, light sensor) only work on a real device.
1. Enable **Developer Options** (Settings → About Phone → tap Build Number 7 times).
2. Enable **USB Debugging** in Developer Options.
3. Connect via USB and verify:
```bash
adb devices
```

---

## 3. Point the app at a backend

There's no runtime `.env` loading in Flutter — the backend URL is passed at build/run time via `--dart-define` flags. Copy the example file for reference:

```bash
cp .env.example .env
```

| Mode | URL |
|------|-----|
| Your own deployed backend (encrypted) | `https://<your-backend-host>` |
| Local dev (unencrypted) | `http://<your-computer's-LAN-IP>:7000` |

The active mode is controlled by `TransparencyConfig.useEncryptedTransit` in `lib/core/constants/transparency_config.dart`. To run the backend locally, see [thesis-privacy-baseline](https://github.com/MelvinMo/thesis-privacy-baseline).

---

## 4. Run the app

**Physical device — your deployed backend**
```bash
flutter run --dart-define=API_ENCRYPTED_URL=https://<your-backend-host>
```

**Physical device — local backend**
```bash
flutter run --dart-define=API_UNENCRYPTED_URL=http://<your-computer's-LAN-IP>:7000
```

**Android emulator — local backend**
```bash
flutter run --dart-define=API_UNENCRYPTED_URL=http://10.0.2.2:7000
```
`10.0.2.2` is the emulator's alias for the host machine's `localhost`.

**Choose a specific connected device**
```bash
flutter devices
flutter run -d <device-id> --dart-define=API_ENCRYPTED_URL=https://<your-backend-host>
```

**Release build (Android APK)**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Permissions required at runtime

Grant **Microphone**, **Body sensors / accelerometer**, and **Notifications** on first launch. If you denied a permission previously, re-enable it in **Device Settings → Apps → Sleep Tracker → Permissions**.

---

## Privacy transparency UI

- **Green icon** — all consented sensors running normally (LOW risk)
- **Yellow icon** — one or more sensor permissions revoked (MEDIUM risk)
- **Red icon** — high-severity violation (HIGH risk)

Tap any privacy icon during sleep mode to open the tooltip, or go to **Profile → Consent Preferences** to change consent (takes effect immediately).

---

## Project structure

```
├── lib/
│   ├── main.dart                  # Entry point
│   ├── app/app.dart               # App + router setup (go_router)
│   ├── blocs/                     # BLoC state management (auth, transparency, user_profile)
│   ├── core/                      # constants, dependency injection, models
│   ├── screens/                   # auth, onboarding, tabs (sleep/journal/statistics/profile)
│   ├── services/                  # HTTP client, sensor repository, encryption, local DB
│   └── widgets/                   # transparency icons/tooltips, shared UI components
├── assets/                        # fonts, images, privacyPolicyData.json
├── android/                       # Android native project
├── .env.example                   # Backend URL reference values (see Section 3)
└── .gitignore
```

---

## Known limitations (from my thesis)

- The onboarding back button does not return to previous consent steps (uses `context.go()` instead of `context.push()`).
- The bedtime save handler dispatches a privacy-risk re-analysis that the alarm-time save handler omits, and silently discards analysis failures.
- See Chapter 4 of my thesis for the full task-by-task and heuristic-by-heuristic severity breakdown, including the two other Claude Sonnet 4.6 migrations (KMP, MAUI).

---

## Environment variables & secrets

This repository contains **no real credentials**. `.env.example` holds placeholder/reference values only (a backend URL, not a secret). If you deploy your own backend, keep its real `.env` (JWT secret, database/Firebase keys, LLM API keys) out of version control — it's already covered by `.gitignore`.

---

## Citing my thesis

If you're referencing this repo, here's the full citation:

> Mokhtari, M. (2026). *"Who Moved My Button?": A Usability Evaluation of LLM-Assisted Cross-Platform Migration* [Master's thesis, McMaster University]. Department of Computing and Software. Supervisor: Richard F. Paige.

---

## License

All rights reserved — this is my thesis work. I've published it publicly so it's easy to review and reproduce, but please reach out to me before reusing or redistributing any of it.
