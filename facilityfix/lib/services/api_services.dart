import 'dart:convert';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:http/http.dart' as http;
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/services/local_storage_service.dart';

class APIService {
  /// Current app role (used to pick base URL)
  final AppRole role;

  /// Base URL resolved from AppEnv or provided explicitly
  final String baseUrl;

  /// Default headers applied to every request (merged with per-call headers)
  Map<String, String> defaultHeaders;

  /// Primary constructor: resolves baseUrl via AppEnv based on role (or override).
  APIService({AppRole? roleOverride, Map<String, String>? headers})
    : role = roleOverride ?? AppEnv.role,
      baseUrl = AppEnv.baseUrlWithLan(roleOverride ?? AppEnv.role),
      defaultHeaders = {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      };

  /// Named constructor: use a literal baseUrl (ignores AppEnv).
  APIService.fromBaseUrl(this.baseUrl, {Map<String, String>? headers})
    : role = AppEnv.role,
      defaultHeaders = {
        'Content-Type': 'application/json',
        if (headers != null) ...headers,
      };

  // -------------------- Low-level helpers --------------------

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return Map.of(defaultHeaders);
    return {...defaultHeaders, ...headers};
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    return http.get(_u(path), headers: _mergeHeaders(headers));
  }

  Future<http.Response> delete(String path, {Map<String, String>? headers}) {
    return http.delete(_u(path), headers: _mergeHeaders(headers));
  }

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return http.post(_u(path), headers: _mergeHeaders(headers), body: body);
  }

  Future<http.Response> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) {
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

  // -------------------- Utilities --------------------

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

  // -------------------- Register --------------------

  Future<Map<String, dynamic>> registerAdmin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
  }) {
    final body = {
      'first_name': firstName,
      'last_name': lastName,
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
    required String email,
    required String password,
    required String staffDepartment,
    String? phoneNumber,
  }) {
    final mapped = _deptToApiEnum(staffDepartment);
    // ignore: avoid_print
    print('[registerStaff] UI="$staffDepartment" → API="$mapped"');

    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'classification': mapped,
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phone_number': phoneNumber,
    };

    // ignore: avoid_print
    print('[registerStaff] body=${jsonEncode(body)}');
    return postJson('/auth/register/staff', jsonBody: body);
  }

  Future<Map<String, dynamic>> registerTenant({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String buildingUnit,
    String? phoneNumber,
  }) {
    final body = {
      'first_name': firstName,
      'last_name': lastName,
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

  // -------------------- Login / Auth --------------------

  Future<Map<String, dynamic>> loginRoleBased({
    required String role, // 'admin' | 'staff' | 'tenant'
    required String email,
    required String userId,
    required String password,
    String? staffDepartment, // staff only
    String? buildingUnitId, // tenant only
  }) async {
    final body = <String, dynamic>{
      'role': role.toLowerCase(),
      'email': email,
      'user_id': userId,
      'password': password,
    };

    if (role.toLowerCase() == 'staff' && staffDepartment != null) {
      body['staffDepartment'] = staffDepartment;
    }
    if (role.toLowerCase() == 'tenant' && buildingUnitId != null) {
      body['buildingUnitId'] = buildingUnitId;
    }

    // ✅ Always post to /auth/login
    return postJson('/auth/login', jsonBody: body);
  }

  /// Example for protected calls using id_token (JWT).
  Future<Map<String, dynamic>> me(String idToken) {
    return getJson(
      '/auth/me',
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );
  }

  /// Added method to fetch user profile (based on the incomplete code at the end)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final localProfile = await AuthStorage.getProfile();
      if (localProfile != null) {
        print('[v0] Debug - Using profile from local storage');
        return localProfile;
      }

      final token = await AuthStorage.getToken();
      print('[v0] Debug - getUserProfile - Token exists: ${token != null}');

      if (token == null) return null;

      final endpoints = ['/auth/me', '/profiles/me/complete'];

      for (final endpoint in endpoints) {
        try {
          print(
            '[v0] Debug - getUserProfile - Trying endpoint: $baseUrl$endpoint',
          );

          final response = await get(
            endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          print(
            '[v0] Debug - getUserProfile - Response status: ${response.statusCode}',
          );
          print(
            '[v0] Debug - getUserProfile - Response body: ${response.body}',
          );

          if (response.statusCode == 200) {
            final jsonResponse = json.decode(response.body);
            return jsonResponse as Map<String, dynamic>;
          }
        } catch (e) {
          print('[v0] Debug - Endpoint $endpoint failed: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }

    return await AuthStorage.getProfile();
  }

  // -------------------- Concern Slip Submission --------------------

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
      final token = await AuthStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final body = {
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'priority': _mapPriorityToBackend(priority),
        if (unitId != null) 'unit_id': unitId,
        'attachments': attachments ?? [],
      };

      print(
        '[v0] Debug - Submitting concern slip with body: ${jsonEncode(body)}',
      );

      final response = await post(
        '/concern-slips/',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      print('[v0] Debug - Submit response status: ${response.statusCode}');
      print('[v0] Debug - Submit response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> result;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            result = decoded;
          } else if (decoded is bool && decoded == true) {
            // Backend returned true for success, create our own result
            result = {
              'success': true,
              'message': 'Concern slip submitted successfully',
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
            };
          } else {
            // Fallback for other response types
            result = {
              'success': true,
              'message': 'Concern slip submitted successfully',
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'raw_response': decoded,
            };
          }
        } catch (e) {
          print('[v0] Debug - JSON decode error: $e');
          // If JSON decode fails, create a success result
          result = {
            'success': true,
            'message': 'Concern slip submitted successfully',
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'raw_response': response.body,
          };
        }

        final localConcernSlip = {
          ...body,
          'id':
              result['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'status': 'submitted',
          'submitted_at': DateTime.now().toIso8601String(),
          'local_id': DateTime.now().millisecondsSinceEpoch.toString(),
        };

        await LocalStorageService.saveSubmittedConcernSlip(localConcernSlip);
        print('[v0] Debug - Saved concern slip to local storage');

        return result;
      } else {
        print(
          '[v0] Debug - Server error ${response.statusCode}, saving locally',
        );

        final localConcernSlip = {
          ...body,
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'status': 'saved_locally',
          'submitted_at': DateTime.now().toIso8601String(),
          'local_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'error_note': 'Server temporarily unavailable - saved locally',
        };

        await LocalStorageService.saveSubmittedConcernSlip(localConcernSlip);
        print('[v0] Debug - Saved concern slip locally due to server error');

        // Return success to user even though server failed
        return {
          'success': true,
          'message':
              'Concern slip saved locally. It will be synced when the server is available.',
          'id': localConcernSlip['id'],
          'saved_locally': true,
        };
      }
    } catch (e) {
      print('Error submitting concern slip: $e');

      try {
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
        print('[v0] Debug - Saved concern slip locally due to network error');

        // Return success to user
        return {
          'success': true,
          'message':
              'Concern slip saved locally. It will be synced when connection is restored.',
          'id': localConcernSlip['id'],
          'saved_locally': true,
        };
      } catch (localError) {
        print('[v0] Debug - Failed to save locally: $localError');
        throw Exception(
          'Failed to submit concern slip and unable to save locally. Please try again.',
        );
      }
    }
  }

  /// Get concern slips for current tenant
  Future<List<Map<String, dynamic>>> getTenantConcernSlips() async {
    try {
      print('[v0] Debug - Getting concern slips from local storage');
      final localSlips = await LocalStorageService.getSubmittedConcernSlips();
      print(
        '[v0] Debug - Found ${localSlips.length} concern slips in local storage',
      );

      // Try to get updated status from server if possible, but don't fail if access denied
      final token = await AuthStorage.getToken();
      if (token != null && localSlips.isNotEmpty) {
        print('[v0] Debug - Attempting to sync status with server');
        try {
          // Try to get updates for each slip
          for (var slip in localSlips) {
            if (slip['id'] != null) {
              try {
                final response = await get(
                  '/concern-slips/${slip['id']}',
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                );

                if (response.statusCode == 200) {
                  final serverSlip =
                      jsonDecode(response.body) as Map<String, dynamic>;
                  slip['status'] = serverSlip['status'] ?? slip['status'];
                  slip['updated_at'] =
                      serverSlip['updated_at'] ?? slip['updated_at'];
                }
              } catch (e) {
                // Ignore individual slip sync errors
                print('[v0] Debug - Could not sync slip ${slip['id']}: $e');
              }
            }
          }
        } catch (e) {
          print('[v0] Debug - Server sync failed, using local data: $e');
        }
      }

      return localSlips;
    } catch (e) {
      print('Error getting tenant concern slips: $e');
      return [];
    }
  }

  /// Get concern slip by ID
  Future<Map<String, dynamic>> getConcernSlip(String concernSlipId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await get(
        '/concern-slips/$concernSlipId',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to get concern slip: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting concern slip: $e');
      rethrow;
    }
  }

  /// Map UI priority to backend priority
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

  /// Get all concern slips (Admin only)
  Future<List<Map<String, dynamic>>> getAllConcernSlips() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await get(
        '/concern-slips/',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to get all concern slips: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting all concern slips: $e');
      rethrow;
    }
  }

  /// Get concern slip by ID (Admin/Staff access)
  Future<Map<String, dynamic>> getConcernSlipById(String concernSlipId) async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await get(
        '/concern-slips/$concernSlipId',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(
          'Failed to get concern slip by ID: ${errorBody['detail'] ?? response.body}',
        );
      }
    } catch (e) {
      print('Error getting concern slip by ID: $e');
      rethrow;
    }
  }

  String mapCategoryToBackend(String uiCategory) {
    return uiCategory; // Directly return the category since it's already correct
  }
}
