import 'package:facilityfix/adminweb/disaster_prepardness/disasterpreparedness_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../maintenance_task/pop_up/assignstaff_popup.dart';
import '../../services/api_service_web.dart';
// Add import for ViewFileDialog if it's in a different file, e.g., import '../../path/to/view_file_dialog.dart';

class EarthquakeDialog extends StatefulWidget {
  final Map<String, dynamic> maintenanceData;
  final VoidCallback? onSaved;

  const EarthquakeDialog({
    super.key,
    required this.maintenanceData,
    this.onSaved,
  });
 
  @override
  State<EarthquakeDialog> createState() => _EarthquakeDialogState();

  static void show(BuildContext context, Map<String, dynamic> data, {VoidCallback? onSaved}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EarthquakeDialog(maintenanceData: data, onSaved: onSaved);
      },
    );
  }
}

class _EarthquakeDialogState extends State<EarthquakeDialog> {
  int? selectedTaskIndex;
  late List<Map<String, dynamic>> tasks;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Convert checklist_completed from backend to tasks format for the UI
    final checklistCompleted = widget.maintenanceData['checklist_completed'] as List?;

    if (checklistCompleted != null && checklistCompleted.isNotEmpty) {
      tasks = checklistCompleted.map((item) {
        return {
          'id': item['id'] ?? '',
          'name': item['task'] ?? 'Unnamed Task',
          'assigned': item['assigned_to'] ?? null,  // Use item-level assignment
          'rotation': widget.maintenanceData['recurrence_type'] ?? 'Quarterly',
          'status': (item['completed'] == true) ? 'Completed' : null,
          'completed': item['completed'] ?? false,
        };
      }).toList().cast<Map<String, dynamic>>();
    } else {
      tasks = List<Map<String, dynamic>>.from(_getDefaultTasks());
    }
  }

  List<Map<String, dynamic>> _getDefaultTasks() {
    return [
      {
        'name': 'Inspect structural components (columns, beams, walls, parapets, stairs)',
        'assigned': null,
        'rotation': 'Annually',
        'status': 'In Progress',
      },
      {
        'name': 'Inspect non-structural elements (ceilings, lights, piping, façade, racks)',
        'assigned': null,
        'rotation': 'Annually',
        'status': null,
      },
      {
        'name': 'Inspect anchorage of heavy equipment, tanks, UPS, gas cylinders',
        'assigned': null,
        'rotation': 'Annually',
        'status': null,
      },
      {
        'name': 'Test critical systems (fire protection, water/gas lines, elevators, emergency power)',
        'assigned': null,
        'rotation': 'Annually',
        'status': null,
      },
    ];
  }

  void _handleAssignTask() {
    // Assign individual checklist item
    if (selectedTaskIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a checklist item first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedTask = tasks[selectedTaskIndex!];
    _assignChecklistItem(selectedTask);
  }

  Future<void> _assignChecklistItem(Map<String, dynamic> item) async {
    // Show assignment dialog for the specific checklist item
    final taskData = {
      'id': '${widget.maintenanceData['id']}_${item['id']}',
      'task_id': widget.maintenanceData['id'],
      'checklist_item_id': item['id'],
      'title': item['name'] ?? 'Checklist Item',
      'priority': widget.maintenanceData['priority'] ?? 'high',
      'category': 'safety',
      'department': 'Safety Team',
      'scheduled_date': widget.maintenanceData['scheduled_date'],
    };

    AssignScheduleWorkDialog.show(
      context,
      taskData,
      isMaintenanceTask: true,
      onAssignmentComplete: () async {
        // After assignment, refresh the task data
        try {
          final response = await _apiService.getSpecialMaintenanceTask('earthquake');
          if (response['success'] == true && mounted) {
            final updatedTask = response['task'] as Map<String, dynamic>;
            final checklistCompleted = updatedTask['checklist_completed'] as List?;

            if (checklistCompleted != null && checklistCompleted.isNotEmpty) {
              setState(() {
                tasks = checklistCompleted.map((checklistItem) {
                  return {
                    'id': checklistItem['id'] ?? '',
                    'name': checklistItem['task'] ?? 'Unnamed Task',
                    'assigned': checklistItem['assigned_to'] ?? null,
                    'rotation': updatedTask['recurrence_type'] ?? 'Quarterly',
                    'status': (checklistItem['completed'] == true) ? 'Completed' : null,
                    'completed': checklistItem['completed'] ?? false,
                  };
                }).toList().cast<Map<String, dynamic>>();
              });
            }
          }
        } catch (e) {
          print('[v0] Error refreshing task data: $e');
        }

        // Also call parent callback
        widget.onSaved?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        constraints: const BoxConstraints(
          maxWidth: 1000,
          maxHeight: 700,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: _buildTitleSection(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                child: _buildTaskCard(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EARTHQUAKE SAFETY',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Task Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.maintenanceData['description'] ??
                      'Checklist for earthquake preparedness and safety inspections. Includes structural and non-structural evaluations, equipment anchorage, and critical systems testing to ensure facility resilience during seismic events.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.grey,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard() {
    final completedCount = tasks.where((t) => t['completed'] == true).length;
    final totalCount = tasks.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final overallStatus = completedCount == totalCount ? 'Completed' : 'In Progress';
    final assigned = tasks.isNotEmpty ? tasks.first['assigned'] ?? 'Unassigned' : 'Unassigned';
    final rotation = widget.maintenanceData['recurrence_type'] ?? 'Annually';

    return GestureDetector(
      onTap: () {
        // Assuming ViewFileDialog has a static show method similar to AssignScheduleWorkDialog
        ViewFileDialog.show(context, widget.maintenanceData);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(
          top: 17.23,
          left: 17.23,
          right: 17.23,
          bottom: 1.23,
        ),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1.23,
              color: const Color(0xFFE5E7E8),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'EARTHQUAKE SAFETY',
                                    style: const TextStyle(
                                      color: Color(0xFF0A0A0A),
                                      fontSize: 15,
                                      fontFamily: 'Arial',
                                      fontWeight: FontWeight.w400,
                                      height: 1.50,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  clipBehavior: Clip.antiAlias,
                                  decoration: ShapeDecoration(
                                    color: const Color(0xFFF57C00),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        overallStatus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            child: Text(
                              widget.maintenanceData['description'] ??
                                  'Checklist for earthquake preparedness and safety inspections.',
                              style: const TextStyle(
                                color: Color(0xFF626C70),
                                fontSize: 13,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: const BoxDecoration(),
                                        child: const Stack(),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        assigned,
                                        style: const TextStyle(
                                          color: Color(0xFF4A5154),
                                          fontSize: 12,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 15.99),
                                Container(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 14,
                                        height: 14,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: const BoxDecoration(),
                                        child: const Stack(),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        rotation,
                                        style: const TextStyle(
                                          color: Color(0xFF4A5154),
                                          fontSize: 12,
                                          fontFamily: 'Arial',
                                          fontWeight: FontWeight.w400,
                                          height: 1.50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 87.89,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Checklist Progress',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Color(0xFF626C70),
                            fontSize: 11,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$completedCount/$totalCount',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 16,
                            fontFamily: 'Arial',
                            fontWeight: FontWeight.w400,
                            height: 1.50,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 79.99,
                          height: 8,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE5E7E8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(41284500),
                            ),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              height: 8,
                              decoration: ShapeDecoration(
                                color: const Color(0xFF005CE7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(41284500),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: ShapeDecoration(
                color: const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 12),
                    child: Text(
                      'Checklist Items:',
                      style: TextStyle(
                        color: Color(0xFF626C70),
                        fontSize: 11,
                        fontFamily: 'Arial',
                        fontWeight: FontWeight.w400,
                        height: 1.50,
                      ),
                    ),
                  ),
                  ...tasks.take(3).map((task) {
                    final isCompleted = task['completed'] == true;
                    return Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: isCompleted
                                ? const BoxDecoration()
                                : ShapeDecoration(
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        width: 1.23,
                                        color: const Color(0xFF959FA3),
                                      ),
                                      borderRadius: BorderRadius.circular(41284500),
                                    ),
                                  ),
                            child: isCompleted
                                ? const Icon(Icons.check, size: 12, color: Colors.green)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task['name'] ?? '',
                              style: TextStyle(
                                color: isCompleted ? const Color(0xFF626C70) : const Color(0xFF191B1C),
                                fontSize: 12,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (tasks.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 12),
                      child: Text(
                        '+${tasks.length - 3} more items...',
                        style: const TextStyle(
                          color: Color(0xFF626C70),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.w400,
                          height: 1.50,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => context.go('/admin/disaster-preparedness/create'),
            icon: const Icon(
              Icons.add,
              size: 20,
            ),
            label: const Text(
              'New Task',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _handleAssignTask,
            icon: const Icon(
              Icons.edit_outlined,
              size: 20,
            ),
            label: const Text(
              'Assign Task',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
