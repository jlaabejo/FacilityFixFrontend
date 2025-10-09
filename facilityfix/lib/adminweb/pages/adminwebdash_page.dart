import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../../services/api_services.dart';
import '../../services/auth_storage.dart';

class AdminWebDashPage extends StatefulWidget {
  const AdminWebDashPage({super.key});

  @override
  State<AdminWebDashPage> createState() => _AdminWebDashPageState();
}

class _AdminWebDashPageState extends State<AdminWebDashPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final APIService _apiService = APIService();

  bool _isLoading = true;
  String? _errorMessage;

  // Dashboard stats from API
  Map<String, dynamic>? _dashboardStats;
  List<dynamic> _allRequests = [];
  List<dynamic> _maintenanceTasks = [];
  Map<String, dynamic>? _workOrderTrends;

  Map<String, String> _userIdToNameMap = {};

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        print('[AdminWebDash] Auth token retrieved and set in API service');
      } else {
        print('[AdminWebDash] Warning: No auth token found in storage');
      }

      // Fetch all tenant requests (includes Concern Slips, Job Services, Work Orders with AI categorization)
      final allRequests = await _apiService.getAllTenantRequests();
      
      // Fetch maintenance tasks
      final maintenanceTasks = await _apiService.getAllMaintenance();

      // Calculate dashboard statistics from real data
      final activeJobs = allRequests.where((request) => 
        request['status'] == 'assigned' || request['status'] == 'in_progress'
      ).length;

      final pendingConcerns = allRequests.where((request) => 
        request['status'] == 'pending'
      ).length;

      final totalRequests = allRequests.length;

      final completedRequests = allRequests.where((request) => 
        request['status'] == 'completed' || request['status'] == 'done'
      ).length;

      final completionRate = totalRequests > 0 
        ? ((completedRequests / totalRequests) * 100).round()
        : 0;

      // Generate mock trends data based on real request count
      final mockTrends = _generateMockTrends(allRequests);

      setState(() {
        _dashboardStats = {
          'active_jobs': activeJobs,
          'pending_concerns': pendingConcerns,
          'total_requests': totalRequests,
          'completion_rate': completionRate,
        };
        _allRequests = allRequests;
        _workOrderTrends = mockTrends;
        _maintenanceTasks = maintenanceTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
      print('[AdminWebDash] Error fetching dashboard data: $e');
    }
  }

  Map<String, dynamic> _generateMockTrends(List<dynamic> requests) {
    final Map<String, int> dailyBreakdown = {};
    
    // Generate last 7 days of data based on actual requests
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dateKey = date.toString().split(' ')[0];
      
      // Count requests for this day (mock distribution)
      final dayRequests = requests.where((request) {
        final createdAt = DateTime.tryParse(request['created_at'] ?? '');
        if (createdAt == null) return false;
        return createdAt.day == date.day && createdAt.month == date.month;
      }).length;
      
      // If no requests for this day, use a small random number
      dailyBreakdown[dateKey] = dayRequests > 0 ? dayRequests : (i % 3) + 1;
    }
    
    return {'daily_breakdown': dailyBreakdown};
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
                context.go('/'); // Go back to login page
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // Column widths for Repair Task table
  final List<double> _colW = <double>[
    180, // TASK
    120, // PRIORITY
    150, // NAME / ASSIGNED TO
    120, // STATUS
  ];

  // Fixed width cell helper
  Widget _fixedCell(
    int i,
    Widget child, {
    Alignment align = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: _colW[i],
      child: Align(alignment: align, child: child),
    );
  }

  // Text with ellipsis helper
  Text _ellipsis(String s, {TextStyle? style}) => Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    style: style,
  );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return FacilityFixLayout(
      currentRoute: 'dashboard',
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
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchDashboardData,
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
                    // TOP ROW: STATISTICS CARDS SECTION (now with real data)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 800) {
                          // Stack cards vertically on smaller screens (Mobile/Tablet)
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'ACTIVE WORK\nORDERS',
                                      '${_dashboardStats?['active_jobs'] ?? 0}',
                                      '${_dashboardStats?['pending_concerns'] ?? 0} pending',
                                      '${_dashboardStats?['completion_rate'] ?? 0}%',
                                      Colors.blue,
                                      Icons.work_outline,
                                      isIncrease: true,
                                      routeKey: 'work_maintenance',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'SCHEDULED\nMAINTENANCE',
                                      '${_maintenanceTasks.length}',
                                      'tasks this week',
                                      '',
                                      Colors.green,
                                      Icons.schedule,
                                      isIncrease: false,
                                      routeKey: 'work_maintenance',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatCard(
                                      'REPAIR TASKS\n(ALL TYPES)',
                                      '${_allRequests.length}',
                                      'This month',
                                      '',
                                      Colors.blue,
                                      Icons.build_outlined,
                                      isIncrease: true,
                                      routeKey: 'work_repair',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatCard(
                                      'TOTAL REQUESTS',
                                      '${_dashboardStats?['total_requests'] ?? 0}',
                                      'All time',
                                      '',
                                      Colors.red,
                                      Icons.check_circle_outline,
                                      isIncrease: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          // Show all cards in a row on larger screens (Desktop)
                          return Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'ACTIVE WORK\nORDERS',
                                  '${_dashboardStats?['active_jobs'] ?? 0}',
                                  '${_dashboardStats?['pending_concerns'] ?? 0} pending',
                                  '${_dashboardStats?['completion_rate'] ?? 0}%',
                                  Colors.blue,
                                  Icons.work_outline,
                                  isIncrease: true,
                                  routeKey: 'work_maintenance',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'SCHEDULED\nMAINTENANCE',
                                  '${_maintenanceTasks.length}',
                                  'tasks this week',
                                  '',
                                  Colors.green,
                                  Icons.schedule,
                                  isIncrease: false,
                                  routeKey: 'work_maintenance',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'REPAIR TASKS\n(ALL TYPES)',
                                  '${_allRequests.length}',
                                  'This month',
                                  '',
                                  Colors.blue,
                                  Icons.build_outlined,
                                  isIncrease: true,
                                  routeKey: 'work_repair',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'TOTAL REQUESTS',
                                  '${_dashboardStats?['total_requests'] ?? 0}',
                                  'All time',
                                  '',
                                  Colors.red,
                                  Icons.check_circle_outline,
                                  isIncrease: true,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // MIDDLE ROW: REPAIR TASKS TABLE + CALENDAR
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1000) {
                          // Stack vertically on smaller screens
                          return Column(
                            children: [
                              _buildRepairTaskTable(),
                              const SizedBox(height: 20),
                              _buildMaintenanceCalendar(),
                            ],
                          );
                        } else {
                          // Side by side on larger screens
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildRepairTaskTable()),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 1,
                                child: _buildMaintenanceCalendar(),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // ============================================
                    // BOTTOM ROW: MAINTENANCE SCHEDULE + CHART
                    // ============================================
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1000) {
                          // Stack vertically on smaller screens
                          return Column(
                            children: [
                              _buildMaintenanceSchedule(),
                              const SizedBox(height: 20),
                              _buildRepairChart(),
                            ],
                          );
                        } else {
                          // Side by side on larger screens
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: _buildMaintenanceSchedule(),
                              ),
                              const SizedBox(width: 20),
                              Expanded(flex: 2, child: _buildRepairChart()),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  // ============================================
  // STATISTICS CARD WIDGET
  // ============================================
  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    String percentage,
    Color color,
    IconData icon, {
    bool isIncrease = true,
    String? routeKey,
  }) {
    return InkWell(
      onTap: () {
        if (routeKey != null) {
          final routePath = _getRoutePath(routeKey);
          if (routePath != null) {
            context.go(routePath); // navigate on tap
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            const SizedBox(height: 4),

            // Bottom Row: Percentage and Subtitle
            Row(
              children: [
                // Percentage indicator (if provided)
                if (percentage.isNotEmpty) ...[
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: isIncrease ? Colors.green : Colors.red,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    percentage,
                    style: TextStyle(
                      fontSize: 11,
                      color: isIncrease ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Subtitle text
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // REPAIR TASKS TABLE WIDGET (now with real data)
  // ============================================
  Widget _buildRepairTaskTable() {
    final tasks =
        _allRequests.take(5).map((request) {
          // Map request data to table format with AI-generated category and priority
          final priority = request['priority'] ?? 'medium';
          final status = request['status'] ?? 'pending';
          final category = request['category'] ?? 'general'; // AI-generated category

          final assignedToId = request['assigned_to'];
          String displayName = 'Unassigned';
          if (assignedToId != null && assignedToId.toString().isNotEmpty) {
            displayName =
                _userIdToNameMap[assignedToId] ?? assignedToId.toString();
          }

          Color priorityColor;
          switch (priority.toLowerCase()) {
            case 'high':
            case 'critical':
              priorityColor = Colors.red;
              break;
            case 'medium':
              priorityColor = Colors.orange;
              break;
            default:
              priorityColor = Colors.green;
          }

          Color statusColor;
          switch (status.toLowerCase()) {
            case 'completed':
            case 'done':
              statusColor = Colors.pink;
              break;
            case 'in_progress':
            case 'assigned':
              statusColor = Colors.green;
              break;
            default:
              statusColor = Colors.orange;
          }

          return {
            'task': request['title'] ?? 'No title',
            'priority': priority.toString().toUpperCase(),
            'name': displayName, // Use display name instead of ID
            'status': status.toString().replaceAll('_', ' ').toUpperCase(),
            'priorityColor': priorityColor,
            'statusColor': statusColor,
            'category': category, // Include AI-generated category
            'request_type': request['request_type'] ?? 'Concern Slip',
          };
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.build, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Repair Tasks (All Types)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context.go('/work/repair');
                  },
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No repair tasks available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              // Data Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width * 0.4,
                  ),
                  child: DataTable(
                    columnSpacing: 40,
                    dataRowMinHeight: 65,
                    dataRowMaxHeight: 65,
                    columns: [
                      DataColumn(
                        label: _fixedCell(
                          0,
                          Text(
                            'Task (AI Category)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: _fixedCell(
                          1,
                          Text(
                            'AI Priority',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: _fixedCell(
                          2,
                          Text(
                            'Assigned To',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      DataColumn(
                        label: _fixedCell(
                          3,
                          Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                    rows:
                        tasks.map((task) {
                          return DataRow(
                            cells: [
                              // TASK (fixed width + ellipsis) + AI Category
                              DataCell(
                                _fixedCell(
                                  0,
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _ellipsis(
                                        task['task'] as String,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${task['category']} • ${task['request_type']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // AI PRIORITY
                              DataCell(
                                _fixedCell(
                                  1,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (task['priorityColor'] as Color)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      task['priority'] as String,
                                      style: TextStyle(
                                        color: task['priorityColor'] as Color,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // NAME (fixed width + ellipsis)
                              DataCell(
                                _fixedCell(
                                  2,
                                  _ellipsis(
                                    task['name'] as String,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),

                              // STATUS
                              DataCell(
                                _fixedCell(
                                  3,
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (task['statusColor'] as Color)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      task['status'] as String,
                                      style: TextStyle(
                                        color: task['statusColor'] as Color,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // MAINTENANCE CALENDAR WIDGET
  // ============================================
  Widget _buildMaintenanceCalendar() {
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
              'Maintenance Calendar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TableCalendar<void>(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.black87),
                todayDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerDecoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              eventLoader: (day) {
                // Show events based on real maintenance tasks
                final hasMaintenanceTask = _maintenanceTasks.any((task) {
                  final scheduledDate = DateTime.tryParse(task['scheduled_date'] ?? '');
                  if (scheduledDate == null) return false;
                  return scheduledDate.day == day.day && 
                         scheduledDate.month == day.month &&
                         scheduledDate.year == day.year;
                });
                
                final hasRepairTask = _allRequests.any((request) {
                  final createdAt = DateTime.tryParse(request['created_at'] ?? '');
                  if (createdAt == null) return false;
                  return createdAt.day == day.day && 
                         createdAt.month == day.month &&
                         createdAt.year == day.year;
                });

                if (hasMaintenanceTask) return ['maintenance'];
                if (hasRepairTask) return ['repair'];
                return [];
              },
            ),
            const SizedBox(height: 16),

            // Calendar Legend
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Repair Tasks', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Maintenance', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // MAINTENANCE SCHEDULE WIDGET (now with real data)
  // ============================================
  Widget _buildMaintenanceSchedule() {
    final schedules =
        _maintenanceTasks.take(2).map((task) {
          final assignedToId = task['assigned_to'];
          String assigneeName = 'Unassigned';
          if (assignedToId != null && assignedToId.toString().isNotEmpty) {
            assigneeName =
                _userIdToNameMap[assignedToId] ?? assignedToId.toString();
          }

          return {
            'title': task['task_title'] ?? task['title'] ?? 'Maintenance Task',
            'assignee': assigneeName, // Use display name instead of ID
            'date': task['scheduled_date'] ?? DateTime.now().toString(),
          };
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
            // Schedule Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Maintenance Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    context.go('/calendar');
                  },
                  child: const Text(
                    'Calendar',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (schedules.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(
                  child: Text(
                    'No maintenance schedules available',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              // Schedule Items
              ...schedules.map(
                (schedule) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Schedule',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        schedule['title']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            schedule['assignee']!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            schedule['date']!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 2),

            // Add New Schedule Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/work/maintenance');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text('Schedule new Maintenance'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // REPAIR CHART WIDGET (now with real data)
  // ============================================
  Widget _buildRepairChart() {
    final dailyBreakdown =
        _workOrderTrends?['daily_breakdown'] as Map<String, dynamic>? ?? {};

    // Convert daily breakdown to chart data points
    List<FlSpot> repairSpots = [];
    List<FlSpot> maintenanceSpots = [];

    // Get last 7 days of data
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dateKey = date.toString().split(' ')[0];
      final count = dailyBreakdown[dateKey] ?? 0;

      // Split between repair and maintenance based on actual data
      final repairCount = _allRequests.where((request) {
        final createdAt = DateTime.tryParse(request['created_at'] ?? '');
        if (createdAt == null) return false;
        return createdAt.day == date.day && createdAt.month == date.month;
      }).length.toDouble();

      final maintenanceCount = _maintenanceTasks.where((task) {
        final scheduledDate = DateTime.tryParse(task['scheduled_date'] ?? '');
        if (scheduledDate == null) return false;
        return scheduledDate.day == date.day && scheduledDate.month == date.month;
      }).length.toDouble();

      repairSpots.add(FlSpot(i.toDouble(), repairCount));
      maintenanceSpots.add(FlSpot(i.toDouble(), maintenanceCount));
    }

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
                  'Repair and Maintenance Trends',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Weekly',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            //linechart
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          );
                          Widget text;
                          switch (value.toInt()) {
                            case 0:
                              text = const Text('Sun', style: style);
                              break;
                            case 1:
                              text = const Text('Mon', style: style);
                              break;
                            case 2:
                              text = const Text('Tue', style: style);
                              break;
                            case 3:
                              text = const Text('Wed', style: style);
                              break;
                            case 4:
                              text = const Text('Thu', style: style);
                              break;
                            case 5:
                              text = const Text('Fri', style: style);
                              break;
                            case 6:
                              text = const Text('Sat', style: style);
                              break;
                            default:
                              text = const Text('', style: style);
                              break;
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: text,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
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
                  maxX: 6,
                  minY: 0,
                  maxY: 20,
                  lineBarsData: [
                    // Repair Tasks line (green)
                    LineChartBarData(
                      spots: repairSpots.isNotEmpty
                          ? repairSpots
                          : const [
                              FlSpot(0, 3),
                              FlSpot(1, 8),
                              FlSpot(2, 2),
                              FlSpot(3, 6),
                              FlSpot(4, 4),
                              FlSpot(5, 12),
                              FlSpot(6, 5),
                            ],
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.green.withOpacity(0.8), Colors.green],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter:
                            (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.green,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Maintenance line (blue)
                    LineChartBarData(
                      spots: maintenanceSpots.isNotEmpty
                          ? maintenanceSpots
                          : const [
                              FlSpot(0, 8),
                              FlSpot(1, 12),
                              FlSpot(2, 6),
                              FlSpot(3, 14),
                              FlSpot(4, 10),
                              FlSpot(5, 16),
                              FlSpot(6, 10),
                            ],
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue.withOpacity(0.8), Colors.blue],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter:
                            (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.blue,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                ),
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Repair Tasks', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 24),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Maintenance', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}