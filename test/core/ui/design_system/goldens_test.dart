import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

import 'package:flutter_production_grade/core/ui/design_system/widgets/app_button.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_empty_state.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_error_view.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_scaffold.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_text_field.dart';
import 'package:flutter_production_grade/core/utils/app_error.dart';

import '../../../support/golden_helper.dart';

void main() {
  for (final entry in {'light': lightTheme, 'dark': darkTheme}.entries) {
    unawaited(
      goldenTest(
        'design system widgets (${entry.key})',
        tags: ['golden'],
        fileName: 'design_system_widgets_${entry.key}',
        builder: () => GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'button',
              child: goldenApp(
                theme: entry.value,
                child: AppButton(label: 'Submit', onPressed: () {}),
              ),
            ),
            GoldenTestScenario(
              name: 'text field',
              child: goldenApp(
                theme: entry.value,
                child: AppTextField(
                  label: 'Email',
                  controller: TextEditingController(),
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'empty state',
              child: goldenApp(
                theme: entry.value,
                child: const AppEmptyState(),
              ),
            ),
            GoldenTestScenario(
              name: 'error view',
              child: goldenApp(
                theme: entry.value,
                child: AppErrorView(
                  error: const AppError.network(),
                  onRetry: () {},
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'scaffold',
              child: goldenApp(
                theme: entry.value,
                child: const SizedBox(
                  width: 320,
                  height: 240,
                  child: AppScaffold(
                    title: 'Title',
                    body: Center(child: Text('Body')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
