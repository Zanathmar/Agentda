# Agentda — AI Scheduler

A Flutter mobile app that uses Google Gemini AI to generate optimized daily schedules from your tasks. Light mode, email authentication, local storage, and optional Supabase cloud sync. No backend or Docker required.

---

## App Screens

| Screen | Description |
|---|---|
| Login | Email/password sign-in with forgot-password sheet |
| Home | Week strip, stats overview, task list, and generate button |
| AI Schedule | Timeline of AI-generated blocks with live "Now" badge |
| Add Task | Task form with priority picker, deadline, and preferred time |
| Calendar | Monthly grid with per-day task stats and task list |
| Profile | API key setup, working hours, break config, sign out |

---

## Stack

| Layer | Technology |
|---|---|
| Mobile app | Flutter + Riverpod + GoRouter |
| Authentication | Supabase (email / password) |
| AI schedule | Google Gemini API (called directly from the app) |
| Local storage | SharedPreferences + FlutterSecureStorage |
| Cloud sync (optional) | Supabase PostgreSQL |

---

## Project structure

```
lib/
├── main.dart                          # Entry point · router · AppShell nav
├── theme.dart                         # Light mode colors (C.*) + ThemeData
├── models/
│   ├── models.dart                    # Barrel export
│   ├── app_user.dart                  # AppUser model
│   ├── task.dart                      # Task + Priority enum
│   ├── schedule.dart                  # ScheduleBlock · GeneratedSchedule
│   └── user_prefs.dart                # Working hours + break duration
├── services/
│   ├── auth_service.dart              # Supabase email sign-in/up/out
│   ├── gemini_service.dart            # Gemini API call + JSON parse + error messages
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
│       ├── home_screen.dart           # Today's task list + stats + generate button
│       ├── calendar_screen.dart       # Monthly calendar + per-day task view
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
- A free [Gemini API key](https://aistudio.google.com) (for schedule generation)

---

## Setup

### Step 1 — Create a Supabase project

1. Go to [supabase.com](https://supabase.com) and sign up for free
2. Create a new project (takes ~2 minutes to provision)
3. Go to **Settings → API** and copy:
   - **Project URL** — looks like `https://abcdefgh.supabase.co`
   - **anon public key** — a long string starting with `eyJ...`

Supabase email auth works out of the box — no extra config needed.

### Step 2 — (Optional) Set up cloud task sync

To back up tasks to the cloud, run the SQL in `supabase_setup.sql` in your Supabase project: **SQL Editor → New query → paste → Run**.

If you skip this step, tasks are still saved locally on device.

### Step 3 — Get a Gemini API key

1. Visit [aistudio.google.com](https://aistudio.google.com)
2. Sign in with your Google account
3. Click **Get API key → Create API key**
4. Copy the key — it starts with `AIzaSy...`

You can also paste the key inside the app after launch (Settings → Profile → Gemini API Key).

### Step 4 — Install Flutter dependencies

```bash
cd ai-scheduler
flutter pub get
```

### Step 5 — Run the app

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

> If you don't pass credentials the app still runs — auth will fail until you add them.

---

## First-time use

```
1. Open app → tap Sign up → create your account
2. Go to Profile tab (bottom right)
3. Follow the guide to get your free Gemini API key
4. Paste the key and tap Save Key
5. Go to Tasks → add a few tasks with deadlines and priorities
6. Go to Today (Home tab) → tap Generate Schedule
7. Gemini AI arranges everything into an optimized timeline
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
HomeScreen  ←→  CalendarScreen  ←→  TasksScreen  ←→  SettingsScreen
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
GeminiService.generate()
  - Builds structured prompt with tasks + working hours
  - POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent
        │
        ▼
Gemini returns JSON
  { "schedule": [...], "unscheduled_task_ids": [], "summary": "..." }
        │
        ▼
Parsed into GeneratedSchedule
  - Saved locally (SharedPreferences)
  - Displayed as timeline in HomeScreen
```

Gemini is called **directly from the Flutter app** — no server in between.
The API key is stored in iOS Keychain / Android Keystore via `flutter_secure_storage`.

---

## Gemini AI prompt

The app sends Gemini a structured prompt with:
- Today's date and day of week
- Each task: title, notes, deadline, duration, priority, preferred start time
- Your working window (default 09:00–18:00)
- Minimum break duration between tasks

Gemini is instructed to reply with **raw JSON only** (no markdown, no explanation).
The app strips any accidental code fences before parsing.

---

## Screen reference

| Screen | Route | Key features |
|---|---|---|
| Splash | `/splash` | Shown while auth resolves on cold start |
| Login | `/login` | Email/password · forgot password bottom sheet |
| Register | `/register` | Name + email + password + confirm |
| Today | `/` | Week strip · stats row · task list · generate button · schedule timeline |
| Calendar | `/calendar` | Monthly grid · dot indicators for task days · per-day stats · task list |
| Tasks | `/tasks` | List sorted by priority+deadline · swipe delete · undo snackbar |
| Add/Edit task | `/task/add` `/task/edit` | Priority picker · date picker · time picker |
| Settings | `/settings` | Step-by-step API key guide · working hours · break duration · sign out |

---

## Navigation

The app uses a bottom navigation bar with a centered floating action button (+) to add tasks quickly from any screen.

| Tab | Icon | Route |
|---|---|---|
| Task | Grid | `/` |
| Calendar | Calendar | `/calendar` |
| + | FAB | `/task/add` |
| Goal | Checklist | `/tasks` |
| Profile | Person | `/settings` |

---

## State management

All state is managed with **Riverpod** (`StateNotifierProvider`). Key providers:

| Provider | Type | Responsibility |
|---|---|---|
| `authProvider` | `AuthNotifier` | Login, signup, signout, session |
| `tasksProvider` | `TasksNotifier` | CRUD tasks, local persist, cloud sync |
| `scheduleProvider` | `ScheduleNotifier` | Generate, cache, and clear schedule |
| `apiKeyProvider` | `ApiKeyNotifier` | Secure read/write of Gemini API key |
| `prefsProvider` | `PrefsNotifier` | Working hours + break minutes |

---

## Data models

### Task

```dart
class Task {
  final String   id;
  final String   title;
  final String?  description;
  final DateTime deadline;
  final int      durationMinutes;
  final Priority priority;       // low | medium | high
  final String?  preferredTime;  // "HH:MM" or null
  final bool     completed;
}
```

### ScheduleBlock

```dart
class ScheduleBlock {
  final String   taskId;
  final String   taskTitle;
  final String   startTime;   // "HH:MM"
  final String   endTime;     // "HH:MM"
  final Priority priority;
}
```

### UserPrefs

```dart
class UserPrefs {
  final String workStart;   // default "09:00"
  final String workEnd;     // default "18:00"
  final int    breakMins;   // default 15
}
```

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
flutter build ios \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON=...

# Android APK
flutter build apk \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON=...

# Android App Bundle
flutter build appbundle \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON=...

# macOS
flutter build macos \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON=...
```

---

## Quick run script

For macOS, use the included `run.sh`:

```bash
export SUPABASE_URL=https://your-project.supabase.co
export SUPABASE_ANON=your-anon-key

chmod +x run.sh
./run.sh ios       # or android, macos
```

---

## Troubleshooting

**"Invalid API key" / "403 Forbidden" when generating**
→ Go to Profile → check the Gemini API key. It must start with `AIzaSy`. Get one free at aistudio.google.com.

**Auth fails / can't sign up**
→ Make sure `SUPABASE_URL` and `SUPABASE_ANON` are correct and that `https://` is included in the URL.

**Schedule never updates after adding tasks**
→ Tap "Regenerate Schedule" on the Home screen — schedules are not generated automatically.

**Tasks disappear after reinstall**
→ Local storage is wiped on uninstall. Enable cloud sync via `supabase_setup.sql` to persist across installs.

**Flutter version error**
→ Run `flutter upgrade` to get Flutter 3.16+, which is required for `WidgetStateProperty`.

**Rate limit error (429) from Gemini**
→ The free tier allows ~15 requests/minute. Wait 60 seconds and try again.

**"Model not found" (404) error**
→ The app uses `gemini-2.5-flash`. If unavailable in your region, update `GeminiService` to use `gemini-1.5-flash`.

---

## Dependencies

```yaml
flutter_riverpod: ^2.5.1       # State management
go_router: ^14.2.7             # Declarative routing
supabase_flutter: ^2.6.0       # Auth + cloud sync
shared_preferences: ^2.3.2     # Local key-value storage
flutter_secure_storage: ^9.2.2 # Encrypted API key storage (Keychain/Keystore)
dio: ^5.7.0                    # HTTP client for Gemini API
google_fonts: ^6.2.1           # DM Sans typeface
intl: ^0.19.0                  # Date/time formatting
url_launcher: ^6.3.0           # Open aistudio.google.com from within the app
```

---

## License

MIT