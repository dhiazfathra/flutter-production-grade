import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/ui/design_system/spacing.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_scaffold.dart';
import 'package:flutter_production_grade/core/ui/localization/context_l10n_extension.dart';
import 'package:flutter_production_grade/features/settings/ui/view_models/locale_view_model.dart';
import 'package:flutter_production_grade/features/settings/ui/view_models/theme_view_model.dart';
import 'package:flutter_production_grade/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeViewModelProvider);
    final locale = ref.watch(localeViewModelProvider);

    return AppScaffold(
      title: context.l10n.settings,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              children: [
                Text(context.l10n.theme),
                const Spacer(),
                Switch(
                  key: const ValueKey('theme_toggle'),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (_) =>
                      ref.read(themeViewModelProvider.notifier).toggle(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(context.l10n.language),
                const Spacer(),
                SegmentedButton<Locale>(
                  key: const ValueKey('locale_selector'),
                  segments: [
                    for (final supported in AppLocalizations.supportedLocales)
                      ButtonSegment(
                        value: supported,
                        label: Text(supported.languageCode),
                      ),
                  ],
                  selected: {locale},
                  onSelectionChanged: (selection) => ref
                      .read(localeViewModelProvider.notifier)
                      .select(selection.first),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
