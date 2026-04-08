import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks  = ref.watch(tasksProvider);
    final user   = ref.watch(authProvider).user;
    final sched  = ref.watch(scheduleProvider);
    final prefs  = ref.watch(prefsProvider);
    final apiKey = ref.watch(apiKeyProvider);

    final pending   = tasks.where((t) => !t.completed).length;
    final done      = tasks.where((t) => t.completed).length;
    final inProcess = tasks.where((t) => !t.completed && t.deadline.difference(DateTime.now()).inDays <= 1).length;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _Header(user: user)),
          const SliverToBoxAdapter(child: _WeekStrip()),
          SliverToBoxAdapter(
            child: _StatsRow(total: tasks.length, done: done, inProcess: inProcess),
          ),
          SliverToBoxAdapter(
            child: _GenerateArea(sched: sched, tasks: tasks, prefs: prefs, apiKey: apiKey),
          ),
          if (sched.schedule != null && sched.schedule!.blocks.isNotEmpty)
            SliverToBoxAdapter(child: _ScheduleSection(sched: sched.schedule!)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.textPri)),
                  GestureDetector(
                    onTap: () => context.go('/tasks'),
                    child: const Text('See all', style: TextStyle(fontSize: 13, color: C.textSec)),
                  ),
                ],
              ),
            ),
          ),
          if (tasks.isEmpty)
            const SliverToBoxAdapter(
              child: EmptyState(
                icon:     Icons.task_alt_outlined,
                title:    'No tasks yet',
                subtitle: 'Tap + to add your first task',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final sorted = [...tasks]..sort((a, b) => a.deadline.compareTo(b.deadline));
                    final t = sorted[i];
                    return _HomeTaskCard(task: t);
                  },
                  childCount: tasks.length > 5 ? 5 : tasks.length,
                ),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final AppUser? user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your task tracking',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.textPri),
          ),
          GestureDetector(
            onTap: () => context.go('/settings'),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color:  C.surface2,
                shape:  BoxShape.circle,
                border: Border.all(color: C.border),
              ),
              child: const Icon(Icons.notifications_outlined, size: 18, color: C.textSec),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week strip ────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context) {
    final today  = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final days   = List.generate(7, (i) => monday.add(Duration(days: i)));
    final labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final d = days[i];
          final isToday = d.day == today.day && d.month == today.month;
          return _DayChip(label: labels[i], day: d.day, isToday: isToday);
        }),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final int    day;
  final bool   isToday;
  const _DayChip({required this.label, required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38, height: 58,
      decoration: BoxDecoration(
        color:        isToday ? C.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label,
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w500,
              color:      isToday ? Colors.white70 : C.textMuted,
            )),
        const SizedBox(height: 4),
        Text('$day',
            style: TextStyle(
              fontSize:   15,
              fontWeight: FontWeight.w700,
              color:      isToday ? Colors.white : C.textPri,
            )),
      ]),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total, done, inProcess;
  const _StatsRow({required this.total, required this.done, required this.inProcess});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color:        C.surface,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: C.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _Stat(label: 'All task', value: total, suffix: '100%'),
          _Divider(),
          _Stat(label: 'Done', value: done,
              suffix: total == 0 ? '0%' : '${(done / total * 100).round()}%',
              color: C.success),
          _Divider(),
          _Stat(label: 'In process', value: inProcess,
              suffix: total == 0 ? '0%' : '${(inProcess / total * 100).round()}%',
              color: C.info),
        ]),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, suffix;
  final int    value;
  final Color? color;
  const _Stat({required this.label, required this.value, required this.suffix, this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: C.textSec)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$value',
                style: TextStyle(
                  fontSize:   26,
                  fontWeight: FontWeight.w700,
                  color:      color ?? C.textPri,
                )),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(suffix,
                  style: const TextStyle(fontSize: 10, color: C.textMuted)),
            ),
          ]),
        ],
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: C.border);
}

// ── Generate area ─────────────────────────────────────────────────────────────

class _GenerateArea extends ConsumerWidget {
  final ScheduleState sched;
  final List<Task>    tasks;
  final UserPrefs     prefs;
  final String?       apiKey;

  const _GenerateArea({required this.sched, required this.tasks, required this.prefs, required this.apiKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generating = sched.status == GenStatus.generating;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(children: [
        if (sched.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InfoBanner(message: sched.error!, color: C.error, icon: Icons.error_outline),
          ),

        if (apiKey == null)
          _NoKeyCard()
        else if (generating)
          _GeneratingPill()
        else
          ElevatedButton.icon(
            onPressed: () => ref.read(scheduleProvider.notifier).generate(
              apiKey: apiKey!, tasks: tasks, prefs: prefs,
            ),
            icon:  const Icon(Icons.auto_awesome, size: 18),
            label: Text(sched.schedule != null ? 'Regenerate Schedule' : 'Generate Schedule'),
          ),
      ]),
    );
  }
}

class _NoKeyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.go('/settings'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        C.surface,
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: C.border),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.key_outlined, color: C.textSec, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Set up your Gemini API key', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.textPri)),
                SizedBox(height: 2),
                Text('Required to generate schedules', style: TextStyle(fontSize: 12, color: C.textSec)),
              ]),
            ),
            const Icon(Icons.chevron_right, color: C.textMuted, size: 18),
          ]),
        ),
      );
}

class _GeneratingPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color:        C.surface,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: C.border),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: C.textSec)),
          SizedBox(width: 12),
          Text('Building your schedule…', style: TextStyle(fontSize: 14, color: C.textSec)),
        ]),
      );
}

// ── Schedule section ──────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final GeneratedSchedule sched;
  const _ScheduleSection({required this.sched});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Today\'s Schedule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.textPri)),
          Text(DateFormat('MMM d').format(sched.date),
              style: const TextStyle(fontSize: 13, color: C.textSec)),
        ]),
        if (sched.summary.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(sched.summary,
              style: const TextStyle(fontSize: 13, color: C.textSec, height: 1.4)),
        ],
        const SizedBox(height: 12),
        ...sched.blocks.map((b) => _ScheduleBlockCard(block: b)),
        if (sched.unscheduledIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:        C.surface,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: C.border),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_outlined, size: 15, color: C.warning),
              const SizedBox(width: 8),
              Text('${sched.unscheduledIds.length} task(s) didn\'t fit the work window',
                  style: const TextStyle(fontSize: 12, color: C.textSec)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _ScheduleBlockCard extends StatelessWidget {
  final ScheduleBlock block;
  const _ScheduleBlockCard({required this.block});

  @override
  Widget build(BuildContext context) {
    final color  = C.priority(block.priority);
    final isNow  = block.isNow;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        isNow ? C.accent.withOpacity(0.04) : C.surface,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: isNow ? C.accent.withOpacity(0.3) : C.border),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(block.startTime,
              style: TextStyle(
                fontSize:   12,
                fontWeight: FontWeight.w600,
                color:      isNow ? C.accent : C.textSec,
              )),
          const SizedBox(height: 2),
          Text(block.endTime,
              style: const TextStyle(fontSize: 11, color: C.textMuted)),
        ]),
        const SizedBox(width: 12),
        Container(
          width: 3, height: 36,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(block.taskTitle,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.textPri),
              overflow: TextOverflow.ellipsis),
          Text('${block.durationMinutes} min',
              style: const TextStyle(fontSize: 11, color: C.textMuted)),
        ])),
        if (isNow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:        C.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Now',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
      ]),
    );
  }
}

// ── Home Task Card ────────────────────────────────────────────────────────────

class _HomeTaskCard extends ConsumerWidget {
  final Task task;
  const _HomeTaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color   = C.priority(task.priority);
    final overdue = !task.completed && task.deadline.isBefore(DateTime.now());
    final dl      = DateFormat('dd.MM.yy').format(task.deadline);
    final time    = task.preferredTime ?? DateFormat('HH:mm').format(task.deadline);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: C.border),
      ),
      child: InkWell(
        onTap:        () => context.push('/task/edit', extra: task.id),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 3, height: 44,
              decoration: BoxDecoration(
                color:        task.completed ? C.textMuted : color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title,
                  style: TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w600,
                    color:      task.completed ? C.textMuted : C.textPri,
                    decoration: task.completed ? TextDecoration.lineThrough : null,
                    decorationColor: C.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis),
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(task.description!,
                    style: const TextStyle(fontSize: 12, color: C.textSec),
                    overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time_outlined, size: 11, color: C.textMuted),
                const SizedBox(width: 3),
                Text(time, style: const TextStyle(fontSize: 11, color: C.textMuted)),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_today_outlined, size: 11, color: C.textMuted),
                const SizedBox(width: 3),
                Text(dl,
                    style: TextStyle(
                      fontSize: 11,
                      color: overdue ? C.error : C.textMuted,
                    )),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color:        C.surface2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(task.priority.label.toLowerCase(),
                      style: const TextStyle(fontSize: 10, color: C.textSec)),
                ),
              ]),
            ])),
            GestureDetector(
              onTap: () => ref.read(tasksProvider.notifier).toggle(task.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color:  task.completed ? C.success : Colors.transparent,
                  border: Border.all(
                    color: task.completed ? C.success : C.border,
                    width: 1.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: task.completed
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}