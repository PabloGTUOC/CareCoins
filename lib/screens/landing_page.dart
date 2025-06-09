import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'email_signup_page.dart';
import 'package:gotrue/gotrue.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  /// Handles Google sign-in using Supabase OAuth
  void _signInWithGoogle(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? 'http://localhost:5000/' : null,
        queryParams: {
          'access_type': 'offline',
          'prompt': 'consent',
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    }
  }



  /// Navigates to the email sign-up page
  void _signUpWithEmail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmailSignUpPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F3), // pastel pink background
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Title
              Text(
                "Welcome to CareCoins",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                "Earn coins for the care you give.",
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Google Sign-In
              SignInButton(
                Buttons.Google,
                onPressed: () => _signInWithGoogle(context),
              ),
              const SizedBox(height: 16),
              // Email Sign-Up
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC8E6C9), // pastel green
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                onPressed: () => _signUpWithEmail(context),
                child: const Text(
                  "Sign up with Email",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
