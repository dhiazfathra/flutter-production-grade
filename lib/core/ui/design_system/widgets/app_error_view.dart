import 'package:flutter/material.dart';

import 'package:flutter_production_grade/core/ui/design_system/spacing.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_button.dart';
import 'package:flutter_production_grade/core/ui/localization/context_l10n_extension.dart';
import 'package:flutter_production_grade/core/utils/app_error.dart';

class AppErrorView extends StatelessWidget {
  const AppErrorView({required this.error, required this.onRetry, super.key});

  final AppError error;
  final VoidCallback onRetry;

  String _message(BuildContext context, AppError error) => switch (error) {
    NetworkError() => context.l10n.errorNetwork,
    UnauthorizedError() => context.l10n.errorUnauthorized,
    NotFoundError() => context.l10n.errorNotFound,
    ServerError() => context.l10n.errorServer,
    UnknownError() => context.l10n.errorUnknown,
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _message(context, error),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: context.l10n.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
