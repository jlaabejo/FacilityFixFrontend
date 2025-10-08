import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/services/auth_storage.dart';

class APIService {
  /// The app-configured role used to pick a default base URL at construction.
  final AppRole role;

  /// Base URL resolved from AppEnv or provided explicitly
  final String baseUrl;

  /// Default headers applied to every request (merged with per-call headers)
  Map<String, String> defaultHeaders;

  /// Role label used **only for logging**; kept in sync with Firebase token claims.
  String _currentRoleLabel;

  // ===== Constructors =====

  APIService({AppRole? roleOverride, Map<String, String>? headers})
    : role = roleOverride ?? AppEnv.role,
      baseUrl = AppEnv.baseUrlWithLan(roleOverride ?? AppEnv.role),
      defaultHeaders = {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      _currentRoleLabel = (roleOverride ?? AppEnv.role).name;

  APIService.fromBaseUrl(this.baseUrl, {Map<String, String>? headers})
    : role = AppEnv.role,
      defaultHeaders = {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      _currentRoleLabel = AppEnv.role.name;

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

  // Decode JWT payload safely
  Map<String, dynamic> _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return const {};
      String payload = parts[1];
      payload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);
      if (map is Map<String, dynamic>) return map;
      return const {};
    } catch (_) {
      return const {};
    }
  }

  // Map claim string to AppRole label
  String _mapRoleClaimToLabel(dynamic v) {
    final s = (v ?? '').toString().toLowerCase().trim();
    if (s == 'admin') return 'admin';
    if (s == 'staff') return 'staff';
    if (s == 'tenant') return 'tenant';
    return role.name; // fallback to constructor role
  }

  /// Sync the role label used in logs from the JWT claims (if available).
  Future<void> _refreshRoleLabelFromToken() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null || token.isEmpty) {
        _currentRoleLabel = role.name;
        return;
      }
      final claims = _decodeJwtPayload(token);
      final claimRole =
          claims['role'] ?? claims['custom:role'] ?? claims['auth/role'];
      _currentRoleLabel = _mapRoleClaimToLabel(claimRole);
    } catch (_) {
      _currentRoleLabel = role.name;
    }
  }

  void _logReq(String method, String path) {
    // ignore: avoid_print
    print('[API] $method $baseUrl$path (role=$_currentRoleLabel)');
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
      final local = await AuthStorage.getProfile();
      if (local != null) return local;

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

  // ===== ID Generation =====

  Future<String> getNextConcernSlipId() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/concern-slips/next-id',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['next_id'] ?? _generateFallbackId('CS');
      } else {
        return _generateFallbackId('CS');
      }
    } catch (e) {
      print('Error getting next concern slip ID: $e');
      return _generateFallbackId('CS');
    }
  }

  Future<String> getNextJobServiceId() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/job-services/next-id',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['next_id'] ?? _generateFallbackId('JS');
      } else {
        return _generateFallbackId('JS');
      }
    } catch (e) {
      print('Error getting next job service ID: $e');
      return _generateFallbackId('JS');
    }
  }

  Future<String> getNextWorkOrderId() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/work-orders/next-id',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['next_id'] ?? _generateFallbackId('WP');
      } else {
        return _generateFallbackId('WP');
      }
    } catch (e) {
      print('Error getting next work order ID: $e');
      return _generateFallbackId('WP');
    }
  }

  String _generateFallbackId(String prefix) {
    final now = DateTime.now();
    final year = now.year;
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    return '$prefix-$year-${dayOfYear.toString().padLeft(5, '0')}';
  }

  // ===== AI Categorization =====

  Future<Map<String, dynamic>> analyzeConcernWithAI({
    required String title,
    required String description,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = {'title': title, 'description': description};

      final response = await post(
        '/ai/analyze-concern',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Fallback to local analysis
        return _performLocalAnalysis(title, description);
      }
    } catch (e) {
      print('AI analysis error: $e');
      return _performLocalAnalysis(title, description);
    }
  }

  Map<String, dynamic> _performLocalAnalysis(String title, String description) {
    final combinedText = '$title $description'.toLowerCase();

    String category = 'general';
    String priority = 'medium';

    // Category detection
    if (combinedText.contains('water') ||
        combinedText.contains('leak') ||
        combinedText.contains('pipe') ||
        combinedText.contains('drain')) {
      category = 'plumbing';
    } else if (combinedText.contains('electric') ||
        combinedText.contains('power') ||
        combinedText.contains('light') ||
        combinedText.contains('outlet')) {
      category = 'electrical';
    } else if (combinedText.contains('air') ||
        combinedText.contains('ac') ||
        combinedText.contains('cooling') ||
        combinedText.contains('heating')) {
      category = 'hvac';
    } else if (combinedText.contains('door') ||
        combinedText.contains('window') ||
        combinedText.contains('wood') ||
        combinedText.contains('cabinet')) {
      category = 'carpentry';
    } else if (combinedText.contains('wall') ||
        combinedText.contains('cement') ||
        combinedText.contains('concrete') ||
        combinedText.contains('tile')) {
      category = 'masonry';
    }

    // Priority detection
    if (combinedText.contains('urgent') ||
        combinedText.contains('emergency') ||
        combinedText.contains('critical') ||
        combinedText.contains('dangerous')) {
      priority = 'critical';
    } else if (combinedText.contains('important') ||
        combinedText.contains('high') ||
        combinedText.contains('asap') ||
        combinedText.contains('quickly')) {
      priority = 'high';
    } else if (combinedText.contains('low') ||
        combinedText.contains('minor') ||
        combinedText.contains('small') ||
        combinedText.contains('whenever')) {
      priority = 'low';
    }

    return {
      'category': category,
      'priority': priority,
      'confidence': 0.8,
      'source': 'local_analysis',
    };
  }

  // ===== Concern Slips - Direct Firebase Integration =====

  Future<Map<String, dynamic>> submitConcernSlip({
    required String title,
    required String description,
    required String location,
    required String category,
    String priority = 'medium',
    String? unitId,
    List<String>? attachments,
    String? scheduleAvailability,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      // Get user profile for additional context
      final profile = await getUserProfile();
      final userId = profile?['id'] ?? profile?['user_id'];

      final body = {
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'priority': _mapPriorityToBackend(priority),
        'schedule_availability': scheduleAvailability,
        if (unitId != null) 'unit_id': unitId,
        if (userId != null) 'user_id': userId,
        'attachments': attachments ?? [],
        'request_type': 'Concern Slip',
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      };

      print('[API] Submitting concern slip directly to Firebase...');

      final response = await post(
        '/concern-slips/',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;

        // Generate formatted ID if not provided
        if (!result.containsKey('formatted_id') && result.containsKey('id')) {
          final now = DateTime.now();
          final year = now.year;
          final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
          result['formatted_id'] =
              'CS-$year-${dayOfYear.toString().padLeft(5, '0')}';
        }

        print(
          '[API] Concern slip submitted successfully to Firebase: ${result['formatted_id']}',
        );
        return {
          'success': true,
          'message': 'Concern slip submitted successfully',
          'id': result['id'],
          'formatted_id': result['formatted_id'],
          'data': result,
        };
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Server error: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('[API] Error submitting concern slip: $e');
      throw Exception('Failed to submit concern slip: $e');
    }
  }

  // ===== Job Services =====

  Future<Map<String, dynamic>> submitJobService({
    required String notes,
    required String location,
    String? unitId,
    List<String>? attachments,
    String? scheduleAvailability,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      // Get user profile for additional context
      final profile = await getUserProfile();
      final userId = profile?['id'] ?? profile?['user_id'];

      final body = {
        'notes': notes,
        'location': location,
        'schedule_availability': scheduleAvailability,
        if (unitId != null) 'unit_id': unitId,
        if (userId != null) 'user_id': userId,
        'attachments': attachments ?? [],
        'request_type': 'Job Service',
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      };

      print('[API] Submitting job service directly to Firebase...');

      final response = await post(
        '/job-services/',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;

        // Generate formatted ID if not provided
        if (!result.containsKey('formatted_id') && result.containsKey('id')) {
          final now = DateTime.now();
          final year = now.year;
          final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
          result['formatted_id'] =
              'JS-$year-${dayOfYear.toString().padLeft(5, '0')}';
        }

        print(
          '[API] Job service submitted successfully to Firebase: ${result['formatted_id']}',
        );
        return {
          'success': true,
          'message': 'Job service submitted successfully',
          'id': result['id'],
          'formatted_id': result['formatted_id'],
          'data': result,
        };
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Server error: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('[API] Error submitting job service: $e');
      throw Exception('Failed to submit job service: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTenantJobServices() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      print('[API] Fetching job services from concern-slips endpoint...');

      // Use concern-slips endpoint but filter for Job Service type
      final response = await get(
        '/concern-slips/',
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Filter for Job Service requests only
        final jobServices =
            data
                .where((item) => item['request_type'] == 'Job Service')
                .cast<Map<String, dynamic>>()
                .toList();

        print(
          '[API] Retrieved ${jobServices.length} job services from Firebase',
        );
        return jobServices;
      } else {
        throw Exception('Failed to fetch job services: ${response.body}');
      }
    } catch (e) {
      print('[API] Error getting tenant job services: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // ===== Work Orders =====

  Future<Map<String, dynamic>> submitWorkOrder({
    required String requestType,
    required String location,
    required String validFrom,
    required String validTo,
    required List<Map<String, String>> contractors,
    String? unitId,
    List<String>? attachments,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      // Get user profile for additional context
      final profile = await getUserProfile();
      final userId = profile?['id'] ?? profile?['user_id'];

      final body = {
        'request_type_detail': requestType,
        'location': location,
        'valid_from': validFrom,
        'valid_to': validTo,
        'contractors': contractors,
        if (unitId != null) 'unit_id': unitId,
        if (userId != null) 'user_id': userId,
        'attachments': attachments ?? [],
        'request_type': 'Work Order Permit',
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      };

      print('[API] Submitting work order directly to Firebase...');

      final response = await post(
        '/work-orders/',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;

        // Generate formatted ID if not provided
        if (!result.containsKey('formatted_id') && result.containsKey('id')) {
          final now = DateTime.now();
          final year = now.year;
          final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
          result['formatted_id'] =
              'WP-$year-${dayOfYear.toString().padLeft(5, '0')}';
        }

        print(
          '[API] Work order submitted successfully to Firebase: ${result['formatted_id']}',
        );
        return {
          'success': true,
          'message': 'Work order submitted successfully',
          'id': result['id'],
          'formatted_id': result['formatted_id'],
          'data': result,
        };
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Server error: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('[API] Error submitting work order: $e');
      throw Exception('Failed to submit work order: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTenantWorkOrders() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      print('[API] Fetching work orders from concern-slips endpoint...');

      // Use concern-slips endpoint but filter for Work Order type
      final response = await get(
        '/concern-slips/',
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Filter for Work Order requests only
        final workOrders =
            data
                .where(
                  (item) =>
                      item['request_type'] == 'Work Order Permit' ||
                      item['request_type'] == 'Work Order',
                )
                .cast<Map<String, dynamic>>()
                .toList();

        print('[API] Retrieved ${workOrders.length} work orders from Firebase');
        return workOrders;
      } else {
        throw Exception('Failed to fetch work orders: ${response.body}');
      }
    } catch (e) {
      print('[API] Error getting tenant work orders: $e');
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTenantConcernSlips() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      print('[API] Fetching concern slips directly from Firebase...');

      final response = await get(
        '/concern-slips/',
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Filter for Concern Slip requests only
        final concernSlips =
            data
                .where(
                  (item) =>
                      item['request_type'] == 'Concern Slip' ||
                      item['request_type'] == null,
                )
                .cast<Map<String, dynamic>>()
                .toList();

        print(
          '[API] Retrieved ${concernSlips.length} concern slips from Firebase',
        );
        return concernSlips;
      } else {
        throw Exception('Failed to fetch concern slips: ${response.body}');
      }
    } catch (e) {
      print('[API] Error getting tenant concern slips: $e');
      throw Exception('Failed to fetch concern slips: $e');
    }
  }

  Future<Map<String, dynamic>> updateConcernSlip({
    required String concernSlipId,
    String? title,
    String? description,
    String? location,
    String? category,
    String? priority,
    String? unitId,
    List<String>? attachments,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (location != null) body['location'] = location;
      if (category != null) body['category'] = category;
      if (priority != null) body['priority'] = _mapPriorityToBackend(priority);
      if (unitId != null) body['unit_id'] = unitId;
      if (attachments != null) body['attachments'] = attachments;

      final response = await http.patch(
        _u('/concern-slips/$concernSlipId'),
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to update concern slip: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error updating concern slip: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteConcernSlip(String concernSlipId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await delete(
        '/concern-slips/$concernSlipId',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to delete concern slip: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error deleting concern slip: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getConcernSlipById(String concernSlipId) async {
    try {
      await _refreshRoleLabelFromToken();
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
          'Failed to get concern slip by ID: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting concern slip by ID: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllConcernSlips() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final response = await get(
        '/concern-slips/',
        headers: _authHeaders(token),
      );

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
      print('Error getting all concern slips: $e');
      rethrow;
    }
  }

  // ===== Maintenance (added) =====

  Future<List<Map<String, dynamic>>> getAllMaintenance() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final response = await get('/maintenance/', headers: _authHeaders(token));

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
      print('Error getting all maintenance: $e');
      rethrow;
    }
  }

  // ===== Announcements =====

  Future<List<Map<String, dynamic>>> getAllAnnouncements({
    required String buildingId,
    String audience = 'all',
    bool activeOnly = true,
    int limit = 50,
    bool includeDismissed = false,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final qs =
          Uri(
            queryParameters: {
              'building_id': buildingId,
              'audience': audience,
              'active_only': activeOnly.toString(),
              'limit': limit.toString(),
              'include_dismissed': includeDismissed.toString(),
            },
          ).query;

      final response = await get(
        '/announcements?$qs',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final list = decoded['announcements'];
          if (list is List) {
            return list.whereType<Map<String, dynamic>>().toList(
              growable: false,
            );
          }
          return const <Map<String, dynamic>>[];
        }
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList(
            growable: false,
          );
        }
        return const <Map<String, dynamic>>[];
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get announcements: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting announcements: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAnnouncementById(
    String announcementId,
  ) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final response = await get(
        '/announcements/$announcementId',
        headers: _authHeaders(token),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        throw Exception('Unexpected response format for announcement detail.');
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get announcement: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting announcement by id: $e');
      rethrow;
    }
  }

  Future<bool> dismissAnnouncement(String announcementId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final response = await post(
        '/announcements/$announcementId/dismiss',
        headers: _authHeaders(token),
        body: '{}',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return (decoded is Map<String, dynamic>) &&
            (decoded['success'] == true);
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to dismiss announcement: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error dismissing announcement: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createAnnouncement({
    required String title,
    required String buildingId,
    String audience = 'all',
    String announcementType = 'General Announcement',
    String locationAffected = 'Lobby',
    String? description,
    String? attachment,
    bool isActive = true,
    String? scheduleStart,
    String? scheduleEnd,
    String? contactNumber,
    String? contactEmail,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final body = <String, dynamic>{
        'title': title,
        'building_id': buildingId,
        'audience': audience,
        'announcement_type': announcementType,
        'location_affected': locationAffected,
        'description': description,
        'attachment': attachment,
        'is_active': isActive,
        'schedule_start': scheduleStart,
        'schedule_end': scheduleEnd,
        'contact_number': contactNumber,
        'contact_email': contactEmail,
        'send_notifications': true,
      };

      final resp = await post(
        '/announcements/',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(resp.body);
        throw Exception(
          'Failed to create announcement: ${errorBody['detail'] ?? resp.body}',
        );
      }
    } catch (e) {
      print('Error createAnnouncement: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateAnnouncement(
    String announcementId, {
    String? title,
    String? audience,
    String? announcementType,
    String? locationAffected,
    String? buildingId,
    String? description,
    String? attachment,
    bool? isActive,
    String? scheduleStart,
    String? scheduleEnd,
    String? contactNumber,
    String? contactEmail,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final body = <String, dynamic>{
        if (title != null) 'title': title,
        if (audience != null) 'audience': audience,
        if (announcementType != null) 'announcement_type': announcementType,
        if (locationAffected != null) 'location_affected': locationAffected,
        if (buildingId != null) 'building_id': buildingId,
        if (description != null) 'description': description,
        if (attachment != null) 'attachment': attachment,
        if (isActive != null) 'is_active': isActive,
        if (scheduleStart != null) 'schedule_start': scheduleStart,
        if (scheduleEnd != null) 'schedule_end': scheduleEnd,
        if (contactNumber != null) 'contact_number': contactNumber,
        if (contactEmail != null) 'contact_email': contactEmail,
        'notify_changes': true,
      };

      final resp = await put(
        '/announcements/$announcementId',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(resp.body);
        throw Exception(
          'Failed to update announcement: ${errorBody['detail'] ?? resp.body}',
        );
      }
    } catch (e) {
      print('Error updateAnnouncement: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deactivateAnnouncement(
    String announcementId, {
    bool notifyDeactivation = false,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final qs =
          Uri(
            queryParameters: {
              'notify_deactivation': notifyDeactivation.toString(),
            },
          ).query;

      final resp = await delete(
        '/announcements/$announcementId?$qs',
        headers: _authHeaders(token),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(resp.body);
        throw Exception(
          'Failed to deactivate announcement: ${errorBody['detail'] ?? resp.body}',
        );
      }
    } catch (e) {
      print('Error deactivateAnnouncement: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rebroadcastAnnouncement(
    String announcementId,
  ) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final resp = await post(
        '/announcements/$announcementId/rebroadcast',
        headers: _authHeaders(token),
        body: '{}',
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(resp.body);
        throw Exception(
          'Failed to rebroadcast announcement: ${errorBody['detail'] ?? resp.body}',
        );
      }
    } catch (e) {
      print('Error rebroadcastAnnouncement: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAnnouncementTypes() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final resp = await get(
        '/announcements/types/available',
        headers: _authHeaders(token),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(resp.body);
        throw Exception(
          'Failed to get announcement types: ${errorBody['detail'] ?? resp.body}',
        );
      }
    } catch (e) {
      print('Error getAnnouncementTypes: $e');
      rethrow;
    }
  }

  // ===== Tenant Requests =====

  Future<List<Map<String, dynamic>>> getAllTenantRequests() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      // Fetch all requests from the concern-slips endpoint (which contains all request types)
      final response = await get(
        '/concern-slips/',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        final allRequests =
            data.map((item) {
              final map = item as Map<String, dynamic>;

              // Ensure request_type is set
              if (!map.containsKey('request_type') ||
                  map['request_type'] == null) {
                map['request_type'] = 'Concern Slip';
              }

              // Add formatted_id if not present
              if (!map.containsKey('formatted_id')) {
                final id = map['id'] ?? '';
                final requestType = map['request_type'] ?? 'Concern Slip';
                final now = DateTime.now();
                final year = now.year;

                String prefix = 'CS';
                if (requestType == 'Job Service') {
                  prefix = 'JS';
                } else if (requestType == 'Work Order Permit' ||
                    requestType == 'Work Order') {
                  prefix = 'WP';
                }

                map['formatted_id'] =
                    '$prefix-$year-${id.toString().padLeft(5, '0')}';
              }

              return map;
            }).toList();

        // Sort by submission date (latest first)
        allRequests.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['submitted_at'] ?? a['created_at'] ?? '') ??
              DateTime.now();
          final bDate =
              DateTime.tryParse(b['submitted_at'] ?? b['created_at'] ?? '') ??
              DateTime.now();
          return bDate.compareTo(aDate);
        });

        return allRequests;
      } else {
        throw Exception('Failed to fetch tenant requests: ${response.body}');
      }
    } catch (e) {
      print('Error getting all tenant requests: $e');
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
