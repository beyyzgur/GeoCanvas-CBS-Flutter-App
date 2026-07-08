import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser?.id;
});
