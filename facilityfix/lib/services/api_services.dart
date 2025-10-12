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
    : role = roleOverride ?? AppRole.tenant,
      baseUrl = AppEnv.baseUrlWithLan(roleOverride ?? AppRole.tenant),
      defaultHeaders = {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      _currentRoleLabel = (roleOverride ?? AppRole.tenant).name;

  APIService.fromBaseUrl(this.baseUrl, {Map<String, String>? headers, AppRole? roleOverride})
    : role = roleOverride ?? AppRole.tenant,
      defaultHeaders = {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      },
      _currentRoleLabel = (roleOverride ?? AppRole.tenant).name;

  // ===== Low-level helpers =====
  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
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
  

    Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _logReq('PATCH', path);
    final resolvedToken = await _requireToken();

    return http.patch(_u(path), headers: _mergeHeaders(_authHeaders(resolvedToken)), body: body);
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

  /// Static method to get the authentication token
  /// Used by other services that need to access the token
  static Future<String> requireToken() async {
    final t = await AuthStorage.getToken();
    if (t == null || t.isEmpty) {
      throw Exception('Authentication token not found. Please login again.');
    }
    return t;
  }

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

  /// Fetch current user's complete profile from server
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      print('[API] Fetching current user profile from server...');

      // Try the complete profile endpoint first
      final response = await get('/profiles/me/complete', headers: _authHeaders(token));
      
      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] Profile fetched successfully from /profiles/me/complete');
        
        // Save to local storage for offline access
        await AuthStorage.saveProfile(profileData);
        return profileData;
      }
      
      // Fallback to /auth/me if complete profile is not available
      final fallbackResponse = await get('/auth/me', headers: _authHeaders(token));
      if (fallbackResponse.statusCode == 200) {
        final profileData = jsonDecode(fallbackResponse.body) as Map<String, dynamic>;
        print('[API] Profile fetched successfully from /auth/me fallback');
        
        // Save to local storage
        await AuthStorage.saveProfile(profileData);
        return profileData;
      }
      
      print('[API] Failed to fetch profile from server: ${response.statusCode}');
      return null;
      
    } catch (e) {
      print('[API] Error fetching current user profile: $e');
      return null;
    }
  }

  /// Update current user's profile
  Future<Map<String, dynamic>> updateCurrentUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? birthDate,
    String? department,
    String? staffDepartment,
    List<String>? departments,
    List<String>? staffDepartments,
    String? buildingId,
    String? unitId,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      // Get current user info to determine which endpoint to use
      final currentProfile = await fetchCurrentUserProfile();
      if (currentProfile == null) {
        throw Exception('Could not fetch current user profile');
      }

      final userId = currentProfile['user_id'] ?? currentProfile['uid'];
      if (userId == null) {
        throw Exception('Could not determine user ID for profile update');
      }

      print('[API] Updating profile for user: $userId');

      final updateData = <String, dynamic>{};
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (birthDate != null) updateData['birth_date'] = birthDate;
      if (department != null) updateData['department'] = department;
      if (staffDepartment != null) updateData['staff_department'] = staffDepartment;
      if (departments != null) updateData['departments'] = departments;
      if (staffDepartments != null) updateData['staff_departments'] = staffDepartments;
      if (buildingId != null) updateData['building_id'] = buildingId;
      if (unitId != null) updateData['unit_id'] = unitId;

      if (updateData.isEmpty) {
        throw Exception('No fields provided to update');
      }

      print('[API] Update data: $updateData');

      final response = await put(
        '/users/$userId',
        headers: _authHeaders(token),
        body: jsonEncode(updateData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] Profile updated successfully');
        
        // Refresh the cached profile
        await fetchCurrentUserProfile();
        
        return result;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to update profile: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('[API] Error updating profile: $e');
      rethrow;
    }
  }

  /// Get user profile with local-first approach (for backward compatibility)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // Try to get from local storage first
      final local = await AuthStorage.getProfile();
      
      // If we have local data and it's recent (less than 1 hour old), use it
      if (local != null) {
        final updatedAt = local['updated_at'] as String?;
        if (updatedAt != null) {
          final lastUpdate = DateTime.tryParse(updatedAt);
          if (lastUpdate != null && 
              DateTime.now().difference(lastUpdate).inHours < 1) {
            print('[API] Using cached profile data');
            return local;
          }
        }
      }

      // Otherwise fetch from server
      print('[API] Fetching fresh profile data from server');
      return await fetchCurrentUserProfile();
      
    } catch (e) {
      print('[API] Error in getUserProfile: $e');
      // Fallback to local storage if server fetch fails
      return await AuthStorage.getProfile();
    }
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
        '/work-order-permits/next-id',
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

      final body = {'title': title, 'text': description};

      final response = await post(
        '/_debug_logits?force_translate=true',
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
    String? notes, // Made optional
    required String location,
    String? unitId,
    List<String>? attachments,
    String? scheduleAvailability,
    DateTime? startTime, // Added structured times
    DateTime? endTime,   // Added structured times
    String? concernSlipId,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = {
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'location': location,
        'schedule_availability': scheduleAvailability,
        if (startTime != null) 'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime.toIso8601String(),
        if (unitId != null) 'unit_id': unitId,
        if (concernSlipId != null) 'concern_slip_id': concernSlipId,
        'attachments': attachments ?? [],
      };

      print('[API] Submitting job service request...');

      // If concernSlipId is provided, use the tenant job service endpoint
      final endpoint = concernSlipId != null 
          ? '/tenant-job-services/' 
          : '/job-services/';

      final response = await post(
        endpoint,
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

      final body = {
        'request_type_detail': requestType,
        'location': location,
        'valid_from': validFrom,
        'valid_to': validTo,
        'contractors': contractors,
        if (unitId != null) 'unit_id': unitId,
        'attachments': attachments ?? [],
      };

      print('[API] Submitting work order permit request...');

      final response = await post(
        '/work-order-permits/',
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] getConcernSlipById response:');
        print('  Status: ${data['status']}');
        print('  Resolution Type: ${data['resolution_type']}');
        print('  Full data keys: ${data.keys.toList()}');
        return data;
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

  Future<Map<String, dynamic>> getJobServiceById(String jobServiceId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final response = await get(
        '/job-services/$jobServiceId',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] getJobServiceById response:');
        print('  Status: ${data['status']}');
        print('  Full data keys: ${data.keys.toList()}');
        return data;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get job service by ID: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting job service by ID: $e');
      rethrow;
    }
  }

  /// Update job service status (for assigned staff and admins)
  Future<Map<String, dynamic>> updateJobServiceStatus({
    required String jobServiceId,
    required String status,
    String? notes,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      
      final body = {
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      
      final response = await patch(
        '/job-services/$jobServiceId/status',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] updateJobServiceStatus response:');
        print('  Status: ${data['status']}');
        return data;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to update job service status: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error updating job service status: $e');
      rethrow;
    }
  }

  /// Complete a job service request
  Future<Map<String, dynamic>> completeJobService(String jobServiceId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      
      final response = await patch(
        '/job-services/$jobServiceId/complete',
        headers: _authHeaders(token),
        body: '{}',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] completeJobService response:');
        print('  Success: ${data['success']}');
        return data;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to complete job service: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error completing job service: $e');
      rethrow;
    }
  }

  /// Add work notes to job service
  Future<Map<String, dynamic>> addJobServiceNotes({
    required String jobServiceId,
    required String notes,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      
      final body = {
        'notes': notes,
      };
      
      final response = await post(
        '/job-services/$jobServiceId/notes',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] addJobServiceNotes response:');
        print('  Success: completed');
        return data;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to add job service notes: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error adding job service notes: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWorkOrderById(String workOrderId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final response = await get(
        '/work-orders/$workOrderId',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] getWorkOrderById response:');
        print('  Status: ${data['status']}');
        print('  Full data keys: ${data.keys.toList()}');
        return data;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get work order by ID: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting work order by ID: $e');
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
      print('[API] getAllMaintenance - Token length: ${token.length}');
      print('[API] getAllMaintenance - Making request to: $baseUrl/maintenance/');
      
      final response = await get('/maintenance/', headers: _authHeaders(token));
      print('[API] getAllMaintenance - Response status: ${response.statusCode}');
      print('[API] getAllMaintenance - Response body length: ${response.body.length}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        print('[API] getAllMaintenance - Parsed ${data.length} maintenance tasks');
        return data.cast<Map<String, dynamic>>();
      } else {
        print('[API] getAllMaintenance - Error response: ${response.body}');
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

  Future<Map<String, dynamic>> getMaintenanceTaskById(String taskId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final response = await get('/maintenance/$taskId', headers: _authHeaders(token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get maintenance task: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting maintenance task: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMaintenanceTask(String taskId, Map<String, dynamic> updateData) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      final response = await put(
        '/maintenance/$taskId',
        headers: _authHeaders(token),
        body: jsonEncode(updateData),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to update maintenance task: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error updating maintenance task: $e');
      rethrow;
    }
  }

  // ===== Inventory =====

  Future<Map<String, dynamic>> getAllInventoryItems({
    bool includeInactive = false,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      
      final queryParams = includeInactive ? '?include_inactive=true' : '';
      final response = await get(
        '/inventory/items$queryParams',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get all inventory items: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting all inventory items: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInventoryItems({
    required String buildingId,
    bool includeInactive = false,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();
      
      final queryParams = includeInactive ? '?include_inactive=true' : '';
      final response = await get(
        '/inventory/buildings/$buildingId/items$queryParams',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get inventory items: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting inventory items: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createInventoryRequest({
    required String inventoryId,
    required String buildingId,
    required int quantityRequested,
    required String purpose,
    required String requestedBy,
    String? maintenanceTaskId,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = jsonEncode({
        'inventory_id': inventoryId,
        'building_id': buildingId,
        'quantity_requested': quantityRequested,
        'purpose': purpose,
        'requested_by': requestedBy,
        'status': 'pending',
        if (maintenanceTaskId != null) 'maintenance_task_id': maintenanceTaskId,
        if (maintenanceTaskId != null) 'reference_type': 'maintenance_task',
        if (maintenanceTaskId != null) 'reference_id': maintenanceTaskId,
      });

      final response = await post(
        '/inventory/requests',
        headers: _authHeaders(token),
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to create inventory request: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error creating inventory request: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInventoryRequestsByMaintenanceTask(
    String maintenanceTaskId,
  ) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/inventory/maintenance-task/$maintenanceTaskId/requests',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to load inventory requests for maintenance task: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error fetching inventory requests for maintenance task: $e');
      rethrow;
    }
  }

  /// Get all inventory requests with optional filters
  Future<List<Map<String, dynamic>>> getInventoryRequests({
    String? buildingId,
    String? status,
    String? requestedBy,
    String? maintenanceTaskId,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final queryParams = <String>[];
      if (buildingId != null) queryParams.add('building_id=$buildingId');
      if (status != null) queryParams.add('status=$status');
      if (requestedBy != null) queryParams.add('requested_by=$requestedBy');
      if (maintenanceTaskId != null) queryParams.add('maintenance_task_id=$maintenanceTaskId');

      final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await get(
        '/inventory/requests$query',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        return [];
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get inventory requests: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting inventory requests: $e');
      rethrow;
    }
  }

  /// Get a specific inventory item by ID
  Future<Map<String, dynamic>?> getInventoryItemById(String itemId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/inventory/items/$itemId',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get inventory item: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting inventory item by ID: $e');
      rethrow;
    }
  }

  /// Get a specific inventory request by ID
  Future<Map<String, dynamic>?> getInventoryRequestById(String requestId) async {
    try {
      // Get all requests and find the matching one
      final requests = await getInventoryRequests();
      final found = requests.where(
        (req) => req['id'] == requestId || req['_doc_id'] == requestId,
      ).toList();
      return found.isNotEmpty ? found.first : null;
    } catch (e) {
      print('Error getting inventory request by ID: $e');
      return null;
    }
  }

  // ===== Announcements =====

  Future<List<Map<String, dynamic>>> getAllAnnouncements({
    String buildingId = 'default_building',
    String audience = 'all',
    bool activeOnly = true,
    int limit = 50,
    bool includeDismissed = false,
    String? announcementType,
    String? priorityLevel,
    String? tags,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      print('[API] Fetching announcements with building_id: $buildingId');

      // Build query parameters
      final queryParams = <String, String>{
        'building_id': buildingId,
        'audience': audience,
        'active_only': activeOnly.toString(),
        'limit': limit.toString(),
        'published_only': 'true',
      };
      
      if (announcementType != null) {
        queryParams['announcement_type'] = announcementType;
      }
      if (priorityLevel != null) {
        queryParams['priority_level'] = priorityLevel;
      }
      if (tags != null) {
        queryParams['tags'] = tags;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await get(
        '/announcements?$queryString',
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

  /// Get user-targeted announcements
  Future<List<Map<String, dynamic>>> getUserTargetedAnnouncements({
    required String buildingId,
    bool activeOnly = true,
    int limit = 50,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final qs = Uri(
        queryParameters: {
          'building_id': buildingId,
          'active_only': activeOnly.toString(),
          'limit': limit.toString(),
        },
      ).query;

      final response = await get(
        '/announcements/user/targeted?$qs',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final list = decoded['announcements'];
          if (list is List) {
            return list.whereType<Map<String, dynamic>>().toList(growable: false);
          }
          return const <Map<String, dynamic>>[];
        }
        return const <Map<String, dynamic>>[];
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to get targeted announcements: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getUserTargetedAnnouncements: $e');
      rethrow;
    }
  }

  /// Mark announcement as viewed
  Future<Map<String, dynamic>> markAnnouncementViewed(String announcementId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await post(
        '/announcements/$announcementId/view',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = _tryDecode(response.body);
        throw Exception(
          'Failed to mark announcement as viewed: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error markAnnouncementViewed: $e');
      rethrow;
    }
  }

  // ===== Tenant Requests =====

  Future<List<Map<String, dynamic>>> getAllTenantRequests([String user_id = ""]) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      // Fetch all requests from the unified tenant-requests endpoint
      final response = await get(
        '/tenant-requests/?user_id=' + user_id,
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

  // ===== Staff Management =====

  /// Get all staff members with optional filtering by department
  Future<List<Map<String, dynamic>>> getStaffMembers({
    String? department,
    bool availableOnly = false,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      // Build query parameters
      final queryParams = <String, String>{};
      if (department != null && department.isNotEmpty) {
        queryParams['department'] = department;
      }
      if (availableOnly) {
        queryParams['available_only'] = 'true';
      }

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

      print('[API] Fetching staff members with filters: $queryParams');

      final response = await get(
        '/users/staff$queryString',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final staffList = data.cast<Map<String, dynamic>>();
          print('[API] Retrieved ${staffList.length} staff members');
          return staffList;
        }
        return [];
      } else {
        print('[API] Error fetching staff members: ${response.statusCode} ${response.body}');
        throw Exception('Failed to fetch staff members: ${response.statusCode}');
      }
    } catch (e) {
      print('[API] Error getting staff members: $e');
      rethrow;
    }
  }

  /// Assign a staff member to a concern slip for assessment
  Future<Map<String, dynamic>> assignStaffToConcernSlip(
    String concernSlipId,
    String staffUserId,
  ) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = jsonEncode({
        'assigned_to': staffUserId,
      });

      print(
        '[API] Assigning staff $staffUserId to concern slip $concernSlipId',
      );

      final response = await http.patch(
        _u('/concern-slips/$concernSlipId/assign-staff'),
        headers: _authHeaders(token),
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] Staff assigned successfully');
        return data;
      } else {
        print(
          '[API] Error assigning staff: ${response.statusCode} ${response.body}',
        );
        throw Exception(
          'Failed to assign staff: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('[API] Error assigning staff to concern slip: $e');
      rethrow;
    }
  }

  /// Set resolution type for an assessed concern slip (Admin only)
  Future<Map<String, dynamic>> setResolutionType(
    String concernSlipId, {
    required String resolutionType, // 'job_service' or 'work_order'
    String? adminNotes,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = <String, dynamic>{
        'resolution_type': resolutionType,
      };
      if (adminNotes != null && adminNotes.isNotEmpty) {
        body['admin_notes'] = adminNotes;
      }

      print(
        '[API] Setting resolution type to $resolutionType for concern slip $concernSlipId',
      );

      final response = await http.patch(
        _u('/concern-slips/$concernSlipId/set-resolution-type'),
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('[API] Resolution type set successfully');
        return data;
      } else {
        print(
          '[API] Error setting resolution type: ${response.statusCode} ${response.body}',
        );
        final err = _tryDecode(response.body);
        throw Exception(
          err['detail'] ?? 'Failed to set resolution type: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[API] Error setting resolution type: $e');
      rethrow;
    }
  }

  // ===== Chat =====

  /// Create or get a chat room
  Future<Map<String, dynamic>> createOrGetChatRoom({
    required List<String> participants,
    String roomType = 'direct',
    String? concernSlipId,
    String? jobServiceId,
    String? workPermitId,
    String? roomName,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = {
        'participants': participants,
        'room_type': roomType,
        if (concernSlipId != null) 'concern_slip_id': concernSlipId,
        if (jobServiceId != null) 'job_service_id': jobServiceId,
        if (workPermitId != null) 'work_permit_id': workPermitId,
        if (roomName != null) 'room_name': roomName,
      };

      final response = await post(
        '/chat/rooms',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create/get chat room: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating/getting chat room: $e');
      rethrow;
    }
  }

  /// Get all chat rooms for current user
  Future<List<Map<String, dynamic>>> getUserChatRooms({int limit = 50}) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/chat/rooms?limit=$limit',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to get chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting chat rooms: $e');
      return [];
    }
  }

  /// Get a specific chat room by ID
  Future<Map<String, dynamic>?> getChatRoom(String roomId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/chat/rooms/$roomId',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get chat room: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting chat room: $e');
      return null;
    }
  }

  /// Get chat room by reference (concern slip, job service, work permit)
  Future<Map<String, dynamic>?> getChatRoomByReference({
    required String referenceType,  // 'concern_slip', 'job_service', 'work_permit'
    required String referenceId,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/chat/rooms/by-reference/$referenceType/$referenceId',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>?;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to get chat room by reference: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting chat room by reference: $e');
      return null;
    }
  }

  /// Send a message to a chat room
  Future<Map<String, dynamic>> sendChatMessage({
    required String roomId,
    required String messageText,
    String messageType = 'text',
    List<String>? attachments,
    String? replyTo,
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = {
        'room_id': roomId,
        'message_text': messageText,
        'message_type': messageType,
        if (attachments != null) 'attachments': attachments,
        if (replyTo != null) 'reply_to': replyTo,
      };

      final response = await post(
        '/chat/messages',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Get messages for a chat room
  Future<List<Map<String, dynamic>>> getChatMessages({
    required String roomId,
    int limit = 100,
    String? before,  // ISO timestamp
  }) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      String url = '/chat/rooms/$roomId/messages?limit=$limit';
      if (before != null) {
        url += '&before=$before';
      }

      final response = await get(url, headers: _authHeaders(token));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      } else {
        throw Exception('Failed to get messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  /// Mark all messages in a room as read
  Future<bool> markMessagesAsRead(String roomId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final body = {'room_id': roomId};

      final response = await post(
        '/chat/messages/mark-read',
        headers: _authHeaders(token),
        body: jsonEncode(body),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  /// Delete a message
  Future<bool> deleteChatMessage(String messageId) async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await delete(
        '/chat/messages/$messageId',
        headers: _authHeaders(token),
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error deleting message: $e');
      return false;
    }
  }

  /// Get unread message count
  Future<int> getUnreadChatCount() async {
    try {
      await _refreshRoleLabelFromToken();
      final token = await _requireToken();

      final response = await get(
        '/chat/unread-count',
        headers: _authHeaders(token),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final dataMap = data['data'] as Map<String, dynamic>?;
        return dataMap?['unread_count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }
}
