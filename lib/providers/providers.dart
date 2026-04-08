import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_sync.dart';

// ── Services ──────────────────────────────────────────────────────────────────

final storageProvider  = Provider((_) => StorageService());
final geminiProvider   = Provider((_) => GeminiService());
final authSvcProvider  = Provider((ref) => AuthService(ref.read(storageProvider)));
final supabaseSyncProv = Provider((_) => SupabaseSync());

// ── Auth ──────────────────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AppUser?   user;
  final String?    error;
  final bool       busy;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.error,
    this.busy = false,
  });

  AuthState copyWith({AuthStatus? status, AppUser? user, String? error, bool? busy}) =>
      AuthState(
        status: status ?? this.status,
        user:   user   ?? this.user,
        error:  error,
        busy:   busy   ?? this.busy,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _svc;

  AuthNotifier(this._svc) : super(const AuthState()) {
    _init();
  }

  void _init() {
    if (_svc.isLoggedIn) {
      state = AuthState(status: AuthStatus.authenticated, user: _svc.currentUser);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> signUp({required String email, required String password, required String name}) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final user = await _svc.signUp(email: email, password: password, name: name);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(busy: false, error: _msg(e));
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = state.copyWith(busy: true, error: null);
    try {
      final user = await _svc.signIn(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(busy: false, error: _msg(e));
    }
  }

  Future<void> signOut() async {
    await _svc.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(busy: true, error: null);
    try {
      await _svc.resetPassword(email);
      state = state.copyWith(busy: false);
    } catch (e) {
      state = state.copyWith(busy: false, error: _msg(e));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authSvcProvider));
});

// ── API Key ───────────────────────────────────────────────────────────────────

class ApiKeyNotifier extends StateNotifier<String?> {
  final StorageService _s;
  ApiKeyNotifier(this._s) : super(null) { _load(); }

  Future<void> _load()       async => state = await _s.loadApiKey();
  Future<void> save(String k) async { await _s.saveApiKey(k); state = k; }
  Future<void> clear()        async { await _s.clearApiKey(); state = null; }
}

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String?>((ref) {
  return ApiKeyNotifier(ref.read(storageProvider));
});

// ── Preferences ───────────────────────────────────────────────────────────────

class PrefsNotifier extends StateNotifier<UserPrefs> {
  final StorageService _s;
  PrefsNotifier(this._s) : super(const UserPrefs()) { _load(); }

  Future<void> _load()               async => state = await _s.loadPrefs();
  Future<void> update(UserPrefs p)   async { await _s.savePrefs(p); state = p; }
}

final prefsProvider = StateNotifierProvider<PrefsNotifier, UserPrefs>((ref) {
  return PrefsNotifier(ref.read(storageProvider));
});

// ── Tasks ─────────────────────────────────────────────────────────────────────

class TasksNotifier extends StateNotifier<List<Task>> {
  final StorageService _s;
  final SupabaseSync   _cloud;
  TasksNotifier(this._s, this._cloud) : super([]) { _load(); }

  Future<void> _load() async {
    final local = await _s.loadTasks();
    state = local;

    final remote = await _cloud.fetchTasks();
    if (remote.isNotEmpty) {
      final merged = {...{for (var t in local) t.id: t},
                      ...{for (var t in remote) t.id: t}}.values.toList();
      state = merged;
      await _s.saveTasks(merged);
    }
  }

  Future<void> add(Task t)       async { state = [...state, t]; await _persist(); await _cloud.upsertTasks(state); }
  Future<void> update(Task t)    async { state = state.map((x) => x.id == t.id ? t : x).toList(); await _persist(); await _cloud.upsertTasks(state); }
  Future<void> remove(String id) async { state = state.where((t) => t.id != id).toList(); await _persist(); await _cloud.deleteTask(id); }
  Future<void> toggle(String id) async {
    state = state.map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t).toList();
    await _persist();
    await _cloud.upsertTasks(state);
  }
  Future<void> _persist() => _s.saveTasks(state);
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier(ref.read(storageProvider), ref.read(supabaseSyncProv));
});

// ── Schedule ──────────────────────────────────────────────────────────────────

enum GenStatus { idle, generating, done, error }

class ScheduleState {
  final GeneratedSchedule? schedule;
  final GenStatus          status;
  final String?            error;

  const ScheduleState({this.schedule, this.status = GenStatus.idle, this.error});

  ScheduleState copy({GeneratedSchedule? schedule, GenStatus? status, String? error}) =>
      ScheduleState(
        schedule: schedule ?? this.schedule,
        status:   status   ?? this.status,
        error:    error,
      );
}

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final StorageService _s;
  final GeminiService  _ai;

  ScheduleNotifier(this._s, this._ai) : super(const ScheduleState()) { _load(); }

  Future<void> _load() async {
    final saved = await _s.loadSchedule();
    if (saved != null) state = ScheduleState(schedule: saved, status: GenStatus.done);
  }

  Future<void> generate({
    required String     apiKey,
    required List<Task> tasks,
    required UserPrefs  prefs,
  }) async {
    final pending = tasks.where((t) => !t.completed).toList();
    if (pending.isEmpty) {
      state = state.copy(status: GenStatus.error, error: 'Add at least one task first.');
      return;
    }
    state = state.copy(status: GenStatus.generating, error: null);
    try {
      final s = await _ai.generate(apiKey: apiKey, tasks: pending, prefs: prefs);
      await _s.saveSchedule(s);
      state = ScheduleState(schedule: s, status: GenStatus.done);
    } catch (e) {
      state = state.copy(status: GenStatus.error, error: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clear() { _s.clearSchedule(); state = const ScheduleState(); }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  return ScheduleNotifier(ref.read(storageProvider), ref.read(geminiProvider));
});