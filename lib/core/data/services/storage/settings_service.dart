import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsService {
  Future<ThemeMode?> readThemeMode();
  Future<void> writeThemeMode(ThemeMode mode);
  Future<Locale?> readLocale();
  Future<void> writeLocale(Locale locale);
}

class SharedPreferencesSettingsService implements SettingsService {
  const SharedPreferencesSettingsService(this._prefs);

  static const _themeKey = 'settings.themeMode';
  static const _localeKey = 'settings.locale';

  final SharedPreferences _prefs;

  @override
  Future<ThemeMode?> readThemeMode() async =>
      switch (_prefs.getString(_themeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => null,
      };

  @override
  Future<void> writeThemeMode(ThemeMode mode) async {
    assert(
      mode != ThemeMode.system,
      'Only a resolved mode may be stored (ADR-0009)',
    );
    await _prefs.setString(
      _themeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  @override
  Future<Locale?> readLocale() async {
    final code = _prefs.getString(_localeKey);
    return code == null ? null : Locale(code);
  }

  @override
  Future<void> writeLocale(Locale locale) =>
      _prefs.setString(_localeKey, locale.languageCode);
}

final settingsServiceProvider = Provider<SettingsService>(
  (ref) =>
      throw UnimplementedError('settingsServiceProvider must be overridden'),
);

/// Resolved once in `bootstrap` from storage, falling back to OS brightness.
final initialThemeModeProvider = Provider<ThemeMode>(
  (ref) =>
      throw UnimplementedError('initialThemeModeProvider must be overridden'),
);

/// Resolved once in `bootstrap` from storage, falling back to the OS locale.
final initialLocaleProvider = Provider<Locale>(
  (ref) => throw UnimplementedError('initialLocaleProvider must be overridden'),
);
