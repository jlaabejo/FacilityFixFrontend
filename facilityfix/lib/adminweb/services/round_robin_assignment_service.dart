import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Round-robin assignment service for automatic staff assignment
/// Maintains a pointer/index per department to ensure fair distribution of tasks
class RoundRobinAssignmentService {
  final ApiService _apiService = ApiService();
  
  // In-memory cache of department pointers
  static final Map<String, int> _departmentPointers = {};
  
  // SharedPreferences key prefix
  static const String _pointerKeyPrefix = 'rr_pointer_';
  
  /// Get the next available staff member for a department using round-robin
  /// Returns a map with staff details or null if no staff available
  Future<Map<String, dynamic>?> getNextStaffForDepartment(String department) async {
    try {
      // Fetch all available staff for this department
      final staffList = await _apiService.getStaffMembers(
        department: department,
        availableOnly: true,
      );
      
      if (staffList.isEmpty) {
        print('[RoundRobin] No available staff found for department: $department');
        return null;
      }
      
      // Get current pointer for this department
      final currentPointer = await _getDepartmentPointer(department);
      
      // Calculate next index (wrap around if needed)
      final nextIndex = currentPointer % staffList.length;
      
      // Get the staff member at this index
      final selectedStaff = staffList[nextIndex] as Map<String, dynamic>;
      
      // Increment and save the pointer for next assignment
      await _incrementDepartmentPointer(department, staffList.length);
      
      print('[RoundRobin] Assigned staff at index $nextIndex for department: $department');
      print('[RoundRobin] Staff: ${selectedStaff['first_name']} ${selectedStaff['last_name']}');
      
      return selectedStaff;
    } catch (e) {
      print('[RoundRobin] Error getting next staff for department $department: $e');
      return null;
    }
  }
  
  /// Assign a task to the next available staff member in the department
  /// Returns the assigned staff details or null if assignment failed
  Future<Map<String, dynamic>?> autoAssignTask({
    required String taskId,
    required String taskType, // 'concern_slip', 'job_service', 'work_order', 'maintenance'
    required String department,
    String? notes,
  }) async {
    try {
      // Get next staff member
      final staff = await getNextStaffForDepartment(department);
      
      if (staff == null) {
        print('[RoundRobin] No staff available for auto-assignment');
        return null;
      }
      
      final staffId = staff['user_id'] ?? staff['id'];
      if (staffId == null) {
        print('[RoundRobin] Staff member has no valid ID');
        return null;
      }
      
      // Assign based on task type
      try {
        switch (taskType.toLowerCase()) {
          case 'concern_slip':
            await _apiService.assignStaffToConcernSlip(
              taskId,
              staffId,
            );
            break;
            
          case 'job_service':
            await _apiService.assignStaffToJobService(
              taskId,
              staffId,
            );
            break;
            
          case 'work_order':
          case 'maintenance':
            await _apiService.assignStaffToWorkOrder(
              taskId,
              staffId,
              note: notes,
            );
            break;
            
          default:
            print('[RoundRobin] Unknown task type: $taskType');
            return null;
        }
        
        print('[RoundRobin] Successfully auto-assigned task $taskId to staff $staffId');
        return staff;
      } catch (e) {
        print('[RoundRobin] Assignment failed for task $taskId: $e');
        return null;
      }
    } catch (e) {
      print('[RoundRobin] Error in autoAssignTask: $e');
      return null;
    }
  }
  
  /// Get the current pointer index for a department
  Future<int> _getDepartmentPointer(String department) async {
    // First check in-memory cache
    if (_departmentPointers.containsKey(department)) {
      return _departmentPointers[department]!;
    }
    
    // Load from persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final pointer = prefs.getInt('$_pointerKeyPrefix$department') ?? 0;
      _departmentPointers[department] = pointer;
      return pointer;
    } catch (e) {
      print('[RoundRobin] Error loading pointer for $department: $e');
      return 0;
    }
  }
  
  /// Increment the pointer for a department and save it
  Future<void> _incrementDepartmentPointer(String department, int staffCount) async {
    try {
      final currentPointer = _departmentPointers[department] ?? 0;
      final newPointer = (currentPointer + 1) % staffCount;
      
      // Update in-memory cache
      _departmentPointers[department] = newPointer;
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_pointerKeyPrefix$department', newPointer);
      
      print('[RoundRobin] Updated pointer for $department: $currentPointer -> $newPointer');
    } catch (e) {
      print('[RoundRobin] Error saving pointer for $department: $e');
    }
  }
  
  /// Reset the pointer for a specific department
  Future<void> resetDepartmentPointer(String department) async {
    try {
      _departmentPointers[department] = 0;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_pointerKeyPrefix$department', 0);
      
      print('[RoundRobin] Reset pointer for department: $department');
    } catch (e) {
      print('[RoundRobin] Error resetting pointer for $department: $e');
    }
  }
  
  /// Reset all department pointers
  Future<void> resetAllPointers() async {
    try {
      _departmentPointers.clear();
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_pointerKeyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      print('[RoundRobin] Reset all department pointers');
    } catch (e) {
      print('[RoundRobin] Error resetting all pointers: $e');
    }
  }
  
  /// Get statistics about department assignments
  Future<Map<String, int>> getAssignmentStatistics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = <String, int>{};
      
      final keys = prefs.getKeys().where((key) => key.startsWith(_pointerKeyPrefix));
      for (final key in keys) {
        final department = key.replaceFirst(_pointerKeyPrefix, '');
        final pointer = prefs.getInt(key) ?? 0;
        stats[department] = pointer;
      }
      
      return stats;
    } catch (e) {
      print('[RoundRobin] Error getting statistics: $e');
      return {};
    }
  }
  
  /// Preview who would be assigned next for a department (without actually assigning)
  Future<Map<String, dynamic>?> previewNextAssignment(String department) async {
    try {
      final staffList = await _apiService.getStaffMembers(
        department: department,
        availableOnly: true,
      );
      
      if (staffList.isEmpty) {
        return null;
      }
      
      final currentPointer = await _getDepartmentPointer(department);
      final nextIndex = currentPointer % staffList.length;
      
      return staffList[nextIndex] as Map<String, dynamic>;
    } catch (e) {
      print('[RoundRobin] Error previewing next assignment: $e');
      return null;
    }
  }
}
