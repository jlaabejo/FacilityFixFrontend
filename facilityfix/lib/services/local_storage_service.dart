import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _concernSlipsKey = 'submitted_concern_slips';

  /// Save a submitted concern slip to local storage
  static Future<void> saveSubmittedConcernSlip(
    Map<String, dynamic> concernSlip,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingSlips = await getSubmittedConcernSlips();

      // Add timestamp and local ID if not present
      concernSlip['submitted_at'] =
          concernSlip['submitted_at'] ?? DateTime.now().toIso8601String();
      concernSlip['local_id'] =
          concernSlip['local_id'] ??
          DateTime.now().millisecondsSinceEpoch.toString();

      existingSlips.add(concernSlip);

      final jsonString = jsonEncode(existingSlips);
      await prefs.setString(_concernSlipsKey, jsonString);

      print('[LocalStorage] Saved concern slip: ${concernSlip['title']}');
    } catch (e) {
      print('[LocalStorage] Error saving concern slip: $e');
    }
  }

  /// Get all submitted concern slips from local storage
  static Future<List<Map<String, dynamic>>> getSubmittedConcernSlips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_concernSlipsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('[LocalStorage] Error getting concern slips: $e');
      return [];
    }
  }

  /// Clear all stored concern slips
  static Future<void> clearSubmittedConcernSlips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_concernSlipsKey);
      print('[LocalStorage] Cleared all concern slips');
    } catch (e) {
      print('[LocalStorage] Error clearing concern slips: $e');
    }
  }

  /// Update a concern slip status (for local tracking)
  static Future<void> updateConcernSlipStatus(
    String localId,
    String newStatus,
  ) async {
    try {
      final existingSlips = await getSubmittedConcernSlips();
      final index = existingSlips.indexWhere(
        (slip) => slip['local_id'] == localId,
      );

      if (index != -1) {
        existingSlips[index]['status'] = newStatus;
        existingSlips[index]['updated_at'] = DateTime.now().toIso8601String();

        final prefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(existingSlips);
        await prefs.setString(_concernSlipsKey, jsonString);

        print(
          '[LocalStorage] Updated concern slip status: $localId -> $newStatus',
        );
      }
    } catch (e) {
      print('[LocalStorage] Error updating concern slip status: $e');
    }
  }
}
