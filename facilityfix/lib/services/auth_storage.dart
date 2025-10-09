// lib/services/auth_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kUserKey = 'ff_user_profile';
const _kTokenKey = 'ff_id_token';
final _secureStorage = FlutterSecureStorage();

class AuthStorage {
  /// Save a small user profile map to SharedPreferences.
  /// Keep this lightweight: user_id, first_name, last_name, email, role, building_unit, etc.
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(profile));
  }

  /// Return profile map or null if none saved.
  static Future<Map<String, dynamic>?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kUserKey);
    if (s == null) return null;
    return Map<String, dynamic>.from(jsonDecode(s) as Map);
  }

  /// Save token securely.
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _kTokenKey, value: token);
  }

  /// Read token.
  static Future<String?> getToken() async {
    return _secureStorage.read(key: _kTokenKey);
  }

  /// Clear stored auth data (logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
    await _secureStorage.delete(key: _kTokenKey);
  }
}
