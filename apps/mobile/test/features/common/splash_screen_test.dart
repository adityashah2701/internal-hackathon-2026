import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/constants/app_constants.dart';
import 'package:mobile/features/common/presentation/splash_screen.dart';

void main() {
  Widget createWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: SplashScreen(),
      ),
    );
  }

  group('SplashScreen Widget Tests', () {
    testWidgets('Renders Sahayog brand emblem, title, tagline and institutional badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.appTagline), findsOneWidget);
      expect(find.byIcon(Icons.handshake_rounded), findsOneWidget);
      expect(find.text('Cooperative Federation of India'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
