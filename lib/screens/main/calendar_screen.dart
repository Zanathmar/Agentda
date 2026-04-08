import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final tasksOnDay = tasks.where((t) =>
      t.deadline.year  == _selectedDate.year &&
      t.deadline.month == _selectedDate.month &&
      t.deadline.day   == _selectedDate.day
    ).toList();

    final total     = tasksOnDay.length;
    final done      = tasksOnDay.where((t) => t.completed).length;
    final inProcess = tasksOnDay.where((t) => !t.completed).length;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(children: [
          // ── App bar ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  }),
                  child: const Icon(Icons.chevron_left, color: C.textSec),
                ),
                Text(
                  DateFormat('MMMM').format(_focusedMonth),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.textPri),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  }),
                  child: const Icon(Icons.chevron_right, color: C.textSec),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Day-of-week labels ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['Mo','Tu','We','Th','Fr','Sa','Su']
                  .map((d) => SizedBox(
                        width: 36,
                        child: Text(d,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: C.textMuted, fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // ── Calendar grid ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _CalendarGrid(
              focusedMonth: _focusedMonth,
              selectedDate: _selectedDate,
              tasks:        tasks,
              onSelect:     (d) => setState(() => _selectedDate = d),
            ),
          ),

          const SizedBox(height: 16),

          // ── Stats for selected day ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Result for these days',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.textSec),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color:        C.surface,
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: C.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _MiniStat('All task', total, '100%'),
                  Container(width: 1, height: 30, color: C.border),
                  _MiniStat('Done', done, total == 0 ? '0%' : '${(done/total*100).round()}%', color: C.success),
                  Container(width: 1, height: 30, color: C.border),
                  _MiniStat('In process', inProcess, total == 0 ? '0%' : '${(inProcess/total*100).round()}%', color: C.info),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 14),

          // ── Tasks for selected day ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text('Tasks for these days',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.textSec)),
            ]),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: tasksOnDay.isEmpty
                ? const Center(child: Text('No tasks on this day', style: TextStyle(color: C.textMuted, fontSize: 14)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: tasksOnDay.length,
                    itemBuilder: (_, i) => _CalendarTaskCard(task: tasksOnDay[i]),
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Calendar Grid ─────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  final DateTime    focusedMonth;
  final DateTime    selectedDate;
  final List<Task>  tasks;
  final void Function(DateTime) onSelect;

  const _CalendarGrid({
    required this.focusedMonth,
    required this.selectedDate,
    required this.tasks,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay  = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    // Monday = 1, offset
    final startOffset = firstDay.weekday - 1;
    final totalCells  = startOffset + lastDay.day;
    final rows        = (totalCells / 7).ceil();

    final today = DateTime.now();

    // Build task-day set for dot indicators
    final taskDays = tasks.map((t) =>
        '${t.deadline.year}-${t.deadline.month}-${t.deadline.day}').toSet();

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (col) {
            final cellIdx = row * 7 + col;
            final dayNum  = cellIdx - startOffset + 1;

            if (dayNum < 1 || dayNum > lastDay.day) {
              return const SizedBox(width: 36, height: 48);
            }

            final date     = DateTime(focusedMonth.year, focusedMonth.month, dayNum);
            final isToday  = date.day == today.day && date.month == today.month && date.year == today.year;
            final isSelected = date.day == selectedDate.day && date.month == selectedDate.month && date.year == selectedDate.year;
            final hasTasks = taskDays.contains('${date.year}-${date.month}-${date.day}');

            return GestureDetector(
              onTap: () => onSelect(date),
              child: SizedBox(
                width: 36, height: 48,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color:  isSelected ? C.accent : isToday ? C.surface2 : Colors.transparent,
                      shape:  BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: C.accent, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: Text('$dayNum',
                          style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                            color:      isSelected ? Colors.white : isToday ? C.accent : C.textPri,
                          )),
                    ),
                  ),
                  const SizedBox(height: 3),
                  if (hasTasks)
                    Container(
                      width: 4, height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? C.textMuted : C.accent,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 4),
                ]),
              ),
            );
          }),
        );
      }),
    );
  }
}

// ── Mini stat ─────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final String label, suffix;
  final int    value;
  final Color? color;
  const _MiniStat(this.label, this.value, this.suffix, {this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: C.textSec)),
          const SizedBox(height: 3),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color ?? C.textPri)),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(suffix, style: const TextStyle(fontSize: 9, color: C.textMuted)),
            ),
          ]),
        ],
      );
}

// ── Calendar task card ────────────────────────────────────────────────────────

class _CalendarTaskCard extends StatelessWidget {
  final Task task;
  const _CalendarTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = C.priority(task.priority);
    final time  = task.preferredTime ?? DateFormat('HH:mm').format(task.deadline);
    final dl    = DateFormat('dd.MM.yy').format(task.deadline);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        C.surface,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: C.border),
      ),
      child: Row(children: [
        Container(
          width: 3, height: 40,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.textPri)),
          if (task.description != null) ...[
            const SizedBox(height: 2),
            Text(task.description!, style: const TextStyle(fontSize: 12, color: C.textSec),
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
            Text(dl, style: const TextStyle(fontSize: 11, color: C.textMuted)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(4)),
              child: Text(task.priority.label.toLowerCase(),
                  style: const TextStyle(fontSize: 10, color: C.textSec)),
            ),
          ]),
        ])),
        if (task.completed)
          Container(
            width: 24, height: 24,
            decoration: const BoxDecoration(color: C.success, shape: BoxShape.circle),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
      ]),
    );
  }
}