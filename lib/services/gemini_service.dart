import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/models.dart';

class GeminiService {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90),
  ));

  Future<GeneratedSchedule> generate({
    required String apiKey,
    required List<Task> tasks,
    required UserPrefs prefs,
  }) async {
    if (tasks.isEmpty) {
      return GeneratedSchedule(
        date: DateTime.now(),
        blocks: [],
        unscheduledIds: [],
        summary: 'No tasks to schedule.',
      );
    }

    try {
      final res = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        options: Options(headers: {'content-type': 'application/json'}),
        data: {
          'contents': [
            {
              'parts': [
                {'text': _prompt(tasks, prefs)}
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 8192,
            'thinkingConfig': {
              'thinkingBudget': 0,
            },
          },
        },
      );

      final candidates = res.data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw Exception('Empty response from Gemini API.');
      }

      final text = candidates[0]['content']['parts'][0]['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw Exception('Gemini returned no text content.');
      }

      return _parse(text, tasks);
    } on DioException catch (e) {
      throw _friendly(e);
    } catch (e) {
      throw Exception('Failed to parse schedule: $e');
    }
  }

  String _prompt(List<Task> tasks, UserPrefs prefs) {
    final now = DateTime.now();
    final date = '${now.year}-${_p(now.month)}-${_p(now.day)}';
    final day = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ][now.weekday - 1];

    final list = tasks.map((t) => {
      'id': t.id,
      'title': t.title,
      'notes': t.description,
      'deadline': '${t.deadline.year}-${_p(t.deadline.month)}-${_p(t.deadline.day)}',
      'minutes': t.durationMinutes,
      'priority': t.priority.name,
      'prefer_start': t.preferredTime,
    }).toList();

    return '''
You are a personal productivity assistant. Create an optimized daily schedule for today ($date, $day).

TASKS TO SCHEDULE:
${jsonEncode(list)}

RULES:
- Work window: ${prefs.workStart}–${prefs.workEnd}
- Leave ${prefs.breakMins} minutes gap between every task
- Schedule high priority tasks earlier in the day
- If a task has a preferred start time, respect it
- Tasks due today must be included first
- Skip tasks that genuinely don't fit the work window

Reply with ONLY valid JSON — no markdown, no explanation:
{
  "schedule": [
    {"task_id": "<id>", "start_time": "HH:MM", "end_time": "HH:MM"}
  ],
  "unscheduled_task_ids": [],
  "summary": "One sentence about today's plan."
}
''';
  }

  GeneratedSchedule _parse(String raw, List<Task> tasks) {
    String s = raw.trim();
    if (s.startsWith('```json')) s = s.substring(7);
    else if (s.startsWith('```')) s = s.substring(3);
    if (s.endsWith('```')) s = s.substring(0, s.length - 3);
    s = s.trim();

    final Map<String, dynamic> d;
    try {
      d = jsonDecode(s) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Gemini returned invalid JSON. Raw output:\n$s');
    }

    final taskMap = {for (final t in tasks) t.id: t};

    final rawSchedule = d['schedule'];
    if (rawSchedule == null || rawSchedule is! List) {
      throw Exception('Missing or invalid "schedule" field in response.');
    }

    final blocks = rawSchedule.map((item) {
      final tid = item['task_id'] as String? ?? '';
      final task = taskMap[tid];
      return ScheduleBlock(
        taskId: tid,
        taskTitle: task?.title ?? '(unknown)',
        startTime: item['start_time'] as String? ?? '00:00',
        endTime: item['end_time'] as String? ?? '00:00',
        priority: task?.priority ?? Priority.medium,
      );
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return GeneratedSchedule(
      date: DateTime.now(),
      blocks: blocks,
      unscheduledIds: (d['unscheduled_task_ids'] as List? ?? []).cast<String>(),
      summary: d['summary'] as String? ?? '',
    );
  }

  Exception _friendly(DioException e) {
    final status = e.response?.statusCode;
    final googleMessage = e.response?.data?['error']?['message'] ?? e.message;

    if (status == 400) return Exception('Bad Request: $googleMessage');
    if (status == 403) return Exception('Invalid API key or API disabled: $googleMessage');
    if (status == 404) return Exception('Model not found (404): $googleMessage');
    if (status == 429) return Exception('Rate limit reached! Wait 60 seconds and try again.');
    if (status != null && status >= 500) return Exception('Gemini servers are down.');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Exception('No internet connection. Please check your network.');
    }

    return Exception('Google API Error ($status): $googleMessage');
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}