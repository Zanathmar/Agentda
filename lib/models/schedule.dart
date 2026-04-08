import 'task.dart';

class ScheduleBlock {
  final String   taskId;
  final String   taskTitle;
  final String   startTime;
  final String   endTime;
  final Priority priority;

  ScheduleBlock({
    required this.taskId,
    required this.taskTitle,
    required this.startTime,
    required this.endTime,
    required this.priority,
  });

  int get durationMinutes {
    final s = _toMins(startTime), e = _toMins(endTime);
    return e - s;
  }

  bool get isNow {
    final now = DateTime.now();
    final n   = now.hour * 60 + now.minute;
    return n >= _toMins(startTime) && n < _toMins(endTime);
  }

  static int _toMins(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  Map<String, dynamic> toJson() => {
        'taskId':    taskId,
        'taskTitle': taskTitle,
        'startTime': startTime,
        'endTime':   endTime,
        'priority':  priority.name,
      };

  factory ScheduleBlock.fromJson(Map<String, dynamic> j) => ScheduleBlock(
        taskId:    j['taskId']    as String,
        taskTitle: j['taskTitle'] as String,
        startTime: j['startTime'] as String,
        endTime:   j['endTime']   as String,
        priority:  Priority.values.firstWhere((p) => p.name == j['priority']),
      );
}

class GeneratedSchedule {
  final DateTime            date;
  final List<ScheduleBlock> blocks;
  final List<String>        unscheduledIds;
  final String              summary;

  GeneratedSchedule({
    required this.date,
    required this.blocks,
    required this.unscheduledIds,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'date':           date.toIso8601String(),
        'blocks':         blocks.map((b) => b.toJson()).toList(),
        'unscheduledIds': unscheduledIds,
        'summary':        summary,
      };

  factory GeneratedSchedule.fromJson(Map<String, dynamic> j) => GeneratedSchedule(
        date:           DateTime.parse(j['date'] as String),
        blocks:         (j['blocks'] as List)
            .map((b) => ScheduleBlock.fromJson(b as Map<String, dynamic>))
            .toList(),
        unscheduledIds: (j['unscheduledIds'] as List? ?? []).cast<String>(),
        summary:        j['summary'] as String? ?? '',
      );
}