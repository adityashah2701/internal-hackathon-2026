import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('SahayogApp initial smoke test and verification render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SahayogApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify application name is rendered
    expect(find.text(AppConstants.appName), findsWidgets);
    // Verify login screen elements render
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}

