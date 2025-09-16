import 'dart:convert';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:http/http.dart' as http;
import 'package:facilityfix/config/env.dart';

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
        final r = await http
            .get(_u(p))
            .timeout(const Duration(seconds: 4));
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
    required String role,           // 'admin' | 'staff' | 'tenant'
    required String email,
    required String userId,
    required String password,
    String? staffDepartment,        // staff only
    String? buildingUnitId,         // tenant only
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
      final token = await AuthStorage.getToken();
      if (token == null) return null;
      
      final response = await get(
        '/user/profile',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }
}

// /// Update user profile
// Future<Map<String, dynamic>> updateProfile({
//   required String token,
//   String? firstName,
//   String? lastName,
//   String? email,
//   String? phoneNumber,
//   String? birthDate,
//   String? department,
// }) async {
//   final body = {
//     if (firstName != null) 'first_name': firstName,
//     if (lastName != null) 'last_name': lastName,
//     if (email != null) 'email': email,
//     if (phoneNumber != null) 'phone_number': phoneNumber,
//     if (birthDate != null) 'birthdate': birthDate,
//     if (department != null) 'department': department,
//   };

//   try {
//     final response = await put(
//       '/user/profile', // Adjust this endpoint based on your API
//       headers: {
//         'Authorization': 'Bearer $token',
//         'Content-Type': 'application/json',
//       },
//       body: jsonEncode(body),
//     );

//     if (response.statusCode >= 200 && response.statusCode < 300) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     } else {
//       throw Exception('Failed to update profile: ${response.statusCode} ${response.body}');
//     }
//   } catch (e) {
//     throw Exception('Profile update failed: $e');
//   }
// }