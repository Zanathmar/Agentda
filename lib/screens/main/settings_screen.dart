import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiKey = ref.watch(apiKeyProvider);
    final prefs  = ref.watch(prefsProvider);
    final user   = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(backgroundColor: C.bg, title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          if (user != null) _UserCard(user: user),
          const SizedBox(height: 16),
          _ApiKeySection(apiKey: apiKey),
          const SizedBox(height: 16),
          _WorkingHoursSection(prefs: prefs),
          const SizedBox(height: 16),
          _ScheduleSection(),
          const SizedBox(height: 24),
          _SettingsRow(
            icon:  Icons.logout_outlined,
            label: 'Sign Out',
            color: C.error,
            onTap: () => _confirmSignOut(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Sign out?'),
        content: const Text('Your tasks are saved and will be here when you return.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(context); ref.read(authProvider.notifier).signOut(); },
            child: const Text('Sign Out', style: TextStyle(color: C.error)),
          ),
        ],
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user.displayName.trim().split(' ')
        .take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: C.border),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color:  C.surface2,
            shape:  BoxShape.circle,
            border: Border.all(color: C.border),
          ),
          child: Center(child: Text(initials,
              style: const TextStyle(color: C.textPri, fontSize: 18, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(user.displayName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.textPri)),
          Text(user.email,
              style: const TextStyle(fontSize: 12, color: C.textSec)),
        ]),
      ]),
    );
  }
}

// ── Settings row ──────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color?   color;
  final VoidCallback onTap;
  const _SettingsRow({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:        C.surface,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: C.border),
          ),
          child: Row(children: [
            Icon(icon, size: 18, color: color ?? C.textSec),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(fontSize: 14, color: color ?? C.textPri, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 18, color: C.textMuted),
          ]),
        ),
      );
}

// ── Card wrapper ──────────────────────────────────────────────────────────────

class _SCard extends StatelessWidget {
  final IconData icon;
  final String   title;
  final Widget   child;
  const _SCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:        C.surface,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: C.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 15, color: C.textSec),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.textPri)),
          ]),
          const SizedBox(height: 14),
          child,
        ]),
      );
}

// ── API Key section ───────────────────────────────────────────────────────────

class _ApiKeySection extends ConsumerStatefulWidget {
  final String? apiKey;
  const _ApiKeySection({required this.apiKey});

  @override
  ConsumerState<_ApiKeySection> createState() => _ApiKeySectionState();
}

class _ApiKeySectionState extends ConsumerState<_ApiKeySection> {
  final _ctrl    = TextEditingController();
  bool  _visible = false;
  bool  _saved   = false;

  @override
  void initState() {
    super.initState();
    if (widget.apiKey != null) _ctrl.text = widget.apiKey!;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) return;
    await ref.read(apiKeyProvider.notifier).save(key);
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) => _SCard(
        icon:  Icons.key_outlined,
        title: 'Gemini API Key',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (widget.apiKey == null) ...[
            _StepGuide(),
            const SizedBox(height: 12),
          ] else ...[
            const Text('Stored securely on this device.',
                style: TextStyle(fontSize: 12, color: C.textSec)),
            const SizedBox(height: 10),
          ],
          AppField(
            controller: _ctrl,
            label:      'API Key',
            hint:       'AIza...',
            obscure:    !_visible,
            suffix: IconButton(
              icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 17, color: C.textSec),
              onPressed: () => setState(() => _visible = !_visible),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: PrimaryBtn(
              label:     _saved ? 'Saved ✓' : 'Save Key',
              onPressed: _save,
            )),
            if (widget.apiKey != null) ...[
              const SizedBox(width: 10),
              IconButton(
                icon:    const Icon(Icons.delete_outline, color: C.error),
                tooltip: 'Remove',
                onPressed: () { ref.read(apiKeyProvider.notifier).clear(); _ctrl.clear(); },
              ),
            ],
          ]),
        ]),
      );
}

class _StepGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.surface2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('How to get a free key:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.textPri)),
          const SizedBox(height: 8),
          ...[
            '1. Visit aistudio.google.com',
            '2. Sign in with your Google account',
            '3. Click Get API key → Create API key',
            '4. Paste it below',
          ].map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(s, style: const TextStyle(fontSize: 12, color: C.textSec)),
              )),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://aistudio.google.com'),
                mode: LaunchMode.externalApplication),
            child: const Text('Open aistudio.google.com →',
                style: TextStyle(fontSize: 12, color: C.info, fontWeight: FontWeight.w500)),
          ),
        ]),
      );
}

// ── Working hours section ─────────────────────────────────────────────────────

class _WorkingHoursSection extends ConsumerWidget {
  final UserPrefs prefs;
  const _WorkingHoursSection({required this.prefs});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _SCard(
        icon:  Icons.access_time_outlined,
        title: 'Working Hours',
        child: Column(children: [
          Row(children: [
            Expanded(child: _TimePicker(
              label:     'Start',
              time:      prefs.workStart,
              onChanged: (t) => ref.read(prefsProvider.notifier).update(prefs.copyWith(workStart: t)),
            )),
            const SizedBox(width: 12),
            Expanded(child: _TimePicker(
              label:     'End',
              time:      prefs.workEnd,
              onChanged: (t) => ref.read(prefsProvider.notifier).update(prefs.copyWith(workEnd: t)),
            )),
          ]),
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Break between tasks',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.textSec)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              value: prefs.breakMins,
              dropdownColor: C.surface,
              style: const TextStyle(color: C.textPri, fontSize: 14),
              decoration: InputDecoration(
                filled: true, fillColor: C.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: C.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: C.border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              ),
              items: [5, 10, 15, 20, 30]
                  .map((m) => DropdownMenuItem(value: m, child: Text('$m minutes')))
                  .toList(),
              onChanged: (v) {
                if (v != null) ref.read(prefsProvider.notifier).update(prefs.copyWith(breakMins: v));
              },
            ),
          ]),
        ]),
      );
}

class _TimePicker extends StatelessWidget {
  final String label, time;
  final ValueChanged<String> onChanged;
  const _TimePicker({required this.label, required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.textSec)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final p = time.split(':');
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.light(primary: C.accent)),
                child: child!,
              ),
            );
            if (t != null)
              onChanged('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
            decoration: BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: C.border)),
            child: Row(children: [
              const Icon(Icons.access_time, size: 15, color: C.textSec),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(fontSize: 14, color: C.textPri)),
            ]),
          ),
        ),
      ]);
}

// ── Schedule section ──────────────────────────────────────────────────────────

class _ScheduleSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => _SCard(
        icon:  Icons.auto_awesome_outlined,
        title: 'Schedule',
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: C.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.delete_sweep_outlined, color: C.error, size: 18),
          ),
          title: const Text('Clear today\'s schedule',
              style: TextStyle(fontSize: 14, color: C.textPri)),
          subtitle: const Text('Will regenerate next time',
              style: TextStyle(fontSize: 12, color: C.textSec)),
          trailing: const Icon(Icons.chevron_right, color: C.textMuted, size: 18),
          onTap: () {
            ref.read(scheduleProvider.notifier).clear();
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Schedule cleared')));
          },
        ),
      );
}