import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResult {
  final bool ok;
  final String? error;
  const AuthResult.success() : ok = true, error = null;
  const AuthResult.failure(this.error) : ok = false;
}

class AuthViewModel {
  final _supabase = Supabase.instance.client;

  Future<AuthResult> register(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user != null) {

        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'role': 'user',
        });
        return const AuthResult.success();
      }
      return const AuthResult.failure('Kayıt tamamlanamadı.');
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return const AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<String> getUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'user';
    try {
      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      return response['role'] as String;
    } catch (e) {
      return 'user';
    }
  }
}

final authViewModelProvider = Provider<AuthViewModel>((ref) => AuthViewModel());
