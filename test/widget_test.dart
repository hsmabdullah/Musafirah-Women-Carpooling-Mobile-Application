// Basic widget smoke test for the Musafirah app shell.
//
// Verifies that the root MaterialApp (MyApp) builds without throwing and
// renders the provided home widget. Firebase-dependent screens are not
// pumped here — those are covered by manual/integration testing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:musafirah_app/main.dart';

void main() {
  testWidgets('MyApp builds and renders its home widget', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MyApp(home: Scaffold(body: Text('Musafirah'))),
    );

    // The app shell mounts a MaterialApp and shows the given home screen.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Musafirah'), findsOneWidget);
  });
}
