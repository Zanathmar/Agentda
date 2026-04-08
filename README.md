# AI Scheduler

A Flutter mobile app that uses Claude AI to generate optimized daily schedules from your tasks.
Dark mode, email authentication, local storage, and optional Supabase cloud sync. No backend or Docker required.

---

## Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter + Riverpod + GoRouter |
| Authentication | Supabase (email / password) |
| AI schedule | Claude API (called directly from the app) |
| Local storage | SharedPreferences + FlutterSecureStorage |
| Cloud sync (optional) | Supabase PostgreSQL |

---

## Project structure

```
lib/
├── main.dart                          # Entry point · router · AppShell nav
├── theme.dart                         # Dark mode colors (C.*) + ThemeData
├── models/
│   └── models.dart                    # AppUser · Task · ScheduleBlock · UserPrefs
├── services/
│   ├── auth_service.dart              # Supabase email sign-in/up/out
│   ├── claude_service.dart            # Claude API call + JSON parse + error messages
│   ├── storage_service.dart           # SharedPrefs + SecureStorage (API key, tasks)
│   └── supabase_sync.dart             # Best-effort cloud task sync (no-op if offline)
├── providers/
│   └── providers.dart                 # All Riverpod StateNotifier providers
├── screens/
│   ├── auth/
│   │   ├── splash_screen.dart         # Cold-start loading screen
│   │   ├── login_screen.dart          # Email/password login + forgot password sheet
│   │   └── register_screen.dart       # Account creation
│   └── main/
│       ├── home_screen.dart           # Today's timeline + generate button
│       ├── tasks_screen.dart          # Task list · swipe-to-delete · completion toggle
│       ├── add_edit_task_screen.dart  # Task form · priority · deadline · preferred time
│       └── settings_screen.dart       # API key guide · working hours · sign out
└── widgets/
    └── widgets.dart                   # AppField · PrimaryBtn · PriorityChip · EmptyState
```

---

## Prerequisites

- Flutter SDK ≥ 3.16 (`flutter --version` to check, `flutter upgrade` to update)
- A free [Supabase](https://supabase.com) project (for auth)
- A free [Claude API key](https://console.anthropic.com) (for schedule generation)

---

## Setup

### Step 1 — Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up for free
2. Create a new project (takes ~2 minutes to provision)
3. Go to **Settings → API** and copy:
   - **Project URL** — looks like `https://abcdefgh.supabase.co`
   - **anon public key** — a long string starting with `eyJ...`

That's all — Supabase email auth works out of the box. No extra config needed.

### Step 2 — (Optional) Set up cloud task sync

If you want tasks backed up to the cloud, run the SQL in `supabase_setup.sql`
in your Supabase project: **SQL Editor → New query → paste → Run**.

If you skip this step, tasks are still saved locally on device.

### Step 3 — Install Flutter dependencies

```bash
cd ai-scheduler-v2
flutter pub get
```

### Step 4 — Run the app

Pass your Supabase credentials via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON=your-anon-key \
  -d ios       # iOS simulator
# or
  -d android   # Android emulator
# or
  -d macos     # macOS desktop
```

> If you don't pass credentials the app still runs — auth will just fail until you add them.

---

## First-time use

```
1. Open app → tap Sign up → create your account
2. Go to Settings tab
3. Follow the 4-step guide to get your free Claude API key
4. Paste the key and tap Save Key
5. Go to Tasks → add a few tasks with deadlines and priorities
6. Go to Today → tap Generate Schedule
7. Claude AI arranges everything into an optimized timeline
```

---

## Auth flow

```
App launch
     │
     ▼
Check Supabase session ──── loading ──▶ SplashScreen
     │
     ├── no session ──▶ LoginScreen
     │                       │
     │              Sign in / Sign up
     │                       │
     └── session found ◀─────┘
     │
     ▼
HomeScreen  ←→  TasksScreen  ←→  SettingsScreen
     │
  Sign out
     │
     ▼
LoginScreen
```

---

## Schedule generation flow

```
Tap "Generate Schedule"
        │
        ▼
ClaudeService.generate()
  - Builds structured prompt with tasks + working hours
  - POST https://api.anthropic.com/v1/messages
        │
        ▼
Claude returns JSON
  { "schedule": [...], "unscheduled_task_ids": [], "summary": "..." }
        │
        ▼
Parsed into GeneratedSchedule
  - Saved locally (SharedPreferences)
  - Displayed as timeline in HomeScreen
```

Claude is called **directly from the Flutter app** — no server in between.
The API key is stored in iOS Keychain / Android Keystore via `flutter_secure_storage`.

---

## Claude AI prompt

The app sends Claude a structured prompt with:
- Today's date and day of week
- Each task: title, notes, deadline, duration, priority, preferred start time
- Your working window (default 09:00–18:00)
- Minimum break duration between tasks

Claude is instructed to reply with **raw JSON only** (no markdown, no explanation).
The app strips any accidental code fences before parsing.

---

## Screen reference

| Screen | Route | Key features |
|---|---|---|
| Splash | `/splash` | Shown while auth resolves on cold start |
| Login | `/login` | Email/password · forgot password bottom sheet |
| Register | `/register` | Name + email + password + confirm |
| Today | `/` | Timeline · summary bar · generate button · NOW badge |
| Tasks | `/tasks` | List sorted by priority+deadline · swipe delete · undo snackbar |
| Add/Edit task | `/task/add` `/task/edit` | Priority picker · date picker · time picker |
| Settings | `/settings` | Step-by-step API key guide · working hours · sign out |

---

## Offline behavior

- Tasks and the last generated schedule are always saved locally
- The app fully works offline for viewing and editing tasks
- Schedule generation and sign-in require an internet connection
- Cloud sync is best-effort — network errors are silently ignored

---

## Build for release

```bash
# iOS
flutter build ios --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON=...

# Android APK
flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON=...

# Android App Bundle
flutter build appbundle --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON=...
```

---

## Troubleshooting

**"Invalid API key" error when generating**
→ Check the key in Settings. It must start with `sk-ant-api03-`. Get one at console.anthropic.com.

**Auth fails / can't sign up**
→ Make sure `SUPABASE_URL` and `SUPABASE_ANON` are correct. The project URL includes `https://`.

**Schedule never updates after adding tasks**
→ Tap "Regenerate Schedule" on the Today screen — schedules are not generated automatically.

**Tasks disappear after reinstall**
→ Local storage is wiped on uninstall. Enable cloud sync via `supabase_setup.sql` to persist across installs.

**Flutter version error**
→ Run `flutter upgrade` to get Flutter 3.16+, which is required for `WidgetStateProperty`.
