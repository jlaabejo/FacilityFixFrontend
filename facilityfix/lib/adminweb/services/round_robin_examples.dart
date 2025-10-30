import 'package:flutter/material.dart';
import '../services/round_robin_assignment_service.dart';

/// Example demonstrations of Round-Robin Assignment Service usage
/// This file shows various use cases and patterns

class RoundRobinExamples {
  final RoundRobinAssignmentService _rrService = RoundRobinAssignmentService();

  /// Example 1: Simple auto-assignment
  Future<void> example1_simpleAutoAssign() async {
    print('=== Example 1: Simple Auto-Assignment ===');
    
    final assignedStaff = await _rrService.autoAssignTask(
      taskId: 'CS-2025-00123',
      taskType: 'concern_slip',
      department: 'electrical',
    );
    
    if (assignedStaff != null) {
      print('✓ Task assigned to: ${assignedStaff['first_name']} ${assignedStaff['last_name']}');
    } else {
      print('✗ Assignment failed - no available staff');
    }
  }

  /// Example 2: Auto-assignment with notes
  Future<void> example2_autoAssignWithNotes() async {
    print('=== Example 2: Auto-Assignment with Notes ===');
    
    final assignedStaff = await _rrService.autoAssignTask(
      taskId: 'JS-2025-00456',
      taskType: 'job_service',
      department: 'plumbing',
      notes: 'Urgent: Customer reported water leak. Please prioritize.',
    );
    
    if (assignedStaff != null) {
      print('✓ Job service assigned with notes');
    }
  }

  /// Example 3: Preview next assignment before committing
  Future<void> example3_previewNextAssignment() async {
    print('=== Example 3: Preview Next Assignment ===');
    
    final nextStaff = await _rrService.previewNextAssignment('maintenance');
    
    if (nextStaff != null) {
      print('Next assignment in maintenance will go to:');
      print('  Name: ${nextStaff['first_name']} ${nextStaff['last_name']}');
      print('  Department: ${nextStaff['department']}');
      print('  User ID: ${nextStaff['user_id']}');
    }
  }

  /// Example 4: Get assignment statistics
  Future<void> example4_getStatistics() async {
    print('=== Example 4: Assignment Statistics ===');
    
    final stats = await _rrService.getAssignmentStatistics();
    
    print('Current rotation positions by department:');
    stats.forEach((department, pointer) {
      print('  $department: Position $pointer');
    });
  }

  /// Example 5: Reset specific department pointer
  Future<void> example5_resetDepartment() async {
    print('=== Example 5: Reset Department Pointer ===');
    
    // Reset electrical department back to start
    await _rrService.resetDepartmentPointer('electrical');
    print('✓ Electrical department pointer reset to 0');
    
    // Verify it was reset
    final stats = await _rrService.getAssignmentStatistics();
    print('  Current position: ${stats['electrical'] ?? 0}');
  }

  /// Example 6: Batch assignment for multiple tasks
  Future<void> example6_batchAssignment() async {
    print('=== Example 6: Batch Assignment ===');
    
    final tasks = [
      {'id': 'CS-2025-00101', 'type': 'concern_slip', 'dept': 'carpentry'},
      {'id': 'CS-2025-00102', 'type': 'concern_slip', 'dept': 'carpentry'},
      {'id': 'CS-2025-00103', 'type': 'concern_slip', 'dept': 'carpentry'},
    ];
    
    int successCount = 0;
    for (final task in tasks) {
      final result = await _rrService.autoAssignTask(
        taskId: task['id'] as String,
        taskType: task['type'] as String,
        department: task['dept'] as String,
      );
      
      if (result != null) {
        successCount++;
        print('✓ ${task['id']} → ${result['first_name']} ${result['last_name']}');
      }
    }
    
    print('Batch complete: $successCount/${tasks.length} tasks assigned');
  }

  /// Example 7: Error handling patterns
  Future<void> example7_errorHandling() async {
    print('=== Example 7: Error Handling ===');
    
    try {
      final result = await _rrService.autoAssignTask(
        taskId: 'INVALID-ID',
        taskType: 'concern_slip',
        department: 'nonexistent_department',
      );
      
      if (result == null) {
        print('⚠ No staff available in department');
        // Handle gracefully - maybe show dialog to admin
      } else {
        print('✓ Assignment successful');
      }
    } catch (e) {
      print('✗ Error during assignment: $e');
      // Log error, notify admin, etc.
    }
  }

  /// Example 8: Get next staff for department (without assigning)
  Future<void> example8_getNextStaffOnly() async {
    print('=== Example 8: Get Next Staff (No Assignment) ===');
    
    final nextStaff = await _rrService.getNextStaffForDepartment('electrical');
    
    if (nextStaff != null) {
      print('Next staff member in queue:');
      print('  ${nextStaff['first_name']} ${nextStaff['last_name']}');
      print('  ${nextStaff['email']}');
      
      // Note: This actually increments the pointer
      // Use previewNextAssignment() if you don't want to increment
    }
  }

  /// Example 9: Department-specific workflows
  Future<void> example9_departmentWorkflow() async {
    print('=== Example 9: Department-Specific Workflow ===');
    
    // High-priority electrical task
    print('Assigning high-priority electrical task...');
    final electricalStaff = await _rrService.autoAssignTask(
      taskId: 'CS-2025-00201',
      taskType: 'concern_slip',
      department: 'electrical',
      notes: 'HIGH PRIORITY - Power outage in Building A',
    );
    
    // Routine plumbing maintenance
    print('Assigning routine plumbing maintenance...');
    final plumbingStaff = await _rrService.autoAssignTask(
      taskId: 'MT-2025-00050',
      taskType: 'maintenance',
      department: 'plumbing',
      notes: 'Routine inspection - quarterly',
    );
    
    if (electricalStaff != null && plumbingStaff != null) {
      print('✓ Both tasks assigned successfully');
      print('  Electrical: ${electricalStaff['first_name']}');
      print('  Plumbing: ${plumbingStaff['first_name']}');
    }
  }

  /// Example 10: Reset all pointers (admin operation)
  Future<void> example10_resetAllPointers() async {
    print('=== Example 10: Reset All Department Pointers ===');
    
    // Get current stats before reset
    final beforeStats = await _rrService.getAssignmentStatistics();
    print('Before reset:');
    beforeStats.forEach((dept, pos) => print('  $dept: $pos'));
    
    // Reset everything
    await _rrService.resetAllPointers();
    
    // Get stats after reset
    final afterStats = await _rrService.getAssignmentStatistics();
    print('\nAfter reset:');
    print('  All departments reset to position 0');
    print('  Stats cleared: ${afterStats.isEmpty}');
  }
}

/// Widget example showing UI integration
class RoundRobinDemoWidget extends StatefulWidget {
  const RoundRobinDemoWidget({super.key});

  @override
  State<RoundRobinDemoWidget> createState() => _RoundRobinDemoWidgetState();
}

class _RoundRobinDemoWidgetState extends State<RoundRobinDemoWidget> {
  final RoundRobinAssignmentService _rrService = RoundRobinAssignmentService();
  Map<String, int> _stats = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final stats = await _rrService.getAssignmentStatistics();
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  Future<void> _previewNextForDepartment(String department) async {
    final staff = await _rrService.previewNextAssignment(department);
    if (staff != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Next: ${staff['first_name']} ${staff['last_name']} ($department)',
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _resetDepartment(String department) async {
    await _rrService.resetDepartmentPointer(department);
    await _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset $department pointer to 0'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Round-Robin Assignment Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh Statistics',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Department Assignment Positions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_stats.isEmpty)
                  const Text('No assignments yet. Use Auto-Assign to start!')
                else
                  ..._stats.entries.map((entry) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${entry.value}'),
                          ),
                          title: Text(entry.key.toUpperCase()),
                          subtitle: Text('Current position: ${entry.value}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility),
                                onPressed: () => _previewNextForDepartment(entry.key),
                                tooltip: 'Preview Next',
                              ),
                              IconButton(
                                icon: const Icon(Icons.restart_alt),
                                onPressed: () => _resetDepartment(entry.key),
                                tooltip: 'Reset to 0',
                              ),
                            ],
                          ),
                        ),
                      )),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _rrService.resetAllPointers();
                    await _loadStats();
                  },
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Reset All Departments'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
    );
  }
}
