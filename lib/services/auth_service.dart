import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage;
  AuthService(this._storage);

  static SupabaseClient get _sb => Supabase.instance.client;

  bool get isLoggedIn => _sb.auth.currentSession != null;

  AppUser? get currentUser {
    final u = _sb.auth.currentUser;
    if (u == null) return null;
    return AppUser(
      id:    u.id,
      email: u.email ?? '',
      name:  u.userMetadata?['name'] as String?,
    );
  }

  Stream<AppUser?> get authStream => _sb.auth.onAuthStateChange.map((e) {
        final u = e.session?.user;
        if (u == null) return null;
        return AppUser(
          id:    u.id,
          email: u.email ?? '',
          name:  u.userMetadata?['name'] as String?,
        );
      });

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final res = await _sb.auth.signUp(
        email:    email,
        password: password,
        data:     {'name': name},
      );
      if (res.user == null) throw Exception('Sign-up failed. Please try again.');
      final user = AppUser(id: res.user!.id, email: email, name: name);
      await _storage.saveUser(user);
      return user;
    } on AuthApiException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<AppUser> signIn({required String email, required String password}) async {
    try {
      final res = await _sb.auth.signInWithPassword(email: email, password: password);
      if (res.user == null) throw Exception('Wrong email or password.');
      final user = AppUser(
        id:    res.user!.id,
        email: email,
        name:  res.user!.userMetadata?['name'] as String?,
      );
      await _storage.saveUser(user);
      return user;
    } on AuthApiException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> signOut() async {
    try {
      await _sb.auth.signOut();
      await _storage.clearUser();
    } on AuthApiException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _sb.auth.resetPasswordForEmail(email);
    } on AuthApiException catch (e) {
      throw Exception(_friendlyAuthError(e));
    }
  }

  /// Converts Supabase error codes into human-readable messages.
  String _friendlyAuthError(AuthApiException e) {
    switch (e.code) {
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please wait a few minutes and try again.';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with this email already exists. Try signing in.';
      case 'invalid_credentials':
      case 'invalid_login_credentials':
        return 'Wrong email or password. Please try again.';
      case 'email_not_confirmed':
        return 'Please verify your email before signing in.';
      case 'weak_password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'over_request_rate_limit':
        return 'Too many requests. Please slow down and try again.';
      case 'network_failure':
        return 'No internet connection. Check your network and try again.';
      default:
        // Fallback: clean up the raw message (remove code/statusCode noise)
        return e.message.isNotEmpty
            ? e.message
            : 'Something went wrong. Please try again.';
    }
  }
}