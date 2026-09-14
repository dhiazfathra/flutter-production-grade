import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_error_view.dart';
import 'package:flutter_production_grade/core/utils/app_error.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/golden_helper.dart';

void main() {
  group('AppErrorView', () {
    for (final error in [
      const AppError.network(),
      const AppError.unauthorized(),
      const AppError.notFound(),
      const AppError.server(500),
      AppError.unknown(Exception('boom')),
    ]) {
      testWidgets('renders a message for ${error.runtimeType}', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: goldenApp(
              theme: lightTheme,
              child: AppErrorView(error: error, onRetry: () {}),
            ),
          ),
        );

        expect(find.byType(Text), findsWidgets);
      });
    }
  });
}
