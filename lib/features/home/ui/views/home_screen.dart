import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/ui/design_system/widgets/app_scaffold.dart';
import 'package:flutter_production_grade/core/ui/localization/context_l10n_extension.dart';
import 'package:flutter_production_grade/routing/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.l10n.appTitle,
      body: Center(
        child: TextButton(
          onPressed: () => const SettingsRoute().go(context),
          child: Text(context.l10n.settings),
        ),
      ),
    );
  }
}
