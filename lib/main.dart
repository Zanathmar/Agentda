import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme.dart';
import 'providers/providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/main/home_screen.dart';
import 'screens/main/tasks_screen.dart';
import 'screens/main/calendar_screen.dart';
import 'screens/main/add_edit_task_screen.dart';
import 'screens/main/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:                     Colors.transparent,
    statusBarIconBrightness:            Brightness.dark,
    systemNavigationBarColor:           C.bg,
    systemNavigationBarIconBrightness:  Brightness.dark,
  ));

  const supabaseUrl  = String.fromEnvironment('SUPABASE_URL',  defaultValue: '');
  const supabaseAnon = String.fromEnvironment('SUPABASE_ANON', defaultValue: '');

  assert(supabaseUrl.isNotEmpty,  'Missing --dart-define=SUPABASE_URL=...');
  assert(supabaseAnon.isNotEmpty, 'Missing --dart-define=SUPABASE_ANON=...');

  if (supabaseUrl.isEmpty || supabaseAnon.isEmpty) {
    throw Exception('Supabase credentials are not set.');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnon);

  runApp(const ProviderScope(child: App()));
}

// ── Router ────────────────────────────────────────────────────────────────────

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);
  return GoRouter(
    initialLocation:   '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth      = ref.read(authProvider);
      final isAuth    = auth.status == AuthStatus.authenticated;
      final isLoading = auth.status == AuthStatus.loading;
      final loc       = state.matchedLocation;
      final onAuth    = loc == '/login' || loc == '/register';
      final onSplash  = loc == '/splash';

      if (isLoading && !onSplash)  return '/splash';
      if (!isLoading && onSplash)  return isAuth ? '/' : '/login';
      if (!isAuth && !onAuth && !onSplash) return '/login';
      if (isAuth && onAuth)        return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash',   builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/',         builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
          GoRoute(path: '/tasks',    builder: (_, __) => const TasksScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
      GoRoute(path: '/task/add', builder: (_, __) => const AddEditTaskScreen()),
      GoRoute(
        path:    '/task/edit',
        builder: (_, s) => AddEditTaskScreen(taskId: s.extra as String),
      ),
    ],
  );
});

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

// ── App ───────────────────────────────────────────────────────────────────────

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title:                      'Agentda',
      theme:                      AppTheme.light,
      routerConfig:               ref.watch(_routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ── Shell ─────────────────────────────────────────────────────────────────────

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;

    int idx = 0;
    if (loc.startsWith('/calendar')) idx = 1;
    if (loc.startsWith('/tasks'))    idx = 2;
    if (loc.startsWith('/settings')) idx = 3;

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed:       () => context.push('/task/add'),
        backgroundColor: C.accent,
        foregroundColor: Colors.white,
        elevation:       0,
        shape:           const CircleBorder(),
        child:           const Icon(Icons.add, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color:       C.surface,
        elevation:   0,
        padding:     EdgeInsets.zero,
        height:      80,
        shape:       const CircularNotchedRectangle(),
        notchMargin: 8,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: C.border, width: 0.8)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavItem(icon: Icons.grid_view_rounded,       label: 'Task',     idx: 0, current: idx, path: '/'),
              _NavItem(icon: Icons.calendar_month_outlined, label: 'Calendar', idx: 1, current: idx, path: '/calendar'),
              const Expanded(child: SizedBox()),
              _NavItem(icon: Icons.checklist_rounded,       label: 'Goal',     idx: 2, current: idx, path: '/tasks'),
              _NavItem(icon: Icons.person_outline_rounded,  label: 'Profile',  idx: 3, current: idx, path: '/settings'),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int      idx;
  final int      current;
  final String   path;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.idx,
    required this.current,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final selected = idx == current;
    return Expanded(
      child: InkWell(
        onTap:        () => context.go(path),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:      MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: selected ? C.textPri : C.textMuted),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize:   10,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color:      selected ? C.textPri : C.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}