import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class SupabaseSync {
  static SupabaseClient get _sb => Supabase.instance.client;

  bool get available {
    try {
      return _sb.auth.currentSession != null;
    } catch (_) {
      return false;
    }
  }

  String? get _uid => _sb.auth.currentUser?.id;

  Future<void> upsertTasks(List<Task> tasks) async {
    if (!available || _uid == null) return;
    try {
      await _sb.from('tasks').upsert(
        tasks.map((t) => {
          'id':               t.id,
          'user_id':          _uid,
          'title':            t.title,
          'description':      t.description,
          'deadline':         t.deadline.toIso8601String(),
          'duration_minutes': t.durationMinutes,  // snake_case matches DB column
          'priority':         t.priority.name,
          'preferred_time':   t.preferredTime,
          'completed':        t.completed,
        }).toList(),
      );
    } catch (e) {
      // ignore — sync is best-effort
    }
  }

  Future<void> deleteTask(String id) async {
    if (!available || _uid == null) return;
    try {
      await _sb.from('tasks').delete().eq('id', id).eq('user_id', _uid!);
    } catch (_) {}
  }

  Future<List<Task>> fetchTasks() async {
    if (!available || _uid == null) return [];
    try {
      final rows = await _sb
          .from('tasks')
          .select()
          .eq('user_id', _uid!)
          .order('deadline');

      return (rows as List).map((r) => Task(
            id:              r['id'] as String,
            title:           r['title'] as String,
            description:     r['description'] as String?,
            deadline:        DateTime.parse(r['deadline'] as String),
            durationMinutes: r['duration_minutes'] as int,  // snake_case from DB
            priority:        Priority.values.firstWhere((p) => p.name == r['priority']),
            preferredTime:   r['preferred_time'] as String?,
            completed:       r['completed'] as bool? ?? false,
          )).toList();
    } catch (_) {
      return [];
    }
  }
}