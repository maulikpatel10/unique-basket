import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic persistent key-value local storage service backed by SharedPreferences.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<bool> setString(String key, String value) => _prefs.setString(key, value);

  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);

  double? getDouble(String key) => _prefs.getDouble(key);

  Future<bool> setDouble(String key, double value) => _prefs.setDouble(key, value);

  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<bool> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);

  Map<String, dynamic>? getJson(String key) {
    final str = _prefs.getString(key);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) {
    return _prefs.setString(key, jsonEncode(value));
  }

  Future<bool> remove(String key) => _prefs.remove(key);

  Future<bool> clear() => _prefs.clear();
}
