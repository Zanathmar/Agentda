// ── login_screen.dart ─────────────────────────────────────────────────────────
// Save as: lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _State();
}

class _State extends ConsumerState<LoginScreen> {
  final _form     = GlobalKey<FormState>();
  final _email    = TextEditingController();
  final _pass     = TextEditingController();
  bool  _showPass = false;

  @override
  void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signIn(
      email: _email.text.trim(), password: _pass.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Logo mark
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color:        C.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 28),
              const Text('Welcome back',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: C.textPri)),
              const SizedBox(height: 6),
              const Text('Sign in to continue',
                  style: TextStyle(fontSize: 15, color: C.textSec)),
              const SizedBox(height: 36),

              AppField(
                controller:   _email,
                label:        'Email',
                hint:         'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppField(
                controller: _pass,
                label:      'Password',
                hint:       '••••••••',
                obscure:    !_showPass,
                suffix: IconButton(
                  icon: Icon(_showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: C.textSec),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Password is required' : null,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showReset(context),
                  child: const Text('Forgot password?',
                      style: TextStyle(fontSize: 13, color: C.textSec)),
                ),
              ),
              const SizedBox(height: 8),

              PrimaryBtn(label: 'Sign In', loading: auth.busy, onPressed: _submit),
              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? ",
                    style: TextStyle(color: C.textSec, fontSize: 14)),
                GestureDetector(
                  onTap: () => context.go('/register'),
                  child: const Text('Sign up',
                      style: TextStyle(color: C.textPri, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showReset(BuildContext context) {
    final ctrl = TextEditingController(text: _email.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Reset password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.textPri)),
          const SizedBox(height: 6),
          const Text("We'll send a reset link to your email.",
              style: TextStyle(fontSize: 13, color: C.textSec)),
          const SizedBox(height: 18),
          AppField(controller: ctrl, label: 'Email', hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          PrimaryBtn(
            label:     'Send reset link',
            onPressed: () async {
              await ref.read(authProvider.notifier).resetPassword(ctrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reset link sent — check your email.')),
                );
              }
            },
          ),
        ]),
      ),
    );
  }
}