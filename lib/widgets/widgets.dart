import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme.dart';

// ── Labelled text field ───────────────────────────────────────────────────────

class AppField extends StatelessWidget {
  final TextEditingController controller;
  final String  label;
  final String? hint;
  final int     maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool    obscure;
  final bool    autofocus;

  const AppField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines    = 1,
    this.keyboardType,
    this.validator,
    this.suffix,
    this.obscure   = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.textSec)),
          const SizedBox(height: 6),
          TextFormField(
            controller:   controller,
            maxLines:     maxLines,
            keyboardType: keyboardType,
            validator:    validator,
            obscureText:  obscure,
            autofocus:    autofocus,
            style:        const TextStyle(color: C.textPri, fontSize: 15),
            decoration:   InputDecoration(hintText: hint, suffixIcon: suffix),
          ),
        ],
      );
}

// ── Primary button ────────────────────────────────────────────────────────────

class PrimaryBtn extends StatelessWidget {
  final String        label;
  final VoidCallback? onPressed;
  final bool          loading;
  final IconData?     icon;

  const PrimaryBtn({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                Text(label),
              ]),
      );
}

// ── Priority chip ─────────────────────────────────────────────────────────────

class PriorityChip extends StatelessWidget {
  final Priority priority;
  const PriorityChip(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = C.priority(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

class InfoBanner extends StatelessWidget {
  final String   message;
  final Color    color;
  final IconData icon;

  const InfoBanner({super.key, required this.message, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: color, height: 1.5))),
        ]),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   subtitle;

  const EmptyState({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color:  C.surface2,
                shape:  BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: C.textMuted),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: C.textPri),
                textAlign: TextAlign.center),
            const SizedBox(height: 7),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: C.textSec, height: 1.6),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ── Section label ─────────────────────────────────────────────────────────────

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: C.textMuted, letterSpacing: .8)),
      );
}

// ── Picker row ────────────────────────────────────────────────────────────────

class PickerRow extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final bool         muted;
  final VoidCallback onTap;
  final Widget?      trailing;

  const PickerRow({super.key, required this.icon, required this.label, required this.onTap, this.muted = false, this.trailing});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color:        C.surface,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: C.border),
          ),
          child: Row(children: [
            Icon(icon, size: 17, color: C.textSec),
            const SizedBox(width: 10),
            Expanded(child: Text(label,
                style: TextStyle(fontSize: 14, color: muted ? C.textMuted : C.textPri))),
            trailing ?? const Icon(Icons.chevron_right, color: C.textMuted, size: 17),
          ]),
        ),
      );
}