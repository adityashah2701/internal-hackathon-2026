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
    expect(find.text(AppConstants.appName), findsOneWidget);
    // Verify diagnostics screen components render
    expect(find.text('Foundation Readiness'), findsOneWidget);
    expect(find.text('Target Role Architecture (PS-089)'), findsOneWidget);
    expect(find.text('Re-check Diagnostics'), findsOneWidget);
  });
}
