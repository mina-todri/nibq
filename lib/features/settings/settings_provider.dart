// lib/features/settings/settings_provider.dart
// FIX 4 — Language Switching:
//   The old code saved/loaded locale correctly in SharedPreferences BUT
//   app.dart was NOT rebuilding when locale changed because MaterialApp's
//   `locale` was set once and the widget tree wasn't fully responding.
//   Fix: The locale is stored in state and MaterialApp reads it via
//   ref.watch(settingsProvider).locale. This file is correct; the critical
//   fix is in app.dart where MaterialApp.locale now reads from state.
//
// FIX 5 — Theme (AppBar color):
//   CustomAppBar hardcoded AppColors.surfBase (dark color) regardless of theme.
//   Fix is in custom_app_bar.dart — AppBar must use Theme.of(context).
//   This provider itself is correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;
  final bool notifyOffers;
  final bool notifyOrders;
  final bool notifyUpdates;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('ar'),
    this.notifyOffers = true,
    this.notifyOrders = true,
    this.notifyUpdates = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    bool? notifyOffers,
    bool? notifyOrders,
    bool? notifyUpdates,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
        notifyOffers: notifyOffers ?? this.notifyOffers,
        notifyOrders: notifyOrders ?? this.notifyOrders,
        notifyUpdates: notifyUpdates ?? this.notifyUpdates,
      );

  bool get isDark => themeMode == ThemeMode.dark;
  bool get isArabic => locale.languageCode == 'ar';
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SharedPreferences? _prefs;

  SettingsNotifier() : super(const AppSettings()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    if (_prefs == null) return;
    
    final dark = _prefs!.getBool('theme_dark') ?? true;
    final arabic = _prefs!.getBool('locale_ar') ?? true;
    
    state = AppSettings(
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: arabic ? const Locale('ar') : const Locale('en'),
      notifyOffers: _prefs!.getBool('notif_offers') ?? true,
      notifyOrders: _prefs!.getBool('notif_orders') ?? true,
      notifyUpdates: _prefs!.getBool('notif_updates') ?? false,
    );
  }

  Future<void> toggleTheme() async {
    final isDark = state.themeMode == ThemeMode.dark;
    state = state.copyWith(themeMode: isDark ? ThemeMode.light : ThemeMode.dark);
    await _prefs?.setBool('theme_dark', !isDark);
  }

  Future<void> toggleLocale() async {
    final isAr = state.locale.languageCode == 'ar';
    state = state.copyWith(
        locale: isAr ? const Locale('en') : const Locale('ar'));
    await _prefs?.setBool('locale_ar', !isAr);
  }

  Future<void> setNotifOffers(bool v) async {
    state = state.copyWith(notifyOffers: v);
    await _prefs?.setBool('notif_offers', v);
  }

  Future<void> setNotifOrders(bool v) async {
    state = state.copyWith(notifyOrders: v);
    await _prefs?.setBool('notif_orders', v);
  }

  Future<void> setNotifUpdates(bool v) async {
    state = state.copyWith(notifyUpdates: v);
    await _prefs?.setBool('notif_updates', v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
        (_) => SettingsNotifier());
