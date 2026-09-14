import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_view_model.g.dart';

@riverpod
class ThemeViewModel extends _$ThemeViewModel {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await ref.read(settingsServiceProvider).writeThemeMode(next);
    state = next;
  }
}
