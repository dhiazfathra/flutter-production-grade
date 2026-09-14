import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppButton', () {
    testWidgets('invokes onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              key: const ValueKey('button'),
              label: 'Submit',
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('button')));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('shows a spinner and blocks taps while loading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              key: const ValueKey('button'),
              label: 'Submit',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('button')));
      await tester.pump();
      expect(taps, 0);
    });
  });
}
