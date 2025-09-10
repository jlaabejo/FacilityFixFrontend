import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

class FacilityFixAPIService {
  final http.Client _client;
  late String baseUrl;
  String? _authToken;

  FacilityFixAPIService({http.Client? client}) : _client = client ?? http.Client() {
    // Set base URL based on platform
    if (kIsWeb) {
      baseUrl = "http://localhost:8000"; // Web
    } else if (Platform.isAndroid) {
      baseUrl = "http://10.0.2.2:8000"; // Android emulator
    } else if (Platform.isIOS) {
      baseUrl = "http://localhost:8000"; // iOS simulator
    } else {
      baseUrl = "http://localhost:8000"; // Desktop/other
    }

    print('[FacilityFix] APIService initialized with baseUrl: $baseUrl');
  }

  // Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
    print('[FacilityFix] Auth token set');
  }

  // Clear authentication token
  void clearAuthToken() {
    _authToken = null;
    print('[FacilityFix] Auth token cleared');
  }

  // Get headers with authentication
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Test connection method
  Future<bool> testConnection() async {
    try {
      print('[FacilityFix] Testing connection to: $baseUrl/');
      final response = await _client
          .get(
            Uri.parse('$baseUrl/'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      print('[FacilityFix] Test connection response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('[FacilityFix] Connection test failed: $e');
      return false;
    }
  }

  // ============================================================================
  // AUTHENTICATION ENDPOINTS
  // ============================================================================

  Future<AuthResponse> exchangeToken(String firebaseToken) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/exchange-token'),
        headers: _headers,
        body: jsonEncode({'firebase_token': firebaseToken}),
      );

      print('[FacilityFix] Exchange token response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final authResponse = AuthResponse.fromJson(data);
        setAuthToken(authResponse.accessToken);
        return authResponse;
      } else {
        throw Exception('Failed to exchange token: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error during token exchange: $e');
      throw Exception('Failed to exchange token: $e');
    }
  }

  Future<UserResponse> registerUser(UserRegistrationRequest request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      print('[FacilityFix] Register user response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserResponse.fromJson(data);
      } else {
        throw Exception('Failed to register user: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error during user registration: $e');
      throw Exception('Failed to register user: $e');
    }
  }

  // ============================================================================
  // REPAIR REQUEST ENDPOINTS
  // ============================================================================

  Future<RepairRequestResponse> submitRepairRequest(RepairRequestSubmission request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/repair-requests/'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      print('[FacilityFix] Submit repair request response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RepairRequestResponse.fromJson(data);
      } else {
        throw Exception('Failed to submit repair request: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error submitting repair request: $e');
      throw Exception('Failed to submit repair request: $e');
    }
  }

  Future<List<RepairRequestResponse>> getUserRepairRequests(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/repair-requests/$userId'),
        headers: _headers,
      );

      print('[FacilityFix] Get user repair requests response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => RepairRequestResponse.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get repair requests: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error getting repair requests: $e');
      throw Exception('Failed to get repair requests: $e');
    }
  }

  Future<List<RepairRequestResponse>> getAllRepairRequests() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/repair-requests/'),
        headers: _headers,
      );

      print('[FacilityFix] Get all repair requests response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => RepairRequestResponse.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get all repair requests: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error getting all repair requests: $e');
      throw Exception('Failed to get all repair requests: $e');
    }
  }

  Future<RepairRequestResponse> updateRepairRequestStatus(
    String requestId, 
    String status, 
    {String? notes}
  ) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (notes != null) body['notes'] = notes;

      final response = await _client.patch(
        Uri.parse('$baseUrl/repair-requests/$requestId/status'),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('[FacilityFix] Update repair request status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return RepairRequestResponse.fromJson(data);
      } else {
        throw Exception('Failed to update repair request status: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error updating repair request status: $e');
      throw Exception('Failed to update repair request status: $e');
    }
  }

  // ============================================================================
  // WORK ORDER ENDPOINTS
  // ============================================================================

  Future<WorkOrderResponse> createWorkOrder(WorkOrderCreation request) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/api/work-orders/'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      print('[FacilityFix] Create work order response: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkOrderResponse.fromJson(data);
      } else {
        throw Exception('Failed to create work order: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error creating work order: $e');
      throw Exception('Failed to create work order: $e');
    }
  }

  Future<List<WorkOrderResponse>> getAssignedWorkOrders(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/api/work-orders/assigned/$userId'),
        headers: _headers,
      );

      print('[FacilityFix] Get assigned work orders response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => WorkOrderResponse.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get assigned work orders: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error getting assigned work orders: $e');
      throw Exception('Failed to get assigned work orders: $e');
    }
  }

  Future<WorkOrderResponse> updateWorkOrderStatus(
    String workOrderId, 
    String status,
    {String? notes}
  ) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (notes != null) body['notes'] = notes;

      final response = await _client.patch(
        Uri.parse('$baseUrl/api/work-orders/$workOrderId/status'),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('[FacilityFix] Update work order status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkOrderResponse.fromJson(data);
      } else {
        throw Exception('Failed to update work order status: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error updating work order status: $e');
      throw Exception('Failed to update work order status: $e');
    }
  }

  // ============================================================================
  // USER MANAGEMENT ENDPOINTS
  // ============================================================================

  Future<List<UserResponse>> getAllUsers() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/'),
        headers: _headers,
      );

      print('[FacilityFix] Get all users response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.map((item) => UserResponse.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get users: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error getting users: $e');
      throw Exception('Failed to get users: $e');
    }
  }

  Future<UserResponse> getUser(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );

      print('[FacilityFix] Get user response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserResponse.fromJson(data);
      } else {
        throw Exception('Failed to get user: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error getting user: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  Future<UserResponse> updateUser(String userId, UserUpdateRequest request) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      print('[FacilityFix] Update user response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserResponse.fromJson(data);
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      print('[FacilityFix] Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  // ============================================================================
  // DATABASE ENDPOINTS
  // ============================================================================

  Future<bool> testDatabaseConnection() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/database/test'),
        headers: _headers,
      );

      print('[FacilityFix] Test database connection response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('[FacilityFix] Database connection test failed: $e');
      return false;
    }
  }

  Future<bool> initializeSampleData() async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/database/init-sample-data'),
        headers: _headers,
      );

      print('[FacilityFix] Initialize sample data response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('[FacilityFix] Error initializing sample data: $e');
      return false;
    }
  }

  // Dispose method to clean up resources
  void dispose() {
    _client.close();
  }
}
