import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import '../layout/facilityfix_layout.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';

class AdminWebAnalyticsPage extends StatefulWidget {
  const AdminWebAnalyticsPage({super.key});

  @override
  State<AdminWebAnalyticsPage> createState() => _AdminWebAnalyticsPageState();
}

class _AdminWebAnalyticsPageState extends State<AdminWebAnalyticsPage> {
  // ============================================
  // STATE VARIABLES FOR FILTERS AND DATA
  // ============================================
  String selectedDateRange = 'This Week';
  String selectedStatus = 'All';
  String selectedDowntimeUnit = 'This Month';

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  // Real data from backend
  Map<String, dynamic>? _dashboardStats;
  Map<String, dynamic>? _categoryBreakdown;
  Map<String, dynamic>? _heatMapData;
  Map<String, dynamic>? _workOrderTrends;
  Map<String, dynamic>? _timeSeriesData;
  Map<String, dynamic>? _staffPerformance;
  Map<String, dynamic>? _equipmentInsights;

  // Computed statistics
  int _totalRequests = 0;
  int _openIssues = 0;
  int _resolvedToday = 0;
  double _resolutionTime = 0.0;
  Map<String, int> _categoryData = {};
  Map<String, List<HeatMapData>> _buildingHeatMap = {};
  List<Map<String, dynamic>> _trendChartData = [];

  // Comparison metrics
  double _totalRequestsChange = 0.0;
  bool _totalRequestsIncreasing = true;
  double _openIssuesChange = 0.0;
  bool _openIssuesIncreasing = true;
  double _resolvedTodayChange = 0.0;
  bool _resolvedTodayIncreasing = true;
  double _resolutionTimeChange = 0.0;
  bool _resolutionTimeImproving = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Check if user has a valid token in AuthStorage
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // Token exists, API service will use it automatically via _getAuthHeaders()
        await _fetchAnalyticsData();
      } else {
        setState(() {
          _errorMessage = 'Authentication token not available. Please log in.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[v0] Error initializing auth: $e');
      setState(() {
        _errorMessage = 'Authentication error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[v0] Fetching analytics data...');

      // Fetch data in parallel
      final results = await Future.wait([
        _apiService.getDashboardStats(),
        _apiService.getCategoryBreakdown(),
        _apiService.getHeatMapData(days: _getDaysFromDateRange()),
        _apiService.getWorkOrderTrends(days: _getDaysFromDateRange()),
        _apiService.getTimeSeriesData(days: _getDaysFromDateRange()),
        _apiService.getStaffPerformanceInsights(days: _getDaysFromDateRange()),
        _apiService.getEquipmentInsights(days: _getDaysFromDateRange()),
      ]);

      _dashboardStats = results[0];
      _categoryBreakdown = results[1];
      _heatMapData = results[2];
      _workOrderTrends = results[3];
      _timeSeriesData = results[4];
      _staffPerformance = results[5];
      _equipmentInsights = results[6];

      print('[v0] Dashboard stats: $_dashboardStats');
      print('[v0] Category breakdown: $_categoryBreakdown');
      print('[v0] Heat map data: $_heatMapData');
      print('[v0] Time series data: $_timeSeriesData');

      // Process the data
      _processAnalyticsData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('[v0] Error fetching analytics data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load analytics data: ${e.toString()}';
      });
    }
  }

  int _getDaysFromDateRange() {
    switch (selectedDateRange) {
      case 'This Week':
        return 7;
      case 'This Month':
        return 30;
      case 'Last Month':
        return 30;
      case 'Last 3 Months':
        return 90;
      default:
        return 30;
    }
  }

  void _processAnalyticsData() {
    // Process dashboard stats
    if (_dashboardStats != null) {
      // Extract from overall_metrics which contains aggregated data
      final overallMetrics = _dashboardStats!['overall_metrics'] as Map<String, dynamic>?;
      if (overallMetrics != null) {
        _totalRequests = overallMetrics['total_requests'] ?? 0;
        _openIssues = overallMetrics['pending_items'] ?? 0;
        _resolvedToday = overallMetrics['completed_today'] ?? 0;
        _resolutionTime = (overallMetrics['average_resolution_time_days'] ?? 0.0).toDouble();

        // Extract comparison metrics if available
        final comparisons = overallMetrics['comparisons'] as Map<String, dynamic>?;
        if (comparisons != null) {
          _totalRequestsChange = (comparisons['total_requests_change'] ?? 0.0).toDouble();
          _totalRequestsIncreasing = comparisons['total_requests_increasing'] ?? true;
          _openIssuesChange = (comparisons['pending_items_change'] ?? 0.0).toDouble();
          _openIssuesIncreasing = comparisons['pending_items_increasing'] ?? true;
          _resolvedTodayChange = (comparisons['completed_today_change'] ?? 0.0).toDouble();
          _resolvedTodayIncreasing = comparisons['completed_today_increasing'] ?? true;
          _resolutionTimeChange = (comparisons['resolution_time_change'] ?? 0.0).toDouble();
          _resolutionTimeImproving = comparisons['resolution_time_improving'] ?? true;
        }
      } else {
        // Fallback: try to get from concern_slips directly
        final concernSlips = _dashboardStats!['concern_slips'] as Map<String, dynamic>?;
        _totalRequests = concernSlips?['total_requests'] ?? 0;
        _openIssues = concernSlips?['pending_concerns'] ?? 0;
        _resolvedToday = 0;
        _resolutionTime = 0.0;
      }
    }

    // Process category breakdown
    if (_categoryBreakdown != null) {
      // Try to get from combined_overview first (aggregated data)
      final combinedOverview = _categoryBreakdown!['combined_overview'] as Map<String, dynamic>?;
      if (combinedOverview != null) {
        final categories = combinedOverview['categories'] as Map<String, dynamic>?;
        if (categories != null) {
          _categoryData = categories.map(
            (key, value) => MapEntry(key, value as int),
          );
        }
      } else {
        // Fallback: try concern_slips categories
        final concernSlips = _categoryBreakdown!['concern_slips'] as Map<String, dynamic>?;
        if (concernSlips != null) {
          final categories = concernSlips['categories'] as Map<String, dynamic>?;
          if (categories != null) {
            _categoryData = categories.map(
              (key, value) => MapEntry(key, value as int),
            );
          }
        }
      }
    }

    // Process heat map data
    if (_heatMapData != null) {
      _buildingHeatMap = _processHeatMapData(_heatMapData!);
    }

    // Process time series data for trend charts
    if (_timeSeriesData != null) {
      final dataPoints = _timeSeriesData!['data_points'] as List<dynamic>?;
      if (dataPoints != null) {
        _trendChartData = dataPoints.map((point) {
          return {
            'date': point['date'] as String,
            'value': (point['value'] as num).toDouble(),
          };
        }).toList();
      }
    }
  }

  Map<String, List<HeatMapData>> _processHeatMapData(
    Map<String, dynamic> heatMapData,
  ) {
    final Map<String, List<HeatMapData>> result = {};

    final heatMapMatrix = heatMapData['heat_map_matrix'] as List<dynamic>?;
    if (heatMapMatrix == null) {
      return _getDefaultHeatMapData(); // Fallback to mock data
    }

    // Group by floor/location
    for (var locationData in heatMapMatrix) {
      final location = locationData['location'] as String;
      final categories = locationData['categories'] as Map<String, dynamic>;

      // Calculate total issues for this location
      final totalIssues = categories.values.fold<int>(
        0,
        (sum, count) => sum + (count as int),
      );

      // Determine color based on issue count
      Color color;
      if (totalIssues == 0) {
        color = Colors.green;
      } else if (totalIssues <= 2) {
        color = Colors.yellow;
      } else if (totalIssues <= 4) {
        color = Colors.orange;
      } else {
        color = Colors.red;
      }

      // Extract floor number and unit from location (e.g., "Floor 1 - Unit 101")
      final parts = location.split(' - ');
      final floorKey = parts.isNotEmpty ? parts[0] : location;
      final unitNumber =
          parts.length > 1 ? parts[1].replaceAll('Unit ', '') : location;

      if (!result.containsKey(floorKey)) {
        result[floorKey] = [];
      }

      result[floorKey]!.add(HeatMapData(unitNumber, totalIssues, color));
    }

    // If no data, return default
    if (result.isEmpty) {
      return _getDefaultHeatMapData();
    }

    return result;
  }

  Map<String, List<HeatMapData>> _getDefaultHeatMapData() {
    return {
      'Floor 1': [
        HeatMapData('101', 0, Colors.green),
        HeatMapData('102', 0, Colors.green),
        HeatMapData('103', 0, Colors.green),
        HeatMapData('104', 0, Colors.green),
        HeatMapData('105', 0, Colors.green),
        HeatMapData('106', 0, Colors.green),
      ],
    };
  }

  // Helper function to convert routeKey to actual route path
  String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_roles': '/user/roles',
      'work_maintenance': '/work/maintenance',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
    };
    return pathMap[routeKey];
  }

  // Handle logout functionality
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Export analytics data
  Future<void> _exportData(String format) async {
    try {
      String reportType = 'comprehensive';
      int days = _getDaysFromDateRange();

      String filename;
      String mimeType;
      String data;

      switch (format) {
        case 'csv':
          data = await _apiService.exportAnalyticsCSV(
            reportType: reportType,
            days: days,
          );
          filename = 'facilityfix_analytics_${DateTime.now().millisecondsSinceEpoch}.csv';
          mimeType = 'text/csv';
          break;
        case 'excel':
          data = await _apiService.exportAnalyticsExcel(
            reportType: reportType,
            days: days,
          );
          filename = 'facilityfix_analytics_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'json':
          data = await _apiService.exportAnalyticsJSON(
            reportType: reportType,
            days: days,
          );
          filename = 'facilityfix_analytics_${DateTime.now().millisecondsSinceEpoch}.json';
          mimeType = 'application/json';
          break;
        case 'dashboard':
          data = await _apiService.exportDashboardSummary(
            format: 'csv',
            days: days,
          );
          filename = 'facilityfix_dashboard_summary_${DateTime.now().millisecondsSinceEpoch}.csv';
          mimeType = 'text/csv';
          break;
        default:
          throw Exception('Unsupported export format: $format');
      }

      _downloadFile(data, filename, mimeType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Analytics exported successfully as $format'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('[v0] Error exporting data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Download file (web implementation)
  void _downloadFile(String content, String filename, String mimeType) {
    print('[v0] Downloading file: $filename');
    print('[v0] Content length: ${content.length} bytes');
    
    try {
      // Create a blob from the content
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], mimeType);
      
      // Create a download URL and trigger download
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      
      // Clean up the URL
      html.Url.revokeObjectUrl(url);
      
      print('[v0] Download triggered successfully');
      
      // Show success message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download started: $filename'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('[v0] Error triggering download: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download file: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return FacilityFixLayout(
      currentRoute: 'analytics',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchAnalyticsData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================
                    // TOP ROW: ANALYTICS STATISTICS CARDS
                    // ============================================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 800) {
                          // Stack cards vertically on smaller screens
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildAnalyticsCard(
                                      'TOTAL REQUEST',
                                      _totalRequests.toString(),
                                      _totalRequestsChange > 0
                                          ? '${_totalRequestsChange.toStringAsFixed(1)}% from last month'
                                          : '',
                                      _totalRequestsIncreasing,
                                      Colors.blue,
                                      Icons.inventory_2_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildAnalyticsCard(
                                      'OPEN ISSUE',
                                      _openIssues.toString(),
                                      _openIssuesChange > 0
                                          ? '${_openIssuesChange.toStringAsFixed(1)}% from last week'
                                          : '',
                                      _openIssuesIncreasing,
                                      Colors.yellow[700]!,
                                      Icons.layers_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildAnalyticsCard(
                                      'RESOLVED TODAY',
                                      _resolvedToday.toString(),
                                      _resolvedTodayChange > 0
                                          ? '${_resolvedTodayChange.toStringAsFixed(1)}% from yesterday'
                                          : '',
                                      _resolvedTodayIncreasing,
                                      Colors.green,
                                      Icons.check_circle_outline,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildAnalyticsCard(
                                      'RESOLUTION TIME',
                                      '${_resolutionTime.toStringAsFixed(1)} days',
                                      _resolutionTimeChange > 0
                                          ? '${_resolutionTimeChange.toStringAsFixed(1)}% improvement'
                                          : '',
                                      _resolutionTimeImproving,
                                      Colors.red,
                                      Icons.trending_up,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          // Show all cards in a row on larger screens
                          return Row(
                            children: [
                              Expanded(
                                child: _buildAnalyticsCard(
                                  'TOTAL REQUEST',
                                  _totalRequests.toString(),
                                  _totalRequestsChange > 0
                                      ? '${_totalRequestsChange.toStringAsFixed(1)}% from last month'
                                      : '',
                                  _totalRequestsIncreasing,
                                  Colors.blue,
                                  Icons.inventory_2_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAnalyticsCard(
                                  'OPEN ISSUE',
                                  _openIssues.toString(),
                                  _openIssuesChange > 0
                                      ? '${_openIssuesChange.toStringAsFixed(1)}% from last week'
                                      : '',
                                  _openIssuesIncreasing,
                                  Colors.yellow[700]!,
                                  Icons.layers_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAnalyticsCard(
                                  'RESOLVED TODAY',
                                  _resolvedToday.toString(),
                                  _resolvedTodayChange > 0
                                      ? '${_resolvedTodayChange.toStringAsFixed(1)}% from yesterday'
                                      : '',
                                  _resolvedTodayIncreasing,
                                  Colors.green,
                                  Icons.check_circle_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAnalyticsCard(
                                  'RESOLUTION TIME',
                                  '${_resolutionTime.toStringAsFixed(1)} days',
                                  _resolutionTimeChange > 0
                                      ? '${_resolutionTimeChange.toStringAsFixed(1)}% improvement'
                                      : '',
                                  _resolutionTimeImproving,
                                  Colors.red,
                                  Icons.trending_up,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // ============================================
                    // FILTER CONTROLS ROW
                    // ============================================
                    _buildFilterControls(),
                    const SizedBox(height: 24),

                    // ============================================
                    // MIDDLE ROW: HEAT MAP + PIE CHART
                    // ============================================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1000) {
                          // Stack vertically on smaller screens
                          return Column(
                            children: [
                              _buildBuildingHeatMap(),
                              const SizedBox(height: 20),
                              _buildTopIssueChart(),
                            ],
                          );
                        } else {
                          // Side by side on larger screens
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 1, child: _buildBuildingHeatMap()),
                              const SizedBox(width: 20),
                              Expanded(flex: 1, child: _buildTopIssueChart()),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // ============================================
                    // BOTTOM ROW: DOWNTIME TRACKING CHART
                    // ============================================
                    _buildDowntimeTrackingChart(),
                  ],
                ),
              ),
    );
  }

  // ============================================
  // ANALYTICS STATISTICS CARD WIDGET
  // ============================================
  Widget _buildAnalyticsCard(
    String title,
    String value,
    String subtitle,
    bool isIncrease,
    Color color,
    IconData icon,
  ) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title and Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),

          // Main Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          // Bottom Row: Percentage and Subtitle (only show if subtitle is not empty)
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isIncrease ? Icons.trending_up : Icons.trending_down,
                  color: isIncrease ? Colors.green : Colors.red,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isIncrease ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================
  // FILTER CONTROLS WIDGET
  // ============================================
  Widget _buildFilterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side filters
        Row(
          children: [
            // Date Range Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  value: selectedDateRange,
                  items:
                      [
                        'This Week',
                        'This Month',
                        'Last Month',
                        'Last 3 Months',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text('Date Range: $value'),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDateRange = newValue!;
                    });
                    _fetchAnalyticsData();
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Status Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  value: selectedStatus,
                  items:
                      ['All', 'Open', 'In Progress', 'Resolved', 'Closed'].map((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text('Status: $value'),
                        );
                      }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                    _fetchAnalyticsData();
                  },
                ),
              ),
            ),
          ],
        ),

        // Right side buttons
        Row(
          children: [
            // Refresh Button
            TextButton.icon(
              onPressed: () {
                _fetchAnalyticsData();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
            const SizedBox(width: 12),

            // Export Button with Enhanced Menu
            PopupMenuButton<String>(
              onSelected: (String format) {
                _exportData(format);
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('📊 Enhanced CSV Report'),
                    ],
                  ),
                ),
              
                const PopupMenuItem(
                  value: 'json',
                  child: Row(
                    children: [
                      Icon(Icons.code, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('⚡ JSON Data Export'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'dashboard',
                  child: Row(
                    children: [
                      Icon(Icons.dashboard, size: 18, color: Colors.purple),
                      SizedBox(width: 8),
                      Text('📋 Executive Summary'),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.analytics, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Professional Export',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================
  // BUILDING HEAT MAP WIDGET
  // ============================================
  Widget _buildBuildingHeatMap() {
    final heatMapData =
        _buildingHeatMap.isNotEmpty
            ? _buildingHeatMap
            : _getDefaultHeatMapData();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Building Heat Map',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Heat Map Grid
            Column(
              children:
                  heatMapData.entries.map((floorEntry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          // Floor Label
                          SizedBox(
                            width: 60,
                            child: Text(
                              floorEntry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Room Units
                          Expanded(
                            child: Row(
                              children:
                                  floorEntry.value.map((unit) {
                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 4),
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: unit.color,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            unit.unitNumber,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            // Heat Map Legend
            const Text(
              'Showing repair request per unit',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLegendItem(Colors.green, '0 requests'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.yellow, '1-2 requests'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, '2-3 requests'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, '3+ requests'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // LEGEND ITEM HELPER WIDGET
  // ============================================
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ============================================
  // TOP ISSUE BY CATEGORY PIE CHART WIDGET
  // ============================================
  Widget _buildTopIssueChart() {
    final categoryData =
        _categoryData.isNotEmpty
            ? _categoryData
            : {
              'HVAC': 28,
              'Electrical': 15,
              'Civil/Carpentry': 10,
              'Plumbing': 10,
              'Others': 10,
            };

    // Calculate total for percentages
    final total = categoryData.values.fold<int>(0, (sum, count) => sum + count);

    // Define colors for categories
    final categoryColors = {
      'HVAC': Colors.blue,
      'hvac': Colors.blue,
      'Electrical': Colors.orange,
      'electrical': Colors.orange,
      'Civil/Carpentry': Colors.red,
      'carpentry': Colors.red,
      'Plumbing': Colors.yellow,
      'plumbing': Colors.yellow,
      'Others': Colors.green,
      'general': Colors.green,
      'pest control': Colors.purple,
      'masonry': Colors.brown,
      'security': Colors.indigo,
      'fire_safety': Colors.deepOrange,
    };

    // Create pie chart sections
    final sections =
        categoryData.entries.map((entry) {
          final color =
              categoryColors[entry.key] ??
              categoryColors[entry.key.toLowerCase()] ??
              Colors.grey;
          final percentage = total > 0 ? (entry.value / total * 100) : 0;

          return PieChartSectionData(
            color: color,
            value: entry.value.toDouble(),
            title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Issue by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Pie Chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: sections,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Chart Legend with Statistics
            const Text(
              'MOST PROBLEMATIC AREAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            ...categoryData.entries.map((entry) {
              final color =
                  categoryColors[entry.key] ??
                  categoryColors[entry.key.toLowerCase()] ??
                  Colors.grey;
              final displayName = entry.key.toUpperCase();
              return _buildCategoryItem(
                displayName,
                '${entry.value} requests',
                color,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CATEGORY ITEM HELPER WIDGET
  // ============================================
  Widget _buildCategoryItem(String category, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          Text(count, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  // ============================================
  // REQUEST TRENDS CHART WIDGET
  // ============================================
  Widget _buildDowntimeTrackingChart() {
    // Generate spots from real data
    final List<FlSpot> spots = [];
    if (_trendChartData.isNotEmpty) {
      for (int i = 0; i < _trendChartData.length && i < 30; i++) {
        spots.add(FlSpot(i.toDouble(), _trendChartData[i]['value']));
      }
    } else {
      // Fallback data
      for (int i = 0; i < 7; i++) {
        spots.add(FlSpot(i.toDouble(), (i * 2 + 1).toDouble()));
      }
    }

    final double maxY = spots.isEmpty
        ? 10
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Request Trends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  // decoration: BoxDecoration(
                  //   color: Colors.grey[100],
                  //   borderRadius: BorderRadius.circular(16),
                  // ),
                  // child: DropdownButtonHideUnderline(
                  //   child: DropdownButton<String>(
                  //     value: selectedDowntimeUnit,
                  //     items:
                  //         ['This Month', 'Last Month', 'Last 3 Months'].map((
                  //           String value,
                  //         ) {
                  //           return DropdownMenuItem<String>(
                  //             value: value,
                  //             child: Text(
                  //               value,
                  //               style: const TextStyle(fontSize: 12),
                  //             ),
                  //           );
                  //         }).toList(),
                  //     onChanged: (String? newValue) {
                  //       setState(() {
                  //         selectedDowntimeUnit = newValue!;
                  //       });
                  //       _fetchAnalyticsData();
                  //     },
                  //   ),
                  // ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Area Chart
            SizedBox(
              height: 300,
              child: spots.isEmpty
                  ? const Center(child: Text('No data available'))
                  : LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (spots.length / 5).ceilToDouble(),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= _trendChartData.length) {
                            return const Text('');
                          }
                          final date = _trendChartData.isNotEmpty &&
                                  value.toInt() < _trendChartData.length
                              ? _trendChartData[value.toInt()]['date'] as String
                              : '';
                          // Show only day (DD)
                          final dayStr = date.split('-').length > 2
                              ? date.split('-')[2]
                              : value.toInt().toString();
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              dayStr,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY / 5,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (spots.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.15),
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.blue.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Chart Legend and Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildChartLegendItem('Daily Requests', Colors.blue),
                if (_timeSeriesData != null)
                  Row(
                    children: [
                      Text(
                        'Total: ${_timeSeriesData!['summary']?['total'] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Avg: ${(_timeSeriesData!['summary']?['average'] ?? 0).toStringAsFixed(1)}/day',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CHART LEGEND ITEM HELPER WIDGET
  // ============================================
  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ============================================
// HEAT MAP DATA MODEL
// Helper class to structure heat map data
// ============================================
class HeatMapData {
  final String unitNumber;
  final int requestCount;
  final Color color;

  HeatMapData(this.unitNumber, this.requestCount, this.color);
}
