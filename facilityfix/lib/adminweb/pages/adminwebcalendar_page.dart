import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_services.dart';
import '../layout/facilityfix_layout.dart';
import '../popupwidgets/createmaintenancedialogue_popup.dart';

class AdminWebCalendarPage extends StatefulWidget {
  const AdminWebCalendarPage({super.key});

  @override
  State<AdminWebCalendarPage> createState() => _AdminWebCalendarPageState();
}

class _AdminWebCalendarPageState extends State<AdminWebCalendarPage> {
  // Current date and calendar navigation
  final DateTime _currentDate = DateTime.now();
  DateTime _selectedMonth = DateTime.now();

  // Real task data from API
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiService = APIService();
      
      // Fetch concern slips
      final concernSlips = await apiService.getAllConcernSlips();
      print('[CALENDAR] Fetched ${concernSlips.length} concern slips');
      
      // Fetch maintenance tasks
      final maintenanceTasks = await apiService.getAllMaintenance();
      print('[CALENDAR] Fetched ${maintenanceTasks.length} maintenance tasks');

      if (mounted) {
        setState(() {
          _tasks = [];
          
          // Process concern slips
          for (var slip in concernSlips) {
            final processed = _processConcernSlip(slip);
            print('[CALENDAR] Processed concern slip: ${processed['id']} on ${processed['date']}');
            _tasks.add(processed);
          }
          
          // Process maintenance tasks
          for (var task in maintenanceTasks) {
            final processed = _processMaintenanceTask(task);
            print('[CALENDAR] Processed maintenance: ${processed['id']} on ${processed['date']}');
            _tasks.add(processed);
          }
          
          print('[CALENDAR] Total tasks loaded: ${_tasks.length}');
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[CALENDAR] Error loading data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load calendar data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _processConcernSlip(Map<String, dynamic> slip) {
    return {
      'id': slip['formatted_id'] ?? slip['id'] ?? 'N/A',
      'title': slip['title'] ?? 'Concern Slip',
      'description': slip['description'] ?? '',
      'assignedTo': slip['assigned_to'] ?? slip['assigned_staff'] ?? 'Unassigned',
      'date': _parseDate(slip['created_at'] ?? slip['submitted_at']),
      'type': 'concern_slip',
      'priority': (slip['priority'] ?? 'medium').toString().toLowerCase(),
      'status': (slip['status'] ?? 'pending').toString().toLowerCase(),
      'category': slip['category'] ?? 'general',
      'location': slip['unit_id'] ?? slip['location'] ?? 'N/A',
    };
  }

  Map<String, dynamic> _processMaintenanceTask(Map<String, dynamic> task) {
    return {
      'id': task['formatted_id'] ?? task['id'] ?? 'N/A',
      'title': task['task_title'] ?? task['title'] ?? 'Maintenance Task',
      'description': task['task_description'] ?? task['description'] ?? '',
      'assignedTo': task['assigned_to'] ?? task['assigned_staff'] ?? 'Unassigned',
      'date': _parseDate(task['scheduled_date'] ?? task['created_at']),
      'type': 'maintenance',
      'priority': (task['priority'] ?? 'medium').toString().toLowerCase(),
      'status': (task['status'] ?? 'scheduled').toString().toLowerCase(),
      'category': task['category'] ?? 'preventive',
      'location': task['location'] ?? 'N/A',
    };
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ?? DateTime.now();
    }
    return DateTime.now();
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

  //month jump dropdown
  Widget _monthDropdown() {
    return PopupMenuButton<int>(
      tooltip: 'Select month',
      position: PopupMenuPosition.under,
      onSelected: (m) {
        setState(() {
          _selectedMonth = DateTime(
            _selectedMonth.year,
            m,
            1,
          ); // jump same year
        });
      },
      itemBuilder:
          (ctx) => [
            for (int i = 1; i <= 12; i++)
              PopupMenuItem<int>(
                value: i,
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      child:
                          i == _selectedMonth.month
                              ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.blue,
                              )
                              : const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    Text(_getMonthName(i)), // reuse function
                  ],
                ),
              ),
          ],
      // the clickable chip
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Text(
              'Month', //stays "Month" always
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 18),
          ],
        ),
      ),
    );
  }

  // date clickable to open create maintenance dialog
  void _openDayDialog(DateTime date) {
    final tasks = _getTasksForDate(date);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Date (left) + Create Task (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_getMonthName(date.month)} ${date.day}, ${date.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Close the day dialog, then show the 2-step create flow
                        Navigator.of(ctx).pop();
                        showCreateMaintenanceTaskDialog(context);
                        // If you want to pass the date to your forms, you can
                        // supply callbacks here:
                        // showCreateMaintenanceTaskDialog(
                        //   context,
                        //   onInternal: () => context.go('/adminweb/pages/workmaintenance_form?date=${date.toIso8601String()}'),
                        //   onExternal: () => context.go('/adminweb/pages/externalmaintenance_form?date=${date.toIso8601String()}'),
                        // );
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Create Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),

                const SizedBox(height: 12),

                // Body: task list (or empty state)
                if (tasks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.inbox_outlined, color: Colors.grey[500]),
                        const SizedBox(width: 12),
                        Text(
                          'No tasks for this date',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                else
                  ...tasks.map(
                    (task) => InkWell(
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _showTaskDetails(task);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _getTaskColor(task['type']).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getTaskColor(
                              task['type'],
                            ).withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getTaskColor(task['type']),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task['title'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    task['assignedTo'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[500],
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Get tasks for a specific date
  List<Map<String, dynamic>> _getTasksForDate(DateTime date) {
    final matches = _tasks.where((task) {
      DateTime taskDate = task['date'] as DateTime;
      final matches = taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
      return matches;
    }).toList();
    
    if (matches.isNotEmpty) {
      print('[CALENDAR] Found ${matches.length} tasks for ${date.year}-${date.month}-${date.day}');
    }
    
    return matches;
  }

  // Get task color based on type
  Color _getTaskColor(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
        return const Color(0xFF00BCD4); // Cyan/Blue for maintenance
      case 'repair':
        return const Color(0xFF4CAF50); // Green for repair
      case 'concern_slip':
      case 'concern slip':
        return const Color(0xFFFF6B6B); // Red for concern slips
      case 'job_service':
      case 'job service':
        return const Color(0xFFFFB84D); // Orange for job services
      default:
        return Colors.grey;
    }
  }

  // Navigate to previous month
  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  // Navigate to next month
  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  // Show task details popup
  void _showTaskDetails(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with task type badge and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTaskColor(task['type']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task['title'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Edit button
                        IconButton(
                          onPressed: () {
                            // TODO: Implement edit functionality
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.edit_outlined, size: 20),
                        ),
                        // More options button
                        IconButton(
                          onPressed: () {
                            // TODO: Implement more options
                          },
                          icon: const Icon(Icons.more_horiz, size: 20),
                        ),
                        // Close button
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Priority indicator
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color:
                          task['priority'] == 'high'
                              ? Colors.red
                              : task['priority'] == 'medium'
                              ? Colors.orange
                              : Colors.green,
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${task['priority'].toString().toUpperCase()} Priority',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            task['priority'] == 'high'
                                ? Colors.red
                                : task['priority'] == 'medium'
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task title
                Text(
                  task['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Assigned person
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task['assignedTo'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(task['date']),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    task['description'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.year} - ${date.month.toString().padLeft(2, '0')} - ${date.day.toString().padLeft(2, '0')}';
  }

  // Get month name
  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // Build legend item
  Widget _buildLegendItem(String label, Color color) {
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // Build summary card
  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Get tasks for a specific month
  List<Map<String, dynamic>> _getTasksForMonth(DateTime month) {
    return _tasks.where((task) {
      DateTime taskDate = task['date'] as DateTime;
      return taskDate.year == month.year && taskDate.month == month.month;
    }).toList();
  }

  // Build calendar day cell
  Widget _buildDayCell(DateTime date, bool isCurrentMonth) {
    final tasks = _getTasksForDate(date);
    final hasMultipleTasks = tasks.length > 1;
    final isToday =
        date.year == _currentDate.year &&
        date.month == _currentDate.month &&
        date.day == _currentDate.day;

    return GestureDetector(
      onTap: () => _openDayDialog(date),
      child: Container(
        height: 120,
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date number
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color:
                      isCurrentMonth
                          ? (isToday ? Colors.blue : Colors.black87)
                          : Colors.grey[400],
                ),
              ),
            ),

            // Task items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    // Show first task
                    if (tasks.isNotEmpty)
                      Builder(
                        builder:
                            (chipCtx) => GestureDetector(
                              onTap:
                                  () => _showTaskPopoverFromContext(
                                    tasks[0],
                                    chipCtx,
                                  ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: _getTaskColor(tasks[0]['type']),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tasks[0]['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (tasks[0]['assignedTo'] != null && 
                                        tasks[0]['assignedTo'] != 'Unassigned')
                                      const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                      ),

                    // Show "X+ More" if there are multiple tasks
                    if (hasMultipleTasks)
                      GestureDetector(
                        onTap: () {
                          // Show all tasks for this date
                          _showAllTasksForDate(date, tasks);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          child: Text(
                            '${tasks.length - 1}+ More',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show all tasks for a specific date
  void _showAllTasksForDate(DateTime date, List<Map<String, dynamic>> tasks) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tasks for ${_getMonthName(date.month)} ${date.day}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Task list (each item opens popover anchored to its tile)
                ...tasks.map<Widget>((task) {
                  return Builder(
                    builder:
                        (tileCtx) => InkWell(
                          onTap: () {
                            // Capture the tile's screen rect BEFORE closing the dialog
                            final rect = _rectFromContext(tileCtx);
                            Navigator.of(ctx).pop(); // close list dialog

                            // Show the anchored popover on the base route
                            Future.microtask(
                              () => _showTaskPopoverAt(task, rect),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: _getTaskColor(
                                task['type'],
                              ).withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getTaskColor(
                                  task['type'],
                                ).withOpacity(0.30),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getTaskColor(task['type']),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['title'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        task['assignedTo'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: Colors.grey[500],
                                ),
                              ],
                            ),
                          ),
                        ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  //  Popover helpers
  // Get a screen-space rect for any widget context
  Rect _rectFromContext(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, box.size.width, box.size.height);
  }

  // Map priority -> color
  Color _priorityColor(String? p) {
    switch (p) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  // Reusable round icon button
  Widget _circleIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.black87),
      ),
    );
  }

  // Show the task popover anchored to an on-screen rect
  void _showTaskPopoverAt(Map<String, dynamic> task, Rect anchor) {
    final overlay = Overlay.of(context);
    final screen = MediaQuery.of(context).size;

    const double popW = 520;
    const double margin = 16;

    // Prefer below the anchor; if not enough space, show above.
    double left = anchor.left;
    double top = anchor.bottom + 8;
    if (left + popW > screen.width - margin) {
      left = screen.width - popW - margin;
    }
    // estimated height; if it overflows, flip above
    const double estH = 320;
    if (top + estH > screen.height - margin) {
      top = anchor.top - estH - 8;
      if (top < margin) top = margin;
    }

    OverlayEntry? entry;
    entry = OverlayEntry(
      builder:
          (_) => Stack(
            children: [
              // tap outside to dismiss
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => entry?.remove(),
                  child: Container(color: Colors.transparent),
                ),
              ),

              // the popover card
              Positioned(
                left: left,
                top: top,
                width: popW,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: edit & more on the LEFT, close on the RIGHT
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _circleIconButton(Icons.edit_outlined, () {
                                  // TODO: hook up edit
                                  entry?.remove();
                                }),
                                const SizedBox(width: 8),
                                _circleIconButton(Icons.more_horiz, () {
                                  // TODO: more actions
                                }),
                              ],
                            ),
                            _circleIconButton(
                              Icons.close,
                              () => entry?.remove(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Priority line
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 10,
                              color: _priorityColor(
                                task['priority'] as String?,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(task['priority'] as String?)?.toUpperCase() ?? 'LOW'} Priority',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _priorityColor(
                                  task['priority'] as String?,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Title
                        Text(
                          task['title'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Assigned
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              task['assignedTo'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Date
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(task['date'] as DateTime),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
    );

    overlay.insert(entry);
  }

  // Convenience: compute rect from a widget context and show popover
  void _showTaskPopoverFromContext(
    Map<String, dynamic> task,
    BuildContext anchorCtx,
  ) {
    final rect = _rectFromContext(anchorCtx);
    _showTaskPopoverAt(task, rect);
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'calendar',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading calendar data',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadCalendarData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005CE7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Header: title + breadcrumbs -----
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Calendar",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "Main",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Calendar",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ----- Color Legend -----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Legend:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildLegendItem('Maintenance', const Color(0xFF00BCD4)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Concern Slip', const Color(0xFFFF6B6B)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Job Service', const Color(0xFFFFB84D)),
                  const SizedBox(width: 16),
                  _buildLegendItem('Repair', const Color(0xFF4CAF50)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ----- Task Summary -----
            Row(
              children: [
                _buildSummaryCard(
                  'Total Tasks',
                  _tasks.length.toString(),
                  Icons.task_alt,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  'This Month',
                  _getTasksForMonth(_selectedMonth).length.toString(),
                  Icons.calendar_today,
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  'Assigned',
                  _tasks.where((t) => t['assignedTo'] != 'Unassigned').length.toString(),
                  Icons.person,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildSummaryCard(
                  'Pending',
                  _tasks.where((t) => t['status'].toString().toLowerCase() == 'pending').length.toString(),
                  Icons.pending_actions,
                  Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ----- Calendar container -----
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                height: 700, // Moved height constraint here
                child: Column(
                  children: [
                    // Header row (arrows, month label, dropdown)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: _previousMonth,
                                icon: const Icon(Icons.chevron_left),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                onPressed: _nextMonth,
                                icon: const Icon(Icons.chevron_right),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              // Refresh button
                              IconButton(
                                onPressed: _loadCalendarData,
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Refresh calendar data',
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.grey[100],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // keep your simple months dropdown button here
                              _monthDropdown(),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Day headers + grid
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                  color: Colors.grey[200]!,
                                ),
                              ),
                            ),
                            child: Row(
                              children:
                                  [
                                        'SUN',
                                        'MON',
                                        'TUES',
                                        'WED',
                                        'THURS',
                                        'FRI',
                                        'SAT',
                                      ]
                                      .map(
                                        (day) => Expanded(
                                          child: Center(
                                            child: Text(
                                              day,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[600],
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                          Expanded(child: _buildCalendarGrid()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the calendar grid with dates
  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final firstDayOfWeek = firstDayOfMonth.weekday % 7; // Sunday = 0

    final List<Widget> dayWidgets = [];

    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstDayOfWeek; i++) {
      final date = firstDayOfMonth.subtract(Duration(days: firstDayOfWeek - i));
      dayWidgets.add(_buildDayCell(date, false));
    }

    // Add cells for each day of the month
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      dayWidgets.add(_buildDayCell(date, true));
    }

    // Add empty cells to complete the grid (if needed)
    while (dayWidgets.length % 7 != 0) {
      final date = lastDayOfMonth.add(
        Duration(
          days: dayWidgets.length - (firstDayOfWeek + lastDayOfMonth.day) + 1,
        ),
      );
      dayWidgets.add(_buildDayCell(date, false));
    }

    // Create rows of 7 days each
    final List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(
        Expanded(
          child: Row(
            children:
                dayWidgets
                    .sublist(i, i + 7)
                    .map((widget) => Expanded(child: widget))
                    .toList(),
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}
