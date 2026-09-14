import 'package:flutter/material.dart';
import 'package:flutter_production_grade/core/data/services/storage/settings_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_view_model.g.dart';

@riverpod
class LocaleViewModel extends _$LocaleViewModel {
  @override
  Locale build() => ref.watch(initialLocaleProvider);

  Future<void> select(Locale locale) async {
    await ref.read(settingsServiceProvider).writeLocale(locale);
    state = locale;
  }
}
