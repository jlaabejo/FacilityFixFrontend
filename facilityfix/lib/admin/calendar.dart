// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/notification.dart';
import 'package:facilityfix/admin/view_details/workorder_details.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/models/cards.dart';
import 'package:facilityfix/services/api_services.dart';
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

  int _selectedIndex = 3;
  DateTime _selectedDate = DateTime.now();
  final EasyDatePickerController _controller = EasyDatePickerController();

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  // Real data from API
  List<WorkOrder> _allWorkOrders = [];
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
      
      // Fetch maintenance tasks
      final maintenanceTasks = await apiService.getAllMaintenance();

      if (mounted) {
        setState(() {
          _allWorkOrders = [];
          
          // Process concern slips into WorkOrder objects
          for (var slip in concernSlips) {
            _allWorkOrders.add(_processConcernSlipToWorkOrder(slip));
          }
          
          // Process maintenance tasks as WorkOrder objects
          for (var task in maintenanceTasks) {
            _allWorkOrders.add(_processMaintenanceToWorkOrder(task));
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

  WorkOrder _processConcernSlipToWorkOrder(Map<String, dynamic> slip) {
    return WorkOrder(
      id: slip['formatted_id'] ?? slip['id'] ?? 'N/A',
      title: slip['title'] ?? 'Concern Slip',
      createdAt: _parseDate(slip['created_at'] ?? slip['submitted_at']),
      updatedAt: _parseDate(slip['updated_at']),
      statusTag: _capitalizeStatus(slip['status'] ?? 'pending'),
      departmentTag: _mapCategoryToDepartment(slip['category']),
      priorityTag: _capitalizePriority(slip['priority']),
      unitId: slip['unit_id'] ?? slip['location'],
      requestTypeTag: 'Concern Slip',
      assignedStaff: slip['assigned_to'] ?? slip['assigned_staff'],
      staffDepartment: _mapCategoryToDepartment(slip['category']),
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
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
      setState(() => _selectedIndex = index);
    }
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
          onTap: () => _showTaskDetails(w),
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

  void _showTaskDetails(WorkOrder task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(task.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('ID:', task.id),
                _buildDetailRow('Type:', task.requestTypeTag),
                _buildDetailRow('Status:', task.statusTag),
                if (task.unitId != null) _buildDetailRow('Unit:', task.unitId!),
                if (task.departmentTag != null) _buildDetailRow('Department:', task.departmentTag!),
                if (task.priorityTag != null) _buildDetailRow('Priority:', task.priorityTag!),
                if (task.assignedStaff != null) _buildDetailRow('Assigned Staff:', task.assignedStaff!),
                _buildDetailRow('Created:', DateFormat('MMM d, yyyy HH:mm').format(task.createdAt)),
                if (task.updatedAt != null && task.updatedAt != task.createdAt)
                  _buildDetailRow('Updated:', DateFormat('MMM d, yyyy HH:mm').format(task.updatedAt!)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkOrderDetailsPage(
                      selectedTabLabel: task.requestTypeTag.toLowerCase().contains('concern') 
                        ? 'concern slip assigned' 
                        : 'work order details',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('View Details'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: kMutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tasks = _tasksFor(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Calendar',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCalendarData,
          ),
        ],
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
