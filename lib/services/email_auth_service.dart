import 'package:supabase_flutter/supabase_flutter.dart';

class EmailAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }
}
