import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import '../../services/api_services.dart' as api_services;

class ApiService {
  // Base URL for the backend API
  // Change this to the backend URL when deployed
  static String get baseUrl => AppEnv.baseUrlWithLan(AppRole.admin);

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  @Deprecated('Use AuthStorage.saveToken() instead. This method now does nothing.')
  void setAuthToken(String token) {
    // No-op - kept for backward compatibility
    // Token is now retrieved dynamically from AuthStorage via _getAuthHeaders()
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await api_services.APIService.requireToken();

    return {
      'Content-Type': 'application/json',
       'Authorization': 'Bearer $token',
    }; 
  }

  // ============================================
  // DASHBOARD ANALYTICS ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/dashboard-stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load dashboard stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWorkOrderTrends({int days = 7}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/work-order-trends?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load work order trends: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching work order trends: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategoryBreakdown() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/category-breakdown'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load category breakdown: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching category breakdown: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getHeatMapData({int days = 30}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/heat-map?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load heat map data: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching heat map data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStaffPerformanceInsights({
    int days = 30,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/staff-performance?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load staff performance insights: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching staff performance insights: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEquipmentInsights({int days = 90}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/equipment-insights?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load equipment insights: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching equipment insights: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getComprehensiveAnalyticsReport({
    int days = 30,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/comprehensive-report?days=$days'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load comprehensive analytics report: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching comprehensive analytics report: $e');
      rethrow;
    }
  }

  /// Export analytics data as CSV
  Future<String> exportAnalyticsCSV({
    required String reportType,
    int days = 30,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/analytics/export/csv?report_type=$reportType&days=$days',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          'Failed to export analytics CSV: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error exporting analytics CSV: $e');
      rethrow;
    }
  }

  /// Export analytics data as JSON
  Future<String> exportAnalyticsJSON({
    required String reportType,
    int days = 30,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/analytics/export/json?report_type=$reportType&days=$days',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          'Failed to export analytics JSON: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error exporting analytics JSON: $e');
      rethrow;
    }
  }

  /// Export analytics data as Excel (enhanced format)
  Future<String> exportAnalyticsExcel({
    required String reportType,
    int days = 30,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/analytics/export/excel?report_type=$reportType&days=$days',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          'Failed to export analytics Excel: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error exporting analytics Excel: $e');
      rethrow;
    }
  }

  /// Export executive dashboard summary
  Future<String> exportDashboardSummary({
    String format = 'csv',
    int days = 30,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/analytics/export/dashboard-summary?format=$format&days=$days',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          'Failed to export dashboard summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error exporting dashboard summary: $e');
      rethrow;
    }
  }

  /// Get time series data for charts
  Future<Map<String, dynamic>> getTimeSeriesData({
    String metric = 'requests',
    int days = 30,
    String interval = 'daily',
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/analytics/time-series?metric=$metric&days=$days&interval=$interval',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load time series data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching time series data: $e');
      rethrow;
    }
  }

  /// Get comparison data between periods
  Future<Map<String, dynamic>> getComparisonData({
    int period1Days = 30,
    int period2Days = 30,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse(
          '$baseUrl/analytics/comparison?period1_days=$period1Days&period2_days=$period2Days',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load comparison data: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching comparison data: $e');
      rethrow;
    }
  }

  /// Get predictive insights
  Future<Map<String, dynamic>> getPredictiveInsights() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/predictive-insights'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load predictive insights: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching predictive insights: $e');
      rethrow;
    }
  }

  // ============================================
  // STAFF MANAGEMENT ENDPOINTS
  // ============================================

  Future<List<dynamic>> getStaffMembers({
    String? department,
    bool availableOnly = false,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (department != null) queryParams['department'] = department;
      if (availableOnly) queryParams['available_only'] = 'true';

      final uri = Uri.parse(
        '$baseUrl/users/staff',
      ).replace(queryParameters: queryParams);
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception('Failed to load staff members: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching staff members: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> assignStaffToConcernSlip(
    String concernSlipId,
    String staffUserId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/concern-slips/$concernSlipId/assign-staff'),
        headers: headers,
        body: json.encode({'assigned_to': staffUserId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to assign staff to concern slip: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error assigning staff to concern slip: $e');
      rethrow;
    }
  }

  /// Assign staff to a job service
  Future<Map<String, dynamic>> assignStaffToJobService(
    String jobServiceId,
    String staffUserId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/job-services/$jobServiceId/assign'),
        headers: headers,
        body: json.encode({'assigned_to': staffUserId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to assign staff to job service: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error assigning staff to job service: $e');
      rethrow;
    }
  }

  /// Assign staff to a work order or maintenance task
  Future<Map<String, dynamic>> assignStaffToWorkOrder(
    String workOrderId,
    String staffUserId, {
    String? note,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = <String, dynamic>{
        'assigned_to': staffUserId,
      };
      if (note != null && note.isNotEmpty) {
        body['note'] = note;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/work-orders/$workOrderId/assign'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to assign staff to work order: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error assigning staff to work order: $e');
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
      final body = <String, dynamic>{
        'resolution_type': resolutionType,
      };
      if (adminNotes != null && adminNotes.isNotEmpty) {
        body['admin_notes'] = adminNotes;
      }

      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/concern-slips/$concernSlipId/set-resolution-type'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['detail'] ?? 'Failed to set resolution type: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error setting resolution type: $e');
      rethrow;
    }
  }

  // ============================================
  // CONCERN SLIPS ENDPOINTS
  // ============================================

  Future<List<dynamic>> getAllConcernSlips() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/concern-slips/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception('Failed to load concern slips: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching concern slips: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPendingConcernSlips() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/concern-slips/pending/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception(
          'Failed to load pending concern slips: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching pending concern slips: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getConcernSlipsByStatus(String status) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/concern-slips/status/$status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception(
          'Failed to load concern slips by status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching concern slips by status: $e');
      rethrow;
    }
  }

  /// Get a specific concern slip by ID
  Future<Map<String, dynamic>> getConcernSlip(String concernSlipId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/concern-slips/$concernSlipId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load concern slip: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching concern slip: $e');
      rethrow;
    }
  }

  // ============================================
  // JOB SERVICES ENDPOINTS
  // ============================================

  Future<List<dynamic>> getAllJobServices() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/job-services/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception('Failed to load job services: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching job services: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getJobServicesByStatus(String status) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/job-services/status/$status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception(
          'Failed to load job services by status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching job services by status: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getJobService(String jobServiceId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/job-services/$jobServiceId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load job service: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching job service: $e');
      rethrow;
    }
  }

  // ============================================
  // WORK ORDER PERMITS ENDPOINTS
  // ============================================

  Future<List<dynamic>> getAllWorkOrderPermits() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/work-order-permits/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception(
          'Failed to load work order permits: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching work order permits: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getWorkOrderPermitsByStatus(String status) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/work-order-permits/status/$status'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception(
          'Failed to load work order permits by status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching work order permits by status: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getPendingWorkOrderPermits() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/work-order-permits/pending/all'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception(
          'Failed to load pending work order permits: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching pending work order permits: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWorkOrderPermit(String permitId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/work-order-permits/$permitId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load work order permit: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching work order permit: $e');
      rethrow;
    }
  }

  /// Approve a work order permit (Admin only)
  Future<Map<String, dynamic>> approveWorkOrderPermit(
    String permitId, {
    String? conditions,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode({
        if (conditions != null) 'conditions': conditions,
      });
      
      final response = await http.patch(
        Uri.parse('$baseUrl/work-order-permits/$permitId/approve'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to approve work order permit: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error approving work order permit: $e');
      rethrow;
    }
  }

  /// Deny a work order permit (Admin only)
  Future<Map<String, dynamic>> denyWorkOrderPermit(
    String permitId,
    String reason,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode({
        'reason': reason,
      });
      
      final response = await http.patch(
        Uri.parse('$baseUrl/work-order-permits/$permitId/deny'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to deny work order permit: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error denying work order permit: $e');
      rethrow;
    }
  }

  /// Mark a work order permit as completed
  Future<Map<String, dynamic>> completeWorkOrderPermit(
    String permitId, {
    String? completionNotes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = json.encode({
        if (completionNotes != null) 'completion_notes': completionNotes,
      });
      
      final response = await http.patch(
        Uri.parse('$baseUrl/work-order-permits/$permitId/complete'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to complete work order permit: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error completing work order permit: $e');
      rethrow;
    }
  }

  // ============================================
  // MAINTENANCE CALENDAR ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> getMaintenanceTasks({
    String? buildingId,
    String? status,
    String? assignedTo,
    String? category,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, String>{
        if (buildingId != null) 'building_id': buildingId,
        if (status != null) 'status': status,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (category != null) 'category': category,
        if (dateFrom != null) 'date_from': dateFrom.toIso8601String(),
        if (dateTo != null) 'date_to': dateTo.toIso8601String(),
      };

      final baseUri = Uri.parse('$baseUrl/maintenance/');
      final uri = queryParams.isEmpty
          ? baseUri
          : baseUri.replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return {
            'success': true,
            'tasks': decoded,
            'count': decoded.length,
          };
        }
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw Exception('Unexpected maintenance tasks response format');
      } else {
        throw Exception(
          'Failed to load maintenance tasks: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching maintenance tasks: $e');
      rethrow;
    }
  }

  /// Get a specific maintenance task by task ID
  Future<Map<String, dynamic>> getMaintenanceTaskById(String taskId) async {
    try {
      print('[v0] Fetching maintenance task: $taskId');

      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance/$taskId'),
        headers: headers,
      );

      print('[v0] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load maintenance task: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching maintenance task by ID: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMaintenanceTask(
    Map<String, dynamic> taskData,
  ) async {
    try {
      print('[v0] Creating maintenance task: ${json.encode(taskData)}');

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/maintenance/'),
        headers: headers,
        body: json.encode(taskData),
      );

      print('[v0] Response status: ${response.statusCode}');
      print('[v0] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to create maintenance task: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error creating maintenance task: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMaintenanceTask(
    String taskId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/maintenance/$taskId'),
        headers: headers,
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to update maintenance task: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error updating maintenance task: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteMaintenanceTask(String taskId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/maintenance/$taskId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to delete maintenance task: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error deleting maintenance task: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMaintenanceTaskChecklist(
    String taskId,
    List<Map<String, dynamic>> checklistCompleted,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/maintenance/$taskId/checklist'),
        headers: headers,
        body: json.encode({
          'checklist_completed': checklistCompleted,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to update maintenance task checklist: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error updating maintenance task checklist: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> assignStaffToMaintenanceTask(
    String taskId,
    String staffId, {
    DateTime? scheduledDate,
    String? notes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'staff_id': staffId,
        if (scheduledDate != null) 'scheduled_date': scheduledDate.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/maintenance/$taskId/assign'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to assign staff to maintenance task: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error assigning staff to maintenance task: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> assignStaffToChecklistItem(
    String taskId,
    String itemId,
    String staffId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final body = {
        'staff_id': staffId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/maintenance/$taskId/checklist/$itemId/assign'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to assign staff to checklist item: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error assigning staff to checklist item: $e');
      rethrow;
    }
  }

  // ============================================
  // SPECIAL MAINTENANCE TASKS ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> initializeSpecialMaintenanceTasks() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/maintenance/special/initialize'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to initialize special maintenance tasks: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error initializing special maintenance tasks: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSpecialMaintenanceTasks() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance/special'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load special maintenance tasks: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching special maintenance tasks: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSpecialMaintenanceTasksSummary() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance/special/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load special maintenance tasks summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching special maintenance tasks summary: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSpecialMaintenanceTask(String taskKey) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance/special/$taskKey'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load special maintenance task: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching special maintenance task: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resetSpecialMaintenanceTask(String taskKey) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/maintenance/special/$taskKey/reset'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to reset special maintenance task: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error resetting special maintenance task: $e');
      rethrow;
    }
  }

  /// Assign a checklist item in a special maintenance task to a staff member
  Future<Map<String, dynamic>> assignSpecialMaintenanceChecklistItem({
    required String taskKey,
    required String itemId,
    required String staffId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final taskId = 'SPECIAL-${taskKey.toUpperCase()}-001';

      final response = await http.post(
        Uri.parse('$baseUrl/maintenance/$taskId/checklist/$itemId/assign'),
        headers: headers,
        body: json.encode({
          'staff_id': staffId,
          'assigned_to': staffId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to assign checklist item: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error assigning special maintenance checklist item: $e');
      rethrow;
    }
  }

  /// Update a single checklist item completion status in a special maintenance task
  Future<Map<String, dynamic>> updateSpecialMaintenanceChecklistItem({
    required String taskKey,
    required String itemId,
    required bool completed,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final taskId = 'SPECIAL-${taskKey.toUpperCase()}-001';

      final response = await http.patch(
        Uri.parse('$baseUrl/maintenance/$taskId/checklist/$itemId'),
        headers: headers,
        body: json.encode({
          'item_id': itemId,
          'completed': completed,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to update checklist item: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error updating special maintenance checklist item: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCalendarSummary({
    required String buildingId,
    String period = 'week',
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/maintenance-calendar/calendar/summary',
      ).replace(queryParameters: {'building_id': buildingId, 'period': period});

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load calendar summary: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching calendar summary: $e');
      rethrow;
    }
  }

  /// Get the next sequential IPM code for Internal Preventive Maintenance
  Future<String> getNextIPMCode() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance-calendar/next-ipm-code'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['code'] as String;
      } else {
        throw Exception('Failed to get next IPM code: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching next IPM code: $e');
      rethrow;
    }
  }

  /// Get the next sequential EPM code for External Preventive Maintenance
  Future<String> getNextEPMCode() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance-calendar/next-epm-code'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['code'] as String;
      } else {
        throw Exception('Failed to get next EPM code: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching next EPM code: $e');
      rethrow;
    }
  }

  /// Get the next sequential maintenance code for any maintenance type
  /// [maintenanceType] should be 'IPM', 'EPM', or other supported types
  Future<String> getNextMaintenanceCode(String maintenanceType) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/maintenance-calendar/next-code/$maintenanceType'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['code'] as String;
      } else {
        throw Exception(
          'Failed to get next $maintenanceType code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching next $maintenanceType code: $e');
      rethrow;
    }
  }

  // ============================================
  // AUTHENTICATION ENDPOINTS
  // ============================================

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['access_token'] != null) {
          setAuthToken(data['access_token']);
        }
        return data;
      } else {
        throw Exception('Login failed: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error during login: $e');
      rethrow;
    }
  }

  // ============================================
  // HEALTH CHECK
  // ============================================

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Health check failed: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error during health check: $e');
      rethrow;
    }
  }

  // ============================================
  // USER MANAGEMENT ENDPOINTS
  // ============================================

  /// Get all users with optional filters
  Future<List<dynamic>> getUsers({
    String? role,
    String? buildingId,
    String? status,
    String? department,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (role != null) queryParams['role'] = role;
      if (buildingId != null) queryParams['building_id'] = buildingId;
      if (status != null) queryParams['status'] = status;
      if (department != null) queryParams['department'] = department;
      queryParams['limit'] = limit.toString();

      final uri = Uri.parse(
        '$baseUrl/users/',
      ).replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching users: $e');
      rethrow;
    }
  }

  /// Get a specific user by user_id (e.g., T-0001, S-0001, A-0001)
  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching user: $e');
      rethrow;
    }
  }

  /// Update user information
  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final url = '$baseUrl/users/$userId';
      final body = json.encode(updateData);
      
      print('[ApiService] PUT $url');
      print('[ApiService] Headers: $headers');
      print('[ApiService] Body: $body');
      
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      print('[ApiService] Response status: ${response.statusCode}');
      print('[ApiService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : 'No error details';
        throw Exception('Failed to update user: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      print('[ApiService] Error updating user: $e');
      rethrow;
    }
  }

  /// Update user status (active, suspended, inactive)
  Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    String status,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/status'),
        headers: headers,
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update user status: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error updating user status: $e');
      rethrow;
    }
  }

  /// Delete or deactivate a user
  Future<Map<String, dynamic>> deleteUser(
    String userId, {
    bool permanent = false,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/users/$userId',
      ).replace(queryParameters: {'permanent': permanent.toString()});

      final headers = await _getAuthHeaders();
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error deleting user: $e');
      rethrow;
    }
  }

  /// Bulk update user status
  Future<Map<String, dynamic>> bulkUpdateUserStatus(
    List<String> userIds,
    String newStatus,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/bulk/status'),
        headers: headers,
        body: json.encode({'user_ids': userIds, 'new_status': newStatus}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to bulk update users: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error in bulk update: $e');
      rethrow;
    }
  }

  // ============================================
  // INVENTORY MANAGEMENT ENDPOINTS
  // ============================================

  /// Create a new inventory item
  Future<Map<String, dynamic>> createInventoryItem(
    Map<String, dynamic> itemData,
  ) async {
    try {
      final backendData = {
        'building_id': itemData['building_id'],
        'item_name': itemData['item_name'],
        'item_code': itemData['item_code'],
        'classification': itemData['classification'],
        'department': itemData['department'],
        'brand_name': itemData['brand_name'],
        'current_stock': itemData['current_stock'],
        'reorder_level': itemData['reorder_level'],
        'unit_of_measure': itemData['unit'], // Map 'unit' to 'unit_of_measure'
        'is_critical': itemData['is_critical'] ?? false,
        'supplier_name':
            itemData['supplier'], // Map 'supplier' to 'supplier_name'
        'description': itemData['description'],
        'recommended_on': itemData['recommended_on'] ?? [], // Include recommended locations
        if (itemData['warranty_until'] != null)
          'warranty_until': itemData['warranty_until'],
      };

      print('[v0] Sending inventory item data: ${json.encode(backendData)}');

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/items'),
        headers: headers,
        body: json.encode(backendData),
      );

      print('[v0] Response status: ${response.statusCode}');
      print('[v0] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to create inventory item: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error creating inventory item: $e');
      rethrow;
    }
  }

  /// Get all inventory items for a building
  Future<Map<String, dynamic>> getInventoryItems({
    required String buildingId,
    bool includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (includeInactive) queryParams['include_inactive'] = 'true';

      final uri = Uri.parse(
        '$baseUrl/inventory/buildings/$buildingId/items',
      ).replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns {success: true, data: [...], count: n}
        return data;
      } else {
        throw Exception(
          'Failed to load inventory items: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching inventory items: $e');
      rethrow;
    }
  }

  /// Get a specific inventory item by ID
  Future<Map<String, dynamic>> getInventoryItem(String itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/inventory/items/$itemId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load inventory item: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching inventory item: $e');
      rethrow;
    }
  }

  /// Update an inventory item
  Future<Map<String, dynamic>> updateInventoryItem(
    String itemId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      // Map frontend fields to backend fields
      final backendData = <String, dynamic>{};

      if (updateData.containsKey('item_name')) {
        backendData['item_name'] = updateData['item_name'];
      }
      if (updateData.containsKey('item_code')) {
        backendData['item_code'] = updateData['item_code'];
      }
      if (updateData.containsKey('classification')) {
        backendData['classification'] = updateData['classification'];
      }
      if (updateData.containsKey('department')) {
        backendData['department'] = updateData['department'];
      }
      if (updateData.containsKey('brand_name')) {
        backendData['brand_name'] = updateData['brand_name'];
      }
      if (updateData.containsKey('current_stock')) {
        backendData['current_stock'] = updateData['current_stock'];
      }
      if (updateData.containsKey('reorder_level')) {
        backendData['reorder_level'] = updateData['reorder_level'];
      }
      if (updateData.containsKey('unit')) {
        backendData['unit_of_measure'] = updateData['unit'];
      }
      if (updateData.containsKey('is_critical')) {
        backendData['is_critical'] = updateData['is_critical'];
      }
      if (updateData.containsKey('supplier')) {
        backendData['supplier_name'] = updateData['supplier'];
      }
      if (updateData.containsKey('warranty_until')) {
        backendData['warranty_until'] = updateData['warranty_until'];
      }

      print(
        '[v0] Updating inventory item $itemId: ${json.encode(backendData)}',
      );

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/inventory/items/$itemId'),
        headers: headers,
        body: json.encode(backendData),
      );

      print('[v0] Response status: ${response.statusCode}');
      print('[v0] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to update inventory item: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error updating inventory item: $e');
      rethrow;
    }
  }

  /// Delete an inventory item
  Future<Map<String, dynamic>> deleteInventoryItem(String itemId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/inventory/items/$itemId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to delete inventory item: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error deleting inventory item: $e');
      rethrow;
    }
  }

  /// Get low stock items for a building
  Future<Map<String, dynamic>> getLowStockItems({
    required String buildingId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/inventory/buildings/$buildingId/low-stock'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to load low stock items: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching low stock items: $e');
      rethrow;
    }
  }

  /// Restock inventory item (add stock)
  Future<Map<String, dynamic>> restockInventoryItem(
    String itemId,
    int quantity, {
    String? reason,
    double? costPerUnit,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'quantity': quantity.toString(),
      };

      if (reason != null) queryParams['reason'] = reason;
      if (costPerUnit != null) queryParams['cost_per_unit'] = costPerUnit.toString();

      final uri = Uri.parse(
        '$baseUrl/inventory/items/$itemId/restock',
      ).replace(queryParameters: queryParams);

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'detail': errorBody['detail'] ?? 'Failed to restock item',
        };
      }
    } catch (e) {
      print('[v0] Error restocking inventory item: $e');
      return {
        'success': false,
        'detail': 'Error: ${e.toString()}',
      };
    }
  }

  /// Consume inventory stock (remove stock)
  Future<Map<String, dynamic>> consumeInventoryStock(
    String itemId,
    int quantity, {
    String? reason,
    String? referenceType,
    String? referenceId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'quantity': quantity.toString(),
      };

      if (reason != null) queryParams['reason'] = reason;
      if (referenceType != null) queryParams['reference_type'] = referenceType;
      if (referenceId != null) queryParams['reference_id'] = referenceId;

      final uri = Uri.parse(
        '$baseUrl/inventory/items/$itemId/consume',
      ).replace(queryParameters: queryParams);

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        return {
          'success': false,
          'detail': errorBody['detail'] ?? 'Failed to consume stock',
        };
      }
    } catch (e) {
      print('[v0] Error consuming inventory stock: $e');
      return {
        'success': false,
        'detail': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get inventory transactions for an item
  Future<Map<String, dynamic>> getInventoryTransactions(
    String itemId, {
    String? transactionType,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{
        'inventory_id': itemId,
      };

      if (transactionType != null) {
        queryParams['transaction_type'] = transactionType;
      }

      final uri = Uri.parse(
        '$baseUrl/inventory/transactions',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {'success': true, 'data': data};
        }
      } else {
        throw Exception(
          'Failed to load transactions: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching inventory transactions: $e');
      return {
        'success': false,
        'data': [],
        'detail': 'Error: ${e.toString()}',
      };
    }
  }

  /// Get all inventory requests
  Future<Map<String, dynamic>> getInventoryRequests({
    String? buildingId,
    String? status,
    String? requestedBy,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (buildingId != null) queryParams['building_id'] = buildingId;
      if (status != null) queryParams['status'] = status;
      if (requestedBy != null) queryParams['requested_by'] = requestedBy;

      final uri = Uri.parse(
        '$baseUrl/inventory/requests',
      ).replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          return {'success': true, 'data': data};
        }
      } else {
        throw Exception(
          'Failed to load inventory requests: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching inventory requests: $e');
      rethrow;
    }
  }

  /// Approve an inventory request
  Future<Map<String, dynamic>> approveInventoryRequest(
    String requestId, {
    int? quantityApproved,
    String? adminNotes,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (quantityApproved != null) {
        queryParams['quantity_approved'] = quantityApproved.toString();
      }
      if (adminNotes != null) {
        queryParams['admin_notes'] = adminNotes;
      }

      final uri = Uri.parse(
        '$baseUrl/inventory/requests/$requestId/approve',
      ).replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to approve inventory request: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error approving inventory request: $e');
      rethrow;
    }
  }

  /// Deny an inventory request
  Future<Map<String, dynamic>> denyInventoryRequest(
    String requestId,
    String adminNotes,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/inventory/requests/$requestId/deny',
      ).replace(queryParameters: {'admin_notes': adminNotes});

      final headers = await _getAuthHeaders();
      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to deny inventory request: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error denying inventory request: $e');
      rethrow;
    }
  }

  /// Fulfill an approved inventory request
  Future<Map<String, dynamic>> fulfillInventoryRequest(String requestId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/inventory/requests/$requestId/fulfill'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to fulfill inventory request: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fulfilling inventory request: $e');
      rethrow;
    }
  }

  /// Get inventory requests linked to a maintenance task
  Future<Map<String, dynamic>> getInventoryRequestsByMaintenanceTask(
    String maintenanceTaskId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/inventory/maintenance-task/$maintenanceTaskId/requests'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load inventory requests for maintenance task: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching inventory requests for maintenance task: $e');
      rethrow;
    }
  }

  // ============================================
  // ANNOUNCEMENT ENDPOINTS
  // ============================================

  /// Get all announcements for a building with advanced filtering
  Future<Map<String, dynamic>> getAnnouncements({
    required String buildingId,
    String audience = 'all',
    bool activeOnly = true,
    int limit = 50,
    String? announcementType,
    String? priorityLevel,
    String? tags,
    bool publishedOnly = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'building_id': buildingId,
        'audience': audience,
        'active_only': activeOnly.toString(),
        'limit': limit.toString(),
        'published_only': publishedOnly.toString(),
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

      final uri = Uri.parse(
        '$baseUrl/announcements/',
      ).replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      print('[API] Request headers: ${headers.keys.join(", ")}');
      print('[API] Request URL: $uri');
      
      final response = await http.get(uri, headers: headers);

      print('[API] Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('[API] Error response body: ${response.body}');
        throw Exception('Failed to load announcements: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('[v0] Error fetching announcements: $e');
      rethrow;
    }
  }

  /// Get a specific announcement by ID
  Future<Map<String, dynamic>> getAnnouncement(String announcementId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/$announcementId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load announcement: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching announcement: $e');
      rethrow;
    }
  }

  /// Create a new announcement
  Future<Map<String, dynamic>> createAnnouncement(
    Map<String, dynamic> announcementData,
  ) async {
    try {
      print('[v0] Creating announcement: ${json.encode(announcementData)}');

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/announcements/'),
        headers: headers,
        body: json.encode(announcementData),
      );

      print('[v0] Response status: ${response.statusCode}');
      print('[v0] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to create announcement: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error creating announcement: $e');
      rethrow;
    }
  }

  /// Update an announcement
  Future<Map<String, dynamic>> updateAnnouncement(
    String announcementId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      print(
        '[v0] Updating announcement $announcementId: ${json.encode(updateData)}',
      );

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/announcements/$announcementId'),
        headers: headers,
        body: json.encode(updateData),
      );

      print('[v0] Response status: ${response.statusCode}');
      print('[v0] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to update announcement: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error updating announcement: $e');
      rethrow;
    }
  }

  /// Delete (deactivate) an announcement
  Future<Map<String, dynamic>> deleteAnnouncement(
    String announcementId, {
    bool notifyDeactivation = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/announcements/$announcementId').replace(
        queryParameters: {'notify_deactivation': notifyDeactivation.toString()},
      );

      final headers = await _getAuthHeaders();
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to delete announcement: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error deleting announcement: $e');
      rethrow;
    }
  }

  /// Get announcement statistics for a building
  Future<Map<String, dynamic>> getAnnouncementStatistics(
    String buildingId,
  ) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/building/$buildingId/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load announcement statistics: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching announcement statistics: $e');
      rethrow;
    }
  }

  /// Get available announcement types and audiences
  Future<Map<String, dynamic>> getAnnouncementTypes() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/announcements/types/available'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load announcement types: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching announcement types: $e');
      rethrow;
    }
  }

  /// Get user-targeted announcements
  Future<Map<String, dynamic>> getUserTargetedAnnouncements({
    required String buildingId,
    bool activeOnly = true,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'building_id': buildingId,
        'active_only': activeOnly.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/announcements/user/targeted',
      ).replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load targeted announcements: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching targeted announcements: $e');
      rethrow;
    }
  }

  /// Mark announcement as viewed
  Future<Map<String, dynamic>> markAnnouncementViewed(String announcementId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/announcements/$announcementId/view'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to mark announcement as viewed: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error marking announcement as viewed: $e');
      rethrow;
    }
  }

  /// Publish scheduled announcements (Admin only)
  Future<Map<String, dynamic>> publishScheduledAnnouncements() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/announcements/publish-scheduled'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to publish scheduled announcements: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error publishing scheduled announcements: $e');
      rethrow;
    }
  }

  /// Expire old announcements (Admin only)
  Future<Map<String, dynamic>> expireOldAnnouncements() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/announcements/expire-old'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to expire announcements: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error expiring announcements: $e');
      rethrow;
    }
  }

  // ============================================
  // NOTIFICATION ENDPOINTS
  // ============================================

  /// Get notifications for the current user
  Future<dynamic> getNotifications({
    bool unreadOnly = false,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, String>{
        'unread_only': unreadOnly.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/notifications/',
      ).replace(queryParameters: queryParams);

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching notifications: $e');
      rethrow;
    }
  }

  /// Mark notifications as read
  Future<Map<String, dynamic>> markNotificationsAsRead(
    List<String> notificationIds,
  ) async {
    try {
      print('[v0] Marking notifications as read: $notificationIds');

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/mark-read'),
        headers: headers,
        body: json.encode({'notification_ids': notificationIds}),
      );

      print('[v0] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to mark notifications as read: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error marking notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      print('[v0] Deleting notification: $notificationId');

      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: headers,
      );

      print('[v0] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to delete notification: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error deleting notification: $e');
      rethrow;
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend returns {"unread_count": count}
        final count = data['unread_count'];
        if (count is int) {
          return count;
        } else if (count is String) {
          return int.tryParse(count) ?? 0;
        } else {
          return 0;
        }
      } else {
        throw Exception(
          'Failed to get unread notification count: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching unread notification count: $e');
      return 0; // Return 0 on error instead of throwing
    }
  }

  // ============================================
  // BUILDING MANAGEMENT ENDPOINTS
  // ============================================

  /// Get all buildings
  Future<List<dynamic>> getAllBuildings() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/buildings/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      } else {
        throw Exception('Failed to load buildings: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching buildings: $e');
      rethrow;
    }
  }

  /// Get a specific building by ID
  Future<Map<String, dynamic>> getBuilding(String buildingId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/buildings/$buildingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load building: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error fetching building: $e');
      rethrow;
    }
  }

  /// Create a new building
  Future<Map<String, dynamic>> createBuilding(
    Map<String, dynamic> buildingData,
  ) async {
    try {
      print('[v0] Creating building: ${json.encode(buildingData)}');

      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/buildings/'),
        headers: headers,
        body: json.encode(buildingData),
      );

      print('[v0] Response status: ${response.statusCode}');
      print('[v0] Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to create building: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error creating building: $e');
      rethrow;
    }
  }

  /// Update a building
  Future<Map<String, dynamic>> updateBuilding(
    String buildingId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      print('[v0] Updating building $buildingId: ${json.encode(updateData)}');

      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/buildings/$buildingId'),
        headers: headers,
        body: json.encode(updateData),
      );

      print('[v0] Response status: ${response.statusCode}');
      print('[v0] Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to update building: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      print('[v0] Error updating building: $e');
      rethrow;
    }
  }

  /// Delete a building
  Future<Map<String, dynamic>> deleteBuilding(String buildingId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/buildings/$buildingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to delete building: ${response.statusCode}');
      }
    } catch (e) {
      print('[v0] Error deleting building: $e');
      rethrow;
    }
  }

  /// Get building statistics
  Future<Map<String, dynamic>> getBuildingStatistics(String buildingId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/buildings/$buildingId/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load building statistics: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('[v0] Error fetching building statistics: $e');
      rethrow;
    }
  }
}
