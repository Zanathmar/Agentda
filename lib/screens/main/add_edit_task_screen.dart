// Save as: lib/screens/main/add_edit_task_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class AddEditTaskScreen extends ConsumerStatefulWidget {
  final String? taskId;
  const AddEditTaskScreen({super.key, this.taskId});

  @override
  ConsumerState<AddEditTaskScreen> createState() => _State();
}

class _State extends ConsumerState<AddEditTaskScreen> {
  final _form   = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descC  = TextEditingController();
  final _durC   = TextEditingController(text: '60');

  DateTime   _deadline = DateTime.now().add(const Duration(days: 1));
  Priority   _priority = Priority.medium;
  TimeOfDay? _pref;
  bool       _saving   = false;

  bool  get _edit => widget.taskId != null;
  Task? get _task => _edit
      ? ref.read(tasksProvider).cast<Task?>().firstWhere(
          (t) => t!.id == widget.taskId, orElse: () => null)
      : null;

  @override
  void initState() {
    super.initState();
    final t = _task;
    if (t != null) {
      _titleC.text = t.title;
      _descC.text  = t.description ?? '';
      _durC.text   = t.durationMinutes.toString();
      _deadline    = t.deadline;
      _priority    = t.priority;
      if (t.preferredTime != null) {
        final p = t.preferredTime!.split(':');
        _pref = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
      }
    }
  }

  @override
  void dispose() { _titleC.dispose(); _descC.dispose(); _durC.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    final prefStr = _pref != null
        ? '${_pref!.hour.toString().padLeft(2, '0')}:${_pref!.minute.toString().padLeft(2, '0')}'
        : null;

    final notifier = ref.read(tasksProvider.notifier);

    if (_edit && _task != null) {
      await notifier.update(_task!.copyWith(
        title:           _titleC.text.trim(),
        description:     _descC.text.trim().isEmpty ? null : _descC.text.trim(),
        deadline:        _deadline,
        durationMinutes: int.parse(_durC.text),
        priority:        _priority,
        preferredTime:   prefStr,
      ));
    } else {
      await notifier.add(Task(
        id:              DateTime.now().millisecondsSinceEpoch.toString(),
        title:           _titleC.text.trim(),
        description:     _descC.text.trim().isEmpty ? null : _descC.text.trim(),
        deadline:        _deadline,
        durationMinutes: int.parse(_durC.text),
        priority:        _priority,
        preferredTime:   prefStr,
      ));
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text(_edit ? 'Edit Task' : 'New Task'),
        actions: [
          if (_edit)
            IconButton(
              icon:  const Icon(Icons.delete_outline),
              color: C.error,
              onPressed: () async {
                await ref.read(tasksProvider.notifier).remove(widget.taskId!);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            AppField(
              controller: _titleC,
              label:      'Task title',
              hint:       'What needs to be done?',
              autofocus:  !_edit,
              validator:  (v) => v!.trim().isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            AppField(
              controller: _descC,
              label:      'Notes (optional)',
              hint:       'Any extra details...',
              maxLines:   3,
            ),
            const SizedBox(height: 16),
            AppField(
              controller:   _durC,
              label:        'Duration (minutes)',
              hint:         'e.g. 60',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 5) return 'Minimum 5 minutes';
                if (n > 480) return 'Maximum 8 hours (480 min)';
                return null;
              },
            ),
            const SizedBox(height: 22),
            const SectionLabel('PRIORITY'),
            _PriorityPicker(value: _priority, onChanged: (p) => setState(() => _priority = p)),
            const SizedBox(height: 22),
            const SectionLabel('DEADLINE'),
            PickerRow(
              icon:  Icons.calendar_today_outlined,
              label: DateFormat('MMMM d, yyyy').format(_deadline),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _deadline,
                  firstDate:   DateTime.now(),
                  lastDate:    DateTime.now().add(const Duration(days: 365)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(primary: C.accent),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) setState(() => _deadline = d);
              },
            ),
            const SizedBox(height: 16),
            const SectionLabel('PREFERRED START TIME (optional)'),
            PickerRow(
              icon:  Icons.schedule_outlined,
              label: _pref?.format(context) ?? 'Any time',
              muted: _pref == null,
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: _pref ?? TimeOfDay.now(),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(primary: C.accent),
                    ),
                    child: child!,
                  ),
                );
                if (t != null) setState(() => _pref = t);
              },
              trailing: _pref != null
                  ? GestureDetector(
                      onTap: () => setState(() => _pref = null),
                      child: const Icon(Icons.close, size: 15, color: C.textMuted),
                    )
                  : null,
            ),
            const SizedBox(height: 32),
            PrimaryBtn(
              label:     _edit ? 'Save Changes' : 'Add Task',
              loading:   _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityPicker extends StatelessWidget {
  final Priority               value;
  final ValueChanged<Priority> onChanged;
  const _PriorityPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        children: Priority.values.map((p) {
          final sel   = value == p;
          final color = C.priority(p);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:        sel ? color.withOpacity(0.1) : C.surface,
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(
                      color: sel ? color : C.border,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Text(p.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                        color:      sel ? color : C.textSec,
                      )),
                ),
              ),
            ),
          );
        }).toList(),
      );
}