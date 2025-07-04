// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carecoins/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://qbshcfljuxkgrpnppykp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFic2hjZmxqdXhrZ3JwbnBweWtwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzODIyNDAsImV4cCI6MjA2NDk1ODI0MH0.cAjCdZvZ3ylIW3k-h4Jixw7Z6se_LzoDKC5QiS1WS2w',
    );
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CareCoinsApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
