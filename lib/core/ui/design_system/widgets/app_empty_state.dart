import 'package:flutter/material.dart';

import 'package:flutter_production_grade/core/ui/design_system/spacing.dart';
import 'package:flutter_production_grade/core/ui/localization/context_l10n_extension.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.emptyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.emptyBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
