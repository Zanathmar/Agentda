import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks     = ref.watch(tasksProvider);
    final pending   = tasks.where((t) => !t.completed).toList()
      ..sort((a, b) {
        final prio = b.priority.weight - a.priority.weight;
        if (prio != 0) return prio;
        return a.deadline.compareTo(b.deadline);
      });
    final completed = tasks.where((t) => t.completed).toList();

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: C.textPri),
            onPressed: () => context.push('/task/add'),
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const EmptyState(
              icon:     Icons.task_alt_outlined,
              title:    'No tasks yet',
              subtitle: 'Tap + to add your first task',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                if (pending.isNotEmpty) ...[
                  const SectionLabel('PENDING'),
                  ...pending.map((t) => _TaskCard(t)),
                  const SizedBox(height: 12),
                ],
                if (completed.isNotEmpty) ...[
                  const SectionLabel('COMPLETED'),
                  ...completed.map((t) => _TaskCard(t)),
                ],
              ],
            ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final Task t;
  const _TaskCard(this.t, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color   = C.priority(t.priority);
    final overdue = !t.completed && t.deadline.isBefore(DateTime.now());
    final dl      = DateFormat('dd.MM.yy').format(t.deadline);
    final time    = t.preferredTime ?? DateFormat('HH:mm').format(t.deadline);

    return Dismissible(
      key:       ValueKey(t.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: C.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: C.error),
      ),
      onDismissed: (_) {
        ref.read(tasksProvider.notifier).remove(t.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${t.title} deleted'),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white70,
            onPressed: () => ref.read(tasksProvider.notifier).add(t),
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color:        C.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: C.border),
        ),
        child: InkWell(
          onTap:        () => context.push('/task/edit', extra: t.id),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Priority bar
              Container(
                width: 3, height: 44,
                decoration: BoxDecoration(
                  color:        t.completed ? C.textMuted : color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title,
                    style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      t.completed ? C.textMuted : C.textPri,
                      decoration: t.completed ? TextDecoration.lineThrough : null,
                      decorationColor: C.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis),
                if (t.description != null && t.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(t.description!,
                      style: const TextStyle(fontSize: 12, color: C.textSec),
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.access_time_outlined, size: 11, color: C.textMuted),
                  const SizedBox(width: 3),
                  Text(time, style: const TextStyle(fontSize: 11, color: C.textMuted)),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today_outlined, size: 11, color: C.textMuted),
                  const SizedBox(width: 3),
                  Text(dl,
                      style: TextStyle(
                        fontSize: 11,
                        color: overdue ? C.error : C.textMuted,
                        fontWeight: overdue ? FontWeight.w600 : FontWeight.normal,
                      )),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: C.surface2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(t.priority.label.toLowerCase(),
                        style: const TextStyle(fontSize: 10, color: C.textSec)),
                  ),
                ]),
              ])),
              // Toggle
              GestureDetector(
                onTap: () => ref.read(tasksProvider.notifier).toggle(t.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color:  t.completed ? C.success : Colors.transparent,
                    border: Border.all(
                      color: t.completed ? C.success : C.border,
                      width: 1.5,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: t.completed
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}