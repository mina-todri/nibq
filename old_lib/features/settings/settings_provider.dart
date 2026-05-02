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

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      themeMode:
      (prefs.getBool('theme_dark') ?? true) ? ThemeMode.dark : ThemeMode.light,
      locale: (prefs.getBool('locale_ar') ?? true)
          ? const Locale('ar')
          : const Locale('en'),
      notifyOffers: prefs.getBool('notif_offers') ?? true,
      notifyOrders: prefs.getBool('notif_orders') ?? true,
      notifyUpdates: prefs.getBool('notif_updates') ?? false,
    );
  }

  Future<void> toggleTheme() async {
    final current = state.valueOrNull ?? const AppSettings();
    final isDark = current.themeMode == ThemeMode.dark;
    state = AsyncData(
        current.copyWith(themeMode: isDark ? ThemeMode.light : ThemeMode.dark));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('theme_dark', !isDark);
  }

  Future<void> toggleLocale() async {
    final current = state.valueOrNull ?? const AppSettings();
    final isAr = current.locale.languageCode == 'ar';
    state = AsyncData(
        current.copyWith(locale: isAr ? const Locale('en') : const Locale('ar')));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locale_ar', !isAr);
  }

  Future<void> setNotifOffers(bool v) async {
    final current = state.valueOrNull ?? const AppSettings();
    state = AsyncData(current.copyWith(notifyOffers: v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_offers', v);
  }

  Future<void> setNotifOrders(bool v) async {
    final current = state.valueOrNull ?? const AppSettings();
    state = AsyncData(current.copyWith(notifyOrders: v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_orders', v);
  }

  Future<void> setNotifUpdates(bool v) async {
    final current = state.valueOrNull ?? const AppSettings();
    state = AsyncData(current.copyWith(notifyUpdates: v));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_updates', v);
  }
}

final settingsProvider =
AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);