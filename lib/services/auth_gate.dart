import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/home_page.dart';
import '../screens/landing_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkingProfile = false;

  @override
  void initState() {
    super.initState();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {});
    });

    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _checkingProfile = true);

    // Check if user exists in our users table
    final existing = await Supabase.instance.client
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      // Insert user
      await Supabase.instance.client.from('users').insert({
        'id': user.id,
        'email': user.email,
      });
    }

    // Insert login_history record
    await Supabase.instance.client.from('login_history').insert({
      'user_id': user.id,
      'login_time': DateTime.now().toUtc().toIso8601String(),
    });

    setState(() => _checkingProfile = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (_checkingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session == null) {
      return const LandingPage();
    } else {
      return const HomePage();
    }
  }
}