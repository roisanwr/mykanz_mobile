import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_service.g.dart';

// ==========================================
// ENV CONFIG — isi dengan data Supabase kamu
// ==========================================
class SupabaseConfig {
  static const String url        = String.fromEnvironment('SUPABASE_URL',     defaultValue: 'https://YOUR_PROJECT.supabase.co');
  static const String anonKey   = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'YOUR_ANON_KEY');
  static const String loginFn   = '$url/functions/v1/login';
  static const String registerFn = '$url/functions/v1/register';
}

// ==========================================
// SECURE STORAGE KEY
// ==========================================
const _kTokenKey   = 'mykanz_access_token';
const _kUserIdKey  = 'mykanz_user_id';
const _kUserName   = 'mykanz_user_name';
const _kUserEmail  = 'mykanz_user_email';

// ==========================================
// SUPABASE CLIENT PROVIDER
// ==========================================
@riverpod
SupabaseClient supabaseClient(Ref ref) {
  return Supabase.instance.client;
}

// ==========================================
// AUTH SERVICE
// ==========================================
class AuthService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  SupabaseClient get _client => Supabase.instance.client;

  /// Login via Supabase Edge Function (verifikasi bcrypt)
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _client.functions.invoke(
        'login',
        body: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['error'] != null) {
        return AuthResult.error(data['error'] as String);
      }

      final token = data['access_token'] as String;
      final user = data['user'] as Map<String, dynamic>;

      // Set session di Supabase client agar RLS otomatis pakai JWT ini
      await _client.auth.setSession(token);

      // Simpan ke secure storage
      await Future.wait([
        _storage.write(key: _kTokenKey,  value: token),
        _storage.write(key: _kUserIdKey, value: user['id'] as String),
        _storage.write(key: _kUserName,  value: user['name'] as String? ?? ''),
        _storage.write(key: _kUserEmail, value: user['email'] as String),
      ]);

      return AuthResult.success(
        userId: user['id'] as String,
        name: user['name'] as String? ?? '',
        email: user['email'] as String,
        token: token,
      );
    } catch (e) {
      return AuthResult.error('Terjadi kesalahan koneksi: $e');
    }
  }

  /// Register via Supabase Edge Function
  Future<AuthResult> register(String name, String email, String password) async {
    try {
      final response = await _client.functions.invoke(
        'register',
        body: {'name': name, 'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      if (data['error'] != null) {
        return AuthResult.error(data['error'] as String);
      }

      // Setelah register berhasil, langsung login
      return login(email, password);
    } catch (e) {
      return AuthResult.error('Terjadi kesalahan koneksi: $e');
    }
  }

  /// Logout — hapus semua data dari secure storage
  Future<void> logout() async {
    await _storage.deleteAll();
    await _client.auth.signOut();
  }

  /// Cek apakah user sudah login (ada token di storage)
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _kTokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Restore session dari secure storage (saat app restart)
  Future<bool> restoreSession() async {
    try {
      final token = await _storage.read(key: _kTokenKey);
      if (token == null) return false;

      await _client.auth.setSession(token);
      return true;
    } catch (_) {
      await _storage.deleteAll();
      return false;
    }
  }

  /// Get cached user info (tanpa network call)
  Future<CachedUser?> getCachedUser() async {
    final id    = await _storage.read(key: _kUserIdKey);
    final name  = await _storage.read(key: _kUserName);
    final email = await _storage.read(key: _kUserEmail);
    if (id == null || email == null) return null;
    return CachedUser(id: id, name: name ?? '', email: email);
  }
}

// ==========================================
// PROVIDER
// ==========================================
@riverpod
AuthService authService(Ref ref) => AuthService();

// ==========================================
// DATA CLASSES
// ==========================================
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? userId;
  final String? name;
  final String? email;
  final String? token;

  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.userId,
    this.name,
    this.email,
    this.token,
  });

  factory AuthResult.success({
    required String userId,
    required String name,
    required String email,
    required String token,
  }) => AuthResult._(
    isSuccess: true, userId: userId, name: name, email: email, token: token,
  );

  factory AuthResult.error(String message) =>
    AuthResult._(isSuccess: false, errorMessage: message);
}

class CachedUser {
  final String id;
  final String name;
  final String email;
  const CachedUser({required this.id, required this.name, required this.email});
}
