import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/onboarding_screen.dart';

void main() {
  Widget createTestWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: OnboardingScreen(),
      ),
    );
  }

  group('OnboardingScreen UI & Interaction Tests', () {
    testWidgets('Renders all section headers, inputs, role cards, and CTA', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Profile Setup'), findsOneWidget);
      expect(find.text('Complete your profile'), findsOneWidget);
      expect(find.text('PERSONAL DETAILS'), findsOneWidget);
      expect(find.text('SELECT ACCOUNT TYPE'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Worker / Service Partner'), findsOneWidget);
      expect(find.text('Complete Setup & Continue'), findsOneWidget);
    });

    testWidgets('Allows toggling between Customer and Worker roles', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Worker card
      final Finder workerCard = find.text('Worker / Service Partner');
      await tester.ensureVisible(workerCard);
      await tester.tap(workerCard);
      await tester.pumpAndSettle();

      // Tap Customer card
      final Finder customerCard = find.text('Customer');
      await tester.ensureVisible(customerCard);
      await tester.tap(customerCard);
      await tester.pumpAndSettle();
    });

    testWidgets('Shows validation errors on empty submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final Finder submitButton = find.text('Complete Setup & Continue');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full legal name.'), findsOneWidget);
    });
  });
}
