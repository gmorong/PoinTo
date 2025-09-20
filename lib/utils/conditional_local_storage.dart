import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConditionalLocalStorage extends LocalStorage {
  final bool rememberMe;
  final String _key = supabasePersistSessionKey;

  ConditionalLocalStorage({required this.rememberMe});

  @override
  Future<void> initialize() async {
    // Инициализация, если необходимо
  }

  @override
  Future<String?> accessToken() async {
    if (!rememberMe) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<bool> hasAccessToken() async {
    if (!rememberMe) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (!rememberMe) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}