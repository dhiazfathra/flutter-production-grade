import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_empty_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden_helper.dart';

void main() {
  testWidgets('AppEmptyState renders', (tester) async {
    // Instantiated without `const` so the constructor actually runs at test
    // time — a `const AppEmptyState()` literal is folded at compile time and
    // never shows up as an executed line in coverage.
    // ignore: prefer_const_constructors
    final widget = AppEmptyState();

    await tester.pumpWidget(
      MaterialApp(
        home: goldenApp(theme: lightTheme, child: widget),
      ),
    );

    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}
