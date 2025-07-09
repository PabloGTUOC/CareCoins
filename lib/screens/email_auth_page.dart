import 'package:flutter/material.dart';
import '../services/email_auth_service.dart';

class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});

  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = EmailAuthService();
  bool _signInMode = true;

  Future<void> _authenticate() async {
    try {
      final response = _signInMode
          ? await _authService.signIn(
              _emailController.text,
              _passwordController.text,
            )
          : await _authService.signUp(
              _emailController.text,
              _passwordController.text,
            );
      if (!_signInMode && response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Confirmation email sent.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_signInMode ? 'Sign in with Email' : 'Register with Email'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _authenticate,
                child: Text(_signInMode ? 'Sign In' : 'Create Account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _signInMode = !_signInMode),
                child: Text(
                  _signInMode
                      ? 'Need an account? Sign up'
                      : 'Have an account? Sign in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
