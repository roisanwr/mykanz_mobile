import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

part 'supabase_service.g.dart';

// ==========================================
// ENV CONFIG — isi dengan data Supabase kamu
// ==========================================
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://wtpnbyfzgooighilutjv.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0cG5ieWZ6Z29vaWdoaWx1dGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI4NTcxNDIsImV4cCI6MjA4ODQzMzE0Mn0.fo5u5vvzSaMxsKRzUUuHbj7Q72dF1viV7f7Bqy2bAo8',
  );
  static const String loginFn = '$url/functions/v1/login';
  static const String registerFn = '$url/functions/v1/register';
}

// ==========================================
// SECURE STORAGE KEY
// ==========================================
const _kTokenKey = 'mykanz_access_token';
const _kUserIdKey = 'mykanz_user_id';
const _kUserName = 'mykanz_user_name';
const _kUserEmail = 'mykanz_user_email';

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

  String? currentUserId;

  /// Login langsung ke Supabase users (verifikasi bcrypt)
  Future<AuthResult> login(String email, String password) async {
    try {
      final user = await _client
          .from('users')
          .select('id, name, email, password_hash')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        return AuthResult.error('Email atau password salah');
      }

      final hash = user['password_hash'] as String?;
      if (hash == null || !BCrypt.checkpw(password, hash)) {
        return AuthResult.error('Email atau password salah');
      }

      final userId = user['id'] as String;
      final userName = user['name'] as String? ?? '';

      currentUserId = userId;

      // Simpan ke secure storage
      await Future.wait([
        _storage.write(key: _kUserIdKey, value: userId),
        _storage.write(key: _kUserName, value: userName),
        _storage.write(key: _kUserEmail, value: email),
        _storage.write(
          key: _kTokenKey,
          value: 'dummy_token',
        ), // Bypass cek token
      ]);

      return AuthResult.success(
        userId: userId,
        name: userName,
        email: email,
        token: 'dummy_token',
      );
    } catch (e) {
      return AuthResult.error('Terjadi kesalahan koneksi: $e');
    }
  }

  /// Register langsung ke Supabase users
  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Cek existing user
      final existing = await _client
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (existing != null) {
        return AuthResult.error('Email sudah terdaftar');
      }

      final hash = BCrypt.hashpw(password, BCrypt.gensalt());

      await _client
          .from('users')
          .insert({'name': name, 'email': email, 'password_hash': hash})
          .select()
          .single();

      // Setelah register berhasil, langsung login
      return await login(email, password);
    } catch (e) {
      return AuthResult.error('Terjadi kesalahan koneksi: $e');
    }
  }

  /// Logout — hapus semua data dari secure storage
  Future<void> logout() async {
    currentUserId = null;
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

      currentUserId = await _storage.read(key: _kUserIdKey);
      return currentUserId != null;
    } catch (_) {
      await _storage.deleteAll();
      return false;
    }
  }

  /// Get cached user info (tanpa network call)
  Future<CachedUser?> getCachedUser() async {
    final id = await _storage.read(key: _kUserIdKey);
    final name = await _storage.read(key: _kUserName);
    final email = await _storage.read(key: _kUserEmail);
    if (id == null || email == null) return null;
    return CachedUser(id: id, name: name ?? '', email: email);
  }
}

// ==========================================
// PROVIDER
// ==========================================
// Singleton AuthService — keepAlive agar currentUserId tidak hilang saat rebuild
@Riverpod(keepAlive: true)
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
    isSuccess: true,
    userId: userId,
    name: name,
    email: email,
    token: token,
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
