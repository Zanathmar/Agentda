// ── register_screen.dart ──────────────────────────────────────────────────────
// Save as: lib/screens/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _State();
}

class _State extends ConsumerState<RegisterScreen> {
  final _form  = GlobalKey<FormState>();
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _conf  = TextEditingController();
  bool  _show  = false;

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _pass.dispose(); _conf.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signUp(
      email: _email.text.trim(), password: _pass.text, name: _name.text.trim(),
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
      appBar: AppBar(
        backgroundColor: C.bg,
        leading: BackButton(onPressed: () => context.go('/login'), color: C.textPri),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Create account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: C.textPri)),
              const SizedBox(height: 6),
              const Text('Get organised in minutes',
                  style: TextStyle(fontSize: 15, color: C.textSec)),
              const SizedBox(height: 32),

              AppField(
                controller: _name,
                label:      'Name',
                hint:       'Your name',
                autofocus:  true,
                validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
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
                hint:       'At least 8 characters',
                obscure:    !_show,
                suffix: IconButton(
                  icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: C.textSec),
                  onPressed: () => setState(() => _show = !_show),
                ),
                validator: (v) => (v?.length ?? 0) < 8 ? 'At least 8 characters' : null,
              ),
              const SizedBox(height: 16),
              AppField(
                controller: _conf,
                label:      'Confirm password',
                hint:       '••••••••',
                obscure:    true,
                validator: (v) => v != _pass.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 28),

              PrimaryBtn(label: 'Create Account', loading: auth.busy, onPressed: _submit),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('Already have an account? ',
                    style: TextStyle(color: C.textSec, fontSize: 14)),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text('Sign in',
                      style: TextStyle(color: C.textPri, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}