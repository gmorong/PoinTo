import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<AsyncValue<Locale>> {
  LocaleNotifier() : super(const AsyncValue.loading()) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('locale') ?? 'en';
    state = AsyncValue.data(Locale(langCode));
  }

  Future<void> setLocale(Locale newLocale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', newLocale.languageCode);
    state = AsyncValue.data(newLocale);
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, AsyncValue<Locale>>((ref) {
  return LocaleNotifier();
});
