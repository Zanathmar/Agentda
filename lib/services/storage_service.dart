import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _tasks    = 'tasks_v1';
  static const _schedule = 'schedule_v1';
  static const _prefs    = 'prefs_v1';
  static const _apiKeyK  = 'gemini_api_key';
  static const _userK    = 'user_data';

  static const _ss = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Tasks
  Future<List<Task>> loadTasks() async {
    final p   = await SharedPreferences.getInstance();
    final raw = p.getStringList(_tasks) ?? [];
    return raw.map((s) => Task.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_tasks, tasks.map((t) => jsonEncode(t.toJson())).toList());
  }

  // Schedule
  Future<GeneratedSchedule?> loadSchedule() async {
    final p   = await SharedPreferences.getInstance();
    final raw = p.getString(_schedule);
    if (raw == null) return null;
    return GeneratedSchedule.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSchedule(GeneratedSchedule s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_schedule, jsonEncode(s.toJson()));
  }

  Future<void> clearSchedule() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_schedule);
  }

  // Prefs
  Future<UserPrefs> loadPrefs() async {
    final p   = await SharedPreferences.getInstance();
    final raw = p.getString(_prefs);
    if (raw == null) return const UserPrefs();
    return UserPrefs.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> savePrefs(UserPrefs prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefs, jsonEncode(prefs.toJson()));
  }

  // API key — secure storage only
  Future<String?> loadApiKey()        => _ss.read(key: _apiKeyK);
  Future<void>    saveApiKey(String k) => _ss.write(key: _apiKeyK, value: k);
  Future<void>    clearApiKey()        => _ss.delete(key: _apiKeyK);

  // User session (local cache for offline display)
  Future<AppUser?> loadUser() async {
    final raw = await _ss.read(key: _userK);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(AppUser u)  => _ss.write(key: _userK, value: jsonEncode(u.toJson()));
  Future<void> clearUser()          => _ss.delete(key: _userK);

  Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    await _ss.deleteAll();
  }
}