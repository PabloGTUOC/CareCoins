import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('CareCoins Dashboard')),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome, ${user?.email ?? "Guest"}!', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user != null) {
                  // Find the latest login_history entry without a logout_time
                  final lastLogin = await Supabase.instance.client
                      .from('login_history')
                      .select()
                      .eq('user_id', user.id)
                      .filter('logout_time', 'is', null)
                      .order('login_time', ascending: false)
                      .limit(1)
                      .maybeSingle();

                  if (lastLogin != null) {
                    final logoutTime = DateTime.now().toUtc();
                    final loginTime = DateTime.parse(lastLogin['login_time']);
                    final duration = logoutTime.difference(loginTime);

                    await Supabase.instance.client
                        .from('login_history')
                        .update({
                      'logout_time': logoutTime.toIso8601String(),
                      'duration': duration.toString(),
                    })
                        .eq('id', lastLogin['id']);
                  }
                }

                // Now sign out
                await Supabase.instance.client.auth.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: const Text('Logout'),
            )
          ],
        ),
      ),
    );
  }
}
