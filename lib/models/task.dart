enum Priority { low, medium, high }

extension PriorityX on Priority {
  String get label  => name[0].toUpperCase() + name.substring(1);
  int    get weight => index;
}

class Task {
  final String   id;
  final String   title;
  final String?  description;
  final DateTime deadline;
  final int      durationMinutes;
  final Priority priority;
  final String?  preferredTime;
  final bool     completed;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.deadline,
    required this.durationMinutes,
    required this.priority,
    this.preferredTime,
    this.completed = false,
  });

  Task copyWith({
    String?   title,
    String?   description,
    DateTime? deadline,
    int?      durationMinutes,
    Priority? priority,
    String?   preferredTime,
    bool?     completed,
  }) => Task(
        id:              id,
        title:           title           ?? this.title,
        description:     description     ?? this.description,
        deadline:        deadline        ?? this.deadline,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        priority:        priority        ?? this.priority,
        preferredTime:   preferredTime   ?? this.preferredTime,
        completed:       completed       ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'id':              id,
        'title':           title,
        'description':     description,
        'deadline':        deadline.toIso8601String(),
        'durationMinutes': durationMinutes,
        'priority':        priority.name,
        'preferredTime':   preferredTime,
        'completed':       completed,
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id:              j['id']              as String,
        title:           j['title']           as String,
        description:     j['description']     as String?,
        deadline:        DateTime.parse(j['deadline'] as String),
        durationMinutes: j['durationMinutes'] as int,
        priority:        Priority.values.firstWhere((p) => p.name == j['priority']),
        preferredTime:   j['preferredTime']   as String?,
        completed:       j['completed']       as bool? ?? false,
      );
}