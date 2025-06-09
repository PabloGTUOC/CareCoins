import 'package:carecoins/services/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qbshcfljuxkgrpnppykp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFic2hjZmxqdXhrZ3JwbnBweWtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzODIyNDAsImV4cCI6MjA2NDk1ODI0MH0.cAjCdZvZ3ylIW3k-h4Jixw7Z6se_LzoDKC5QiS1WS2w', // TODO: Replace with your Supabase anon key
  );

  runApp(const CareCoinsApp());
}

class CareCoinsApp extends StatelessWidget {
  const CareCoinsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareCoins',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF8BBD0), // pastel pink
          primary: const Color(0xFFF8BBD0),
          secondary: const Color(0xFFC8E6C9), // pastel green
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.latoTextTheme(),
      ),
      home: const AuthGate(),
    );
  }
}
