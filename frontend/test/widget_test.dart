import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos_x/features/auth/auth_screen.dart';

void main() {
  testWidgets('auth screen renders LifeOS brand', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AuthScreen()),
      ),
    );
    expect(find.text('LifeOS X'), findsWidgets);
  });
}
