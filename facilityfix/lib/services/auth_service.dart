// lib/services/auth_state_manager.dart
import 'package:flutter/material.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/services/api_services_mobile.dart';
import 'package:facilityfix/config/env.dart';

class AuthStateManager {
  /// Check if user is logged in and return their profile
  static Future<Map<String, dynamic>?> checkAuthState() async {
    try {
      // Try to get saved profile and token
      final profile = await AuthStorage.getProfile();
      final token = await AuthStorage.getToken();

      if (profile == null || token == null) {
        print('[AuthStateManager] No saved credentials found');
        return null;
      }

      print('[AuthStateManager] Found saved credentials for: ${profile['email']}');

      // Verify token is still valid by pinging the backend
      final role = (profile['role'] ?? 'tenant').toString().toLowerCase();
      final api = APIService(roleOverride: _toAppRole(role));

      // Test connection with the saved token
      final isValid = await api.testConnection();

      if (!isValid) {
        print('[AuthStateManager] Token appears invalid, clearing auth');
        await AuthStorage.clear();
        return null;
      }

      print('[AuthStateManager] Auth state is valid');
      return profile;
    } catch (e) {
      print('[AuthStateManager] Error checking auth state: $e');
      // Clear auth on error to be safe
      await AuthStorage.clear();
      return null;
    }
  }

  static AppRole _toAppRole(String role) {
    switch (role.toLowerCase()) {
      case 'tenant':
        return AppRole.tenant;
      case 'staff':
        return AppRole.staff;
      default:
        return AppRole.tenant;
    }
  }

  /// Get the appropriate home screen based on user role
  static Widget getHomeScreenForRole(String role) {
    switch (role.toLowerCase()) {
      case 'tenant':
        return _getTenantHome();
      case 'staff':
        return _getStaffHome();
      default:
        return _getTenantHome();
    }
  }

  static Widget _getTenantHome() {
    // Dynamic import to avoid circular dependencies
    try {
      return _createWidget('facilityfix/tenant/home.dart', 'HomePage');
    } catch (e) {
      print('[AuthStateManager] Error loading tenant home: $e');
      rethrow;
    }
  }

  static Widget _getStaffHome() {
    // Dynamic import to avoid circular dependencies
    try {
      return _createWidget('facilityfix/staff/home.dart', 'HomePage');
    } catch (e) {
      print('[AuthStateManager] Error loading staff home: $e');
      rethrow;
    }
  }

  static Widget _createWidget(String path, String className) {
    // This is a placeholder - in the actual implementation,
    // we'll import directly in the calling code
    throw UnimplementedError('Use direct imports in calling code');
  }
}

