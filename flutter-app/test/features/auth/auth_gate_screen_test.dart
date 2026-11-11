import 'package:edusafe_flutter/features/auth/auth_gate_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps password login locked before dongle verification', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthGateScreen())),
    );

    expect(find.text('Verifikasi dongle'), findsOneWidget);
    expect(find.text('Login dengan biometric'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });
}
