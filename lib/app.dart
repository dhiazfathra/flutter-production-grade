import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/ui/themes/app_theme.dart';
import 'package:flutter_production_grade/features/settings/ui/view_models/locale_view_model.dart';
import 'package:flutter_production_grade/features/settings/ui/view_models/theme_view_model.dart';
import 'package:flutter_production_grade/l10n/generated/app_localizations.dart';
import 'package:flutter_production_grade/routing/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeViewModelProvider),
      locale: ref.watch(localeViewModelProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 2, child: child!),
      debugShowCheckedModeBanner: false,
    );
  }
}
