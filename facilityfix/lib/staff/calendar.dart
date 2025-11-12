
import 'package:facilityfix/models/cards.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/maintenance.dart';
import 'package:facilityfix/staff/notification.dart';
import 'package:facilityfix/staff/view_details/workorder.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/config/env.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const Color kPrimary = Color(0xFF005CE7);
  static const Color kPrimaryDark = Color(0xFF003E9C);
  static const Color kMutedText = Color(0xFF667085);

  int _selectedIndex = 4;
  DateTime _selectedDate = DateTime.now();
  final EasyDatePickerController _controller = EasyDatePickerController();

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  // Real data from API
  List<WorkOrder> _allWorkOrders = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Current user info for filtering
  String? _currentUserId;
  String? _currentStaffId;
  String? _currentUserName;
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadCalendarData();
    _loadUnreadNotifCount();
  }

  Future<void> _loadUnreadNotifCount() async {
    try {
      final api = APIService(roleOverride: AppRole.staff);
      final count = await api.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadNotifCount = count);
    } catch (e) {
      print('[Calendar] Failed to load unread notification count: $e');
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final profile = await AuthStorage.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentUserId = profile['user_id'] ?? profile['id'];
          _currentStaffId = profile['staff_id'];
          _currentUserName = profile['name'] ??
                           '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  /// Check if a task/request is assigned to the current logged-in user
  bool _isAssignedToCurrentUser(Map<String, dynamic> item) {
    // If no current user info loaded yet, don't filter
    if (_currentUserId == null && _currentStaffId == null && _currentUserName == null) {
      return true;
    }

    // Get the assigned staff information from the item
    final assignedTo = item['assigned_to'];
    final assignedStaff = item['assigned_staff'];
    final assignedStaffId = item['assigned_staff_id'];
    final assignedUserId = item['assigned_user_id'];

    // Check if any of the assigned fields match current user
    if (_currentUserId != null && assignedUserId != null) {
      if (assignedUserId == _currentUserId) return true;
    }

    if (_currentStaffId != null && assignedStaffId != null) {
      if (assignedStaffId == _currentStaffId) return true;
    }

    if (_currentUserName != null && _currentUserName!.isNotEmpty) {
      // Check assigned_to or assigned_staff fields (which might contain name)
      if (assignedTo != null && assignedTo.toString().toLowerCase().contains(_currentUserName!.toLowerCase())) {
        return true;
      }
      if (assignedStaff != null && assignedStaff.toString().toLowerCase().contains(_currentUserName!.toLowerCase())) {
        return true;
      }
    }

    // If no match found, don't show this task
    return false;
  }

  Future<void> _loadCalendarData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final apiService = APIService(roleOverride: AppRole.staff);

      // Fetch all tenant requests (includes concern slips and job services)
      final allRequests = await apiService.getAllTenantRequests();

      // Fetch maintenance tasks
      final maintenanceTasks = await apiService.getAllMaintenance();

      if (mounted) {
        setState(() {
          _allWorkOrders = [];

          // Process tenant requests into WorkOrder objects
          for (var request in allRequests) {
            // Filter by current user - only show tasks assigned to this staff member
            if (_isAssignedToCurrentUser(request)) {
              _allWorkOrders.add(_processRequestToWorkOrder(request));
            }
          }

          // Process maintenance tasks as WorkOrder objects
          for (var task in maintenanceTasks) {
            // Filter by current user - only show tasks assigned to this staff member
            if (_isAssignedToCurrentUser(task)) {
              _allWorkOrders.add(_processMaintenanceToWorkOrder(task));
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load calendar data: $e';
          _isLoading = false;
        });
      }
    }
  }

  WorkOrder _processRequestToWorkOrder(Map<String, dynamic> request) {
    return WorkOrder(
      id: request['formatted_id'] ?? request['id'] ?? 'N/A',
      title: request['title'] ?? 'Request',
      createdAt: _parseDate(request['created_at'] ?? request['submitted_at']),
      updatedAt: _parseDate(request['updated_at']),
      statusTag: _capitalizeStatus(request['status'] ?? 'pending'),
      departmentTag: _mapCategoryToDepartment(request['category'] ?? request['department_tag']),
      priorityTag: _capitalizePriority(request['priority']),
      unitId: request['unit_id'] ?? request['location'],
      requestTypeTag: request['request_type'] ?? 'Concern Slip',
      assignedStaff: request['assigned_to'] ?? request['assigned_staff'],
      staffDepartment: _mapCategoryToDepartment(request['category'] ?? request['staff_department']),
    );
  }

  WorkOrder _processMaintenanceToWorkOrder(Map<String, dynamic> task) {
    return WorkOrder(
      id: task['formatted_id'] ?? task['id'] ?? 'N/A',
      title: task['task_title'] ?? task['title'] ?? 'Maintenance Task',
      createdAt: _parseDate(task['scheduled_date'] ?? task['created_at']),
      updatedAt: _parseDate(task['updated_at']),
      statusTag: _capitalizeStatus(task['status'] ?? 'scheduled'),
      departmentTag: _mapCategoryToDepartment(task['category'] ?? task['department']),
      priorityTag: _capitalizePriority(task['priority']),
      unitId: task['location'],
      requestTypeTag: 'Maintenance',
      assignedStaff: task['assigned_to'] ?? task['assigned_staff'],
      staffDepartment: _mapCategoryToDepartment(task['category'] ?? task['department']),
    );
  }

  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    if (dateValue is DateTime) return dateValue;
    if (dateValue is String) {
      return DateTime.tryParse(dateValue) ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _capitalizeStatus(String status) {
    return status.split('_').map((word) =>
      word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  String _capitalizePriority(String? priority) {
    if (priority == null) return 'Medium';
    return priority[0].toUpperCase() + priority.substring(1).toLowerCase();
  }

  String? _mapCategoryToDepartment(String? category) {
    if (category == null) return null;

    final Map<String, String> categoryMapping = {
      'plumbing': 'Plumbing',
      'electrical': 'Electrical',
      'hvac': 'HVAC',
      'carpentry': 'Carpentry',
      'painting': 'Painting',
      'cleaning': 'Cleaning',
      'security': 'Security',
      'general': 'General',
    };

    return categoryMapping[category.toLowerCase()] ?? category;
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkOrderPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MaintenancePage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AnnouncementPage()),
        );
        break;
      case 4:
        if (_selectedIndex != 4) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CalendarPage()),
          );
        }
        break;
      case 5:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const InventoryPage()),
        );
        break;
    }

    setState(() => _selectedIndex = index);
  }

  // Helper to get tasks per day
  List<WorkOrder> _tasksFor(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _allWorkOrders.where((w) {
      final dt = w.createdAt;
      return DateTime(dt.year, dt.month, dt.day) == normalized;
    }).toList();
  }

  Widget _buildItem(WorkOrder w) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _getTypeColor(w.requestTypeTag).withOpacity(0.3), width: 2),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTypeColor(w.requestTypeTag).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              w.requestTypeTag == 'Maintenance'
                ? Icons.build_circle
                : Icons.assignment_outlined,
              color: _getTypeColor(w.requestTypeTag),
              size: 24,
            ),
          ),
          title: Text(
            w.title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${w.requestTypeTag} • Unit ${w.unitId ?? 'N/A'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (w.assignedStaff != null && w.assignedStaff!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        w.assignedStaff!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(w.statusTag),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              w.statusTag,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
         ),
      );

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
      case 'in progress':
      case 'in_progress':
        return Colors.blue;
      case 'done':
      case 'completed':
        return Colors.green;
      case 'on hold':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
        return const Color(0xFF00BCD4); // Cyan for maintenance
      case 'concern slip':
        return const Color(0xFFFF6B6B); // Red for concern slips
      case 'job service':
        return const Color(0xFF4CAF50); // Green for job services
      case 'work order':
        return const Color(0xFFFF9800); // Orange for work orders
      default:
        return kPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tasks = _tasksFor(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Calendar',
        notificationCount: _unreadNotifCount,
        onNotificationTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          );
          _loadUnreadNotifCount();
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: kMutedText),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCalendarData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // === Date timeline with header ===
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: EasyTheme(
                              data: EasyTheme.of(context).copyWith(
                                dayBorder: WidgetStatePropertyAll(
                                  BorderSide(color: Colors.grey.shade100),
                                ),
                              ),
                              child: EasyDateTimeLinePicker.itemBuilder(
                      controller: _controller,
                      firstDate: DateTime(2025, 1, 1),
                      lastDate: DateTime(2030, 12, 31),
                      focusedDate: _selectedDate,
                      itemExtent: 64.0,
                      headerOptions: HeaderOptions(
                        // ✅ Jump-to-today icon moved to the RIGHT side
                        headerBuilder: (context, date, onTap) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: onTap,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    DateFormat.yMMMM().format(date),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _controller.jumpToDate(DateTime.now()),
                                icon:
                                    const Icon(Icons.today, color: kPrimary),
                                tooltip: 'Jump to Today',
                              ),
                            ],
                          );
                        },
                      ),
                      monthYearPickerOptions: MonthYearPickerOptions(
                        initialCalendarMode: EasyDatePickerMode.month,
                        cancelText: 'Cancel',
                        confirmText: 'Confirm',
                      ),
                      itemBuilder: (context, date, isSelected, isDisabled,
                          isToday, onTap) {
                        final isSameDay = date.year == today.year &&
                            date.month == today.month &&
                            date.day == today.day;
                        final dayLabel =
                            DateFormat.E().format(date).toUpperCase();

                        final BoxDecoration decoration;
                        if (isSameDay) {
                          decoration = BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: const [kPrimary, kPrimaryDark],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          );
                        } else if (isSelected) {
                          decoration = BoxDecoration(
                            color: kPrimary.withOpacity(.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: kPrimary.withOpacity(.35)),
                          );
                        } else {
                          decoration = BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          );
                        }

                        final textColor = isSameDay
                            ? Colors.white
                            : (isSelected ? kPrimary : Colors.black87);

                        return InkResponse(
                          onTap: onTap,
                          highlightColor: Colors.transparent,
                          splashColor: kPrimary.withOpacity(.10),
                          child: Container(
                            width: 64,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            decoration: decoration,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      onDateChange: (date) =>
                          setState(() => _selectedDate = date),
                    ),
                  ),
                ),

                          const SizedBox(height: 8),

                          // === Tasks list ===
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: RefreshIndicator(
                                onRefresh: _loadCalendarData,
                                child: tasks.isEmpty
                                    ? ListView(
                                        children: const [
                                          SizedBox(height: 100),
                                          Center(
                                            child: Text(
                                              'No tasks for this day.',
                                              style: TextStyle(color: kMutedText),
                                            ),
                                          ),
                                        ],
                                      )
                                    : ListView.separated(
                                        itemCount: tasks.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (_, i) => _buildItem(tasks[i]),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
