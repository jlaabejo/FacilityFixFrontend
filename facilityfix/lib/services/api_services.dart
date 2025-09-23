import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/services/local_storage_service.dart';

class APIService {
  /// Current app role (used to pick base URL)
  final AppRole role;

  /// Base URL resolved from AppEnv or provided explicitly
  final String baseUrl;

  /// Default headers applied to every request (merged with per-call headers)
  Map<String, String> defaultHeaders;

  // ===== Constructors =====

  APIService({AppRole? roleOverride, Map<String, String>? headers})
      : role = roleOverride ?? AppEnv.role,
        baseUrl = AppEnv.baseUrlWithLan(roleOverride ?? AppEnv.role),
        defaultHeaders = {
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        };

  APIService.fromBaseUrl(this.baseUrl, {Map<String, String>? headers})
      : role = AppEnv.role,
        defaultHeaders = {
          'Content-Type': 'application/json',
          if (headers != null) ...headers,
        };

  // ===== Low-level helpers =====

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return Map.of(defaultHeaders);
    return {...defaultHeaders, ...headers};
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    _logReq('GET', path);
    return http.get(_u(path), headers: _mergeHeaders(headers));
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) {
    _logReq('DELETE', path);
    return http.delete(_u(path), headers: _mergeHeaders(headers));
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    _logReq('POST', path);
    return http.post(_u(path), headers: _mergeHeaders(headers), body: body);
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    _logReq('PUT', path);
    return http.put(_u(path), headers: _mergeHeaders(headers), body: body);
  }

  // JSON convenience
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? jsonBody,
  }) async {
    final r = await post(
      path,
      headers: _mergeHeaders(headers),
      body: jsonEncode(jsonBody ?? {}),
    );
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception('POST $path failed: ${r.statusCode} ${r.body}');
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? headers,
  }) async {
    final r = await get(path, headers: headers);
    if (r.statusCode >= 200 && r.statusCode < 300) {
      return jsonDecode(r.body) as Map<String, dynamic>;
    }
    throw Exception('GET $path failed: ${r.statusCode} ${r.body}');
  }

  // ===== Utilities =====

  Future<bool> testConnection() async {
    final probes = ['/ping', '/health', '/'];
    for (final p in probes) {
      try {
        final r = await http.get(_u(p)).timeout(const Duration(seconds: 4));
        if (r.statusCode >= 200 && r.statusCode < 300) return true;
      } catch (_) {}
    }
    return false;
  }

  // ===== Internal auth helpers =====

  Future<String> _requireToken() async {
    final t = await AuthStorage.getToken();
    if (t == null || t.isEmpty) {
      throw Exception('Authentication token not found. Please login again.');
    }
    return t;
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  void _logReq(String method, String path) {
    // ignore: avoid_print
    print('[API] $method $baseUrl$path (role=$role)');
  }

  // ===== Register =====

  Future<Map<String, dynamic>> registerAdmin({
    required String firstName,
    required String lastName,
    required String birthDate,
    required String email,
    required String password,
    String? phoneNumber,
  }) {
    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
      'email': email,
      'password': password,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phone_number': phoneNumber,
    };
    return postJson('/auth/register/admin', jsonBody: body);
  }

  Future<Map<String, dynamic>> registerStaff({
    required String firstName,
    required String lastName,
    required String birthDate,
    required String email,
    required String password,
    required String staffDepartment,
    String? phoneNumber,
  }) {
    final mapped = _deptToApiEnum(staffDepartment);
    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
      'email': email,
      'password': password,
      'staff_department': mapped,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phone_number': phoneNumber,
    };
    return postJson('/auth/register/staff', jsonBody: body);
  }

  Future<Map<String, dynamic>> registerTenant({
    required String firstName,
    required String lastName,
    required String birthDate,
    required String email,
    required String password,
    required String buildingUnit,
    String? phoneNumber,
  }) {
    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': birthDate,
      'email': email,
      'password': password,
      'building_unit': buildingUnit,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phone_number': phoneNumber,
    };
    return postJson('/auth/register/tenant', jsonBody: body);
  }

  String _deptToApiEnum(String v) {
    final s = v.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    switch (s) {
      case 'maintenance':
      case 'carpentry':
      case 'plumbing':
      case 'electrical':
      case 'masonry':
        return s;
      default:
        return s.isEmpty ? 'other' : s;
    }
  }

  // ===== Login / Auth =====

  Future<Map<String, dynamic>> loginRoleBased({
    required String role, // 'admin' | 'staff' | 'tenant'
    required String email,
    required String password,
  }) async {
    final body = <String, dynamic>{
      'role': role.toLowerCase(),
      'email': email,
      'password': password,
    };
    return postJson('/auth/login', jsonBody: body);
  }

  Future<Map<String, dynamic>> me(String idToken) {
    return getJson('/auth/me', headers: _authHeaders(idToken));
  }

  /// Local-first profile fetch.
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // Prefer local profile (immediate greeting)
      final local = await AuthStorage.getProfile();
      if (local != null) return local;

      // Try server if token exists
      final token = await AuthStorage.getToken();
      if (token == null) return null;

      for (final endpoint in const ['/auth/me', '/profiles/me/complete']) {
        try {
          final response = await get(endpoint, headers: _authHeaders(token));
          if (response.statusCode == 200) {
            final jsonResponse = json.decode(response.body);
            return Map<String, dynamic>.from(jsonResponse as Map);
          }
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching user profile: $e');
    }
    return await AuthStorage.getProfile();
  }

  // ===== Concern Slips =====

  /// Submit a new concern slip (Tenant only)
  Future<Map<String, dynamic>> submitConcernSlip({
    required String title,
    required String description,
    required String location,
    required String category,
    String priority = 'medium',
    String? unitId,
    List<String>? attachments,
  }) async {
    try {
      final token = await _requireToken();

      final body = {
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'priority': _mapPriorityToBackend(priority),
        if (unitId != null) 'unit_id': unitId,
        'attachments': attachments ?? [],
      };

      final response = await post(
        '/concern-slips/',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> result;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            result = decoded;
          } else if (decoded is bool && decoded == true) {
            result = {
              'success': true,
              'message': 'Concern slip submitted successfully',
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
            };
          } else {
            result = {
              'success': true,
              'message': 'Concern slip submitted successfully',
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'raw_response': decoded,
            };
          }
        } catch (e) {
          result = {
            'success': true,
            'message': 'Concern slip submitted successfully',
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'raw_response': response.body,
          };
        }

        final localConcernSlip = {
          ...body,
          'id': result['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'status': 'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
          'local_id': DateTime.now().millisecondsSinceEpoch.toString(),
        };
        await LocalStorageService.saveSubmittedConcernSlip(localConcernSlip);
        return result;
      } else {
        final localConcernSlip = {
          ...body,
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'status': 'saved_locally',
          'submitted_at': DateTime.now().toIso8601String(),
          'local_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'error_note': 'Server temporarily unavailable - saved locally',
        };
        await LocalStorageService.saveSubmittedConcernSlip(localConcernSlip);
        return {
          'success': true,
          'message':
              'Concern slip saved locally. It will be synced when the server is available.',
          'id': localConcernSlip['id'],
          'saved_locally': true,
        };
      }
    } catch (e) {
      // Try local save on network error
      final localConcernSlip = {
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'priority': _mapPriorityToBackend(priority),
        if (unitId != null) 'unit_id': unitId,
        'attachments': attachments ?? [],
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'status': 'saved_locally',
        'submitted_at': DateTime.now().toIso8601String(),
        'local_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'error_note': 'Network error - saved locally',
      };
      await LocalStorageService.saveSubmittedConcernSlip(localConcernSlip);
      return {
        'success': true,
        'message':
            'Concern slip saved locally. It will be synced when connection is restored.',
        'id': localConcernSlip['id'],
        'saved_locally': true,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getTenantConcernSlips() async {
    try {
      final localSlips = await LocalStorageService.getSubmittedConcernSlips();
      final token = await AuthStorage.getToken();

      if (token != null && localSlips.isNotEmpty) {
        for (var slip in localSlips) {
          if (slip['id'] != null) {
            try {
              final response = await get(
                '/concern-slips/${slip['id']}',
                headers: _authHeaders(token),
              );
              if (response.statusCode == 200) {
                final serverSlip = jsonDecode(response.body) as Map<String, dynamic>;
                slip['status'] = serverSlip['status'] ?? slip['status'];
                slip['updated_at'] = serverSlip['updated_at'] ?? slip['updated_at'];
              }
            } catch (_) {}
          }
        }
      }
      return localSlips;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting tenant concern slips: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getConcernSlip(String concernSlipId) async {
    try {
      final token = await _requireToken();
      final response = await get(
        '/concern-slips/$concernSlipId',
        headers: _authHeaders(token),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get concern slip: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting concern slip: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllConcernSlips() async {
    try {
      final token = await _requireToken();
      final response = await get('/concern-slips/', headers: _authHeaders(token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get all concern slips: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting all concern slips: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getConcernSlipById(String concernSlipId) async {
    try {
      final token = await _requireToken();
      final response =
          await get('/concern-slips/$concernSlipId', headers: _authHeaders(token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get concern slip by ID: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting concern slip by ID: $e');
      rethrow;
    }
  }

  // ===== Maintenance (added) =====

  Future<List<Map<String, dynamic>>> getAllMaintenance() async {
    try {
      final token = await _requireToken();
      final response =
          await get('/maintenance/', headers: _authHeaders(token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get all maintenance: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting all maintenance: $e');
      rethrow;
    }
  }

  // ===== Announcements (added) =====

  Future<List<Map<String, dynamic>>> getAllAnnouncements() async {
    try {
      final token = await _requireToken();
      final response =
          await get('/announcements/', headers: _authHeaders(token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get all announcements: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getting all announcements: $e');
      rethrow;
    }
  }

  // ===== misc =====

  String _mapPriorityToBackend(String? uiPriority) {
    if (uiPriority == null) return 'medium';
    switch (uiPriority.toLowerCase().trim()) {
      case 'high':
        return 'high';
      case 'medium':
        return 'medium';
      case 'low':
        return 'low';
      case 'critical':
        return 'critical';
      default:
        return 'medium';
    }
  }

  Map<String, dynamic> _tryDecode(String body) {
    try {
      final m = jsonDecode(body);
      if (m is Map<String, dynamic>) return m;
      return {'raw': m};
    } catch (_) {
      return {'raw': body};
    }
  }

  String mapCategoryToBackend(String uiCategory) {
    return uiCategory; // passthrough for now
  }
}
