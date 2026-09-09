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

  group('Step-by-Step Onboarding Wizard Tests', () {
    testWidgets('Completes full 4-step onboarding flow with navigation and validation', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ==========================================
      // STEP 1: Welcome
      // ==========================================
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Welcome to Sahayog'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // ==========================================
      // STEP 2: Basic Profile (Your Details)
      // ==========================================
      expect(find.text('Step 2 of 4'), findsOneWidget);
      expect(find.text('Your Details'), findsOneWidget);

      // Try continuing without filling name
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your full legal name.'), findsOneWidget);

      // Fill in valid details
      final Finder nameField = find.widgetWithText(TextFormField, 'Full Name');
      final Finder phoneField = find.widgetWithText(TextFormField, 'Mobile Number');
      await tester.enterText(nameField, 'Anita Sharma');
      await tester.enterText(phoneField, '9876543210');
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // ==========================================
      // STEP 3: Role Selection
      // ==========================================
      expect(find.text('Step 3 of 4'), findsOneWidget);
      expect(find.text('Select Your Role'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Worker / Service Partner'), findsOneWidget);

      // Select Worker
      await tester.tap(find.text('Worker / Service Partner'));
      await tester.pumpAndSettle();

      // Tap Continue to Step 4
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // ==========================================
      // STEP 4: Review & Confirm
      // ==========================================
      expect(find.text('Step 4 of 4'), findsOneWidget);
      expect(find.text('Review & Confirm'), findsOneWidget);
      expect(find.text('Anita Sharma'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.text('Worker / Service Provider'), findsOneWidget);
      expect(find.text('Confirm & Enter Dashboard'), findsOneWidget);

      // Test Back navigation: go back to Step 3
      final Finder backButton = find.byTooltip('Back');
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      expect(find.text('Step 3 of 4'), findsOneWidget);

      // Go forward to Step 4 again
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4 of 4'), findsOneWidget);

      // Data is preserved!
      expect(find.text('Anita Sharma'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
    });
  });
}
