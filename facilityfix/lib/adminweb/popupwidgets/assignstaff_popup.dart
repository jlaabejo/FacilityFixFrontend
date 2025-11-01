import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_services.dart';
import '../services/api_service.dart' as admin_api;
import '../services/round_robin_assignment_service.dart';

class AssignScheduleWorkDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onAssignmentComplete;
  final bool isMaintenanceTask;

  const AssignScheduleWorkDialog({
    super.key,
    required this.task,
    this.onAssignmentComplete,
    this.isMaintenanceTask = false,
  });

  @override
  State<AssignScheduleWorkDialog> createState() =>
      _AssignScheduleWorkDialogState();

  static void show(
    BuildContext context,
    Map<String, dynamic> task, {
    VoidCallback? onAssignmentComplete,
    bool isMaintenanceTask = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AssignScheduleWorkDialog(
          task: task,
          onAssignmentComplete: onAssignmentComplete,
          isMaintenanceTask: isMaintenanceTask,
        );
      },
    );
  }
}

class _AssignScheduleWorkDialogState extends State<AssignScheduleWorkDialog> {
  final _formKey = GlobalKey<FormState>();
  final APIService _apiService = APIService();
  final admin_api.ApiService _adminApiService = admin_api.ApiService();
  final RoundRobinAssignmentService _roundRobinService = RoundRobinAssignmentService();
  bool _formValid = false;
  bool _isLoading = false;
  bool _isAssigning = false;

  String? selectedStaffId;
  String? selectedStaffName;
  DateTime? selectedDate;
  final TextEditingController notesController = TextEditingController();

  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _filteredStaffList = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    notesController.addListener(_revalidate);
    _loadStaffMembers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _revalidate());
  }

  Future<void> _loadStaffMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? taskCategory = widget.task['category']?.toString().toLowerCase();
      String? department;

      // Map AI-classified categories to main departments
      // Only 4 departments available: carpentry, electrical, masonry, plumbing
      // API expects lowercase department names
      switch (taskCategory) {
        case 'electrical':
          department = 'electrical';
          break;
        case 'plumbing':
          department = 'plumbing';
          break;
        case 'carpentry':
          department = 'carpentry';
          break;
        case 'masonry':
          department = 'masonry';
          break;
        // Map HVAC (others) to electrical - HVAC work often involves electrical systems
        case 'hvac':
          department = 'electrical';
          break;
        // Map pest control (others) to masonry - structural issues
        case 'pest control':
        case 'pest_control':
          department = 'masonry';
          break;
        // Map maintenance/general to null to show all available staff
        case 'maintenance':
        case 'general':
        case 'other':
          department = null; // Show all available staff from all 4 departments
          break;
        // For unknown categories, show all available staff
        default:
          department = null; // Will fetch all available staff from all departments
      }

      final staffData = await _apiService.getStaffMembers(
        department: department,
        availableOnly: true,
      );

      setState(() {
        _staffList = staffData;
        _filteredStaffList = List.from(_staffList);
        _isLoading = false;
      });

      print('[AssignStaff] Loaded ${_staffList.length} staff members');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load staff members: $e';
        _isLoading = false;
      });
      print('[AssignStaff] Error loading staff: $e');
    }
  }

  void _revalidate() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (ok != _formValid) setState(() => _formValid = ok);
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  String _getStaffDisplayName(Map<String, dynamic> staff) {
    final firstName = staff['first_name'] ?? '';
    final lastName = staff['last_name'] ?? '';
    final department = staff['staff_department'] ?? staff['department'] ?? 'General';
    final userId = staff['user_id'] ?? staff['id'] ?? '';

    String name = '$firstName $lastName'.trim();
    if (name.isEmpty) name = 'Staff Member';

    return '$name - $department ($userId)';
  }

  String _getStaffId(Map<String, dynamic> staff) {
    return staff['user_id'] ?? staff['id'] ?? '';
  }

  String _getStaffInitials(Map<String, dynamic> staff) {
    final firstName = staff['first_name'] ?? '';
    final lastName = staff['last_name'] ?? '';

    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();

    return initials.isNotEmpty ? initials : 'SM';
  }

  Color _getStaffAvatarColor(Map<String, dynamic> staff) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF97316), // Orange
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFA855F7), // Purple
    ];

    final name = '${staff['first_name'] ?? ''} ${staff['last_name'] ?? ''}'.trim();
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }

  Widget _buildStaffAvatar(Map<String, dynamic> staff, {double size = 32}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStaffAvatarColor(staff),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getStaffInitials(staff),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAssignHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskInfo(),
                      const SizedBox(height: 24),
                      _buildUrgencyChip(widget.task['priority'] ?? 'Medium'),
                      const SizedBox(height: 32),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[600], fontSize: 14))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildStaffDropdown()),
                          const SizedBox(width: 24),
                          Expanded(child: _buildDatePicker()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildNotesSection(),
                    ],
                  ),
                ),
              ),
            ),
            _buildAssignFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 24, bottom: 16),
      child: Row(
        children: [
          const Text('Assign & Schedule Work', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
          const Spacer(),
          IconButton(onPressed: _isAssigning ? null : () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.grey, size: 24), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
        ],
      ),
    );
  }

  Widget _buildTaskInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task: ${widget.task['id'] ?? 'N/A'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(widget.task['title'] ?? 'No Title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Category: ${widget.task['department'] ?? 'General'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String priority) {
    Color bgColor;
    Color textColor;
    switch (priority.toLowerCase()) {
      case 'high':
      case 'critical':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'medium':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF8F00);
        break;
      case 'low':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        break;
      default:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF8F00);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Text('$priority Priority', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildStaffDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assign Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 12),
        if (_isLoading)
          Container(
            height: 50,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          )
        else
          DropdownButtonFormField<String>(
            value: selectedStaffId,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              hintText: _filteredStaffList.isEmpty ? 'No staff available' : 'Select Staff...',
            ),
            selectedItemBuilder: (BuildContext context) {
              return _filteredStaffList.map((staff) {
                final staffId = _getStaffId(staff);
                if (selectedStaffId == staffId) {
                  final firstName = staff['first_name'] ?? '';
                  final lastName = staff['last_name'] ?? '';
                  String name = '$firstName $lastName'.trim();
                  if (name.isEmpty) name = 'Staff Member';

                  return Row(
                    children: [
                      _buildStaffAvatar(staff, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }).toList();
            },
            items: _filteredStaffList.map((staff) {
              final staffId = _getStaffId(staff);
              final firstName = staff['first_name'] ?? '';
              final lastName = staff['last_name'] ?? '';
              final department = staff['staff_department'] ?? staff['department'] ?? 'General';

              String name = '$firstName $lastName'.trim();
              if (name.isEmpty) name = 'Staff Member';

              return DropdownMenuItem(
                value: staffId,
                child: Row(
                  children: [
                    _buildStaffAvatar(staff, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            department,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: _filteredStaffList.isEmpty ? null : (value) {
              setState(() {
                selectedStaffId = value;
                final staff = _filteredStaffList.firstWhere((s) => _getStaffId(s) == value);
                selectedStaffName = _getStaffDisplayName(staff);
              });
              _revalidate();
            },
            validator: (value) => value == null || value.isEmpty ? 'Please select a staff member' : null,
          ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Work Order Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 12),
        FormField<DateTime>(
          validator: (_) {
            if (selectedDate == null) return 'Please pick a date';
            final today = DateTime.now();
            final floor = DateTime(today.year, today.month, today.day);
            if (selectedDate!.isBefore(floor)) return 'Date can\'t be in the past';
            return null;
          },
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _selectDate(context).then((_) => _revalidate()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: state.hasError ? Colors.red : Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: state.hasError ? Colors.red : Colors.blue[600], size: 20),
                      const SizedBox(width: 12),
                      Text(selectedDate != null ? _fmtDate(selectedDate!) : 'DD / MM / YY', style: TextStyle(color: selectedDate != null ? Colors.black87 : (state.hasError ? Colors.red : Colors.grey[500]), fontSize: 14)),
                    ],
                  ),
                ),
              ),
              if (state.hasError) ...[const SizedBox(height: 6), Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12))],
            ],
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().substring(2);
    return '$dd / $mm / $yy';
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Internal Notes (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 12),
        TextFormField(
          controller: notesController,
          maxLines: 6,
          decoration: InputDecoration(hintText: 'Enter Notes....', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            if (v.trim().length < 5) return 'Add a bit more detail or leave blank';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAssignFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: _isAssigning ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[600], 
              side: BorderSide(color: Colors.blue[600]!), 
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          Row(
            children: [
              // Auto-Assign Button
              ElevatedButton(
                onPressed: _isAssigning ? null : _handleAutoAssign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600], 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
                  elevation: 0
                ),
                child: _isAssigning
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Row(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          Icon(Icons.autorenew, size: 18), 
                          SizedBox(width: 8), 
                          Text('Auto-Assign', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
                        ]
                      ),
              ),
              const SizedBox(width: 16),
              // Manual Assign Button
              ElevatedButton(
                onPressed: (_formValid && !_isAssigning) ? _handleSaveAndAssign : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600], 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), 
                  elevation: 0
                ),
                child: _isAssigning
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : const Row(
                        mainAxisSize: MainAxisSize.min, 
                        children: [
                          Icon(Icons.save, size: 18), 
                          SizedBox(width: 8), 
                          Text('Save & Assign Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500))
                        ]
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030, 12));
    if (picked != null && picked != selectedDate) setState(() => selectedDate = picked);
  }

  // Auto-assign handler using Round Robin
  Future<void> _handleAutoAssign() async {
    setState(() => _isAssigning = true);

    try {
      // Get the department/category from the task
      final category = widget.task['category']?.toString().toLowerCase() ?? 
                      widget.task['department']?.toString().toLowerCase();
      
      // Map category to department (same logic as in _loadStaffMembers)
      String? department;
      switch (category) {
        case 'electrical':
          department = 'electrical';
          break;
        case 'plumbing':
          department = 'plumbing';
          break;
        case 'carpentry':
          department = 'carpentry';
          break;
        case 'masonry':
          department = 'masonry';
          break;
        case 'hvac':
          department = 'electrical';
          break;
        case 'pest control':
        case 'pest_control':
          department = 'masonry';
          break;
        default:
          department = null;
      }

      if (department == null) {
        throw Exception('Cannot auto-assign: No valid department found for this task');
      }

      print('[AssignStaff] Auto-assigning task with department: $department');

      // Determine task type and ID
      String taskType;
      String taskId;
      
      if (widget.isMaintenanceTask) {
        taskType = 'maintenance';
        taskId = widget.task['id'] ?? widget.task['task_id'] ?? '';
      } else {
        // Check if it's a job service or concern slip
        final serviceId = widget.task['serviceId'];
        if (serviceId != null && serviceId.toString().isNotEmpty) {
          taskType = 'job_service';
          taskId = serviceId.toString();
        } else {
          taskType = 'concern_slip';
          taskId = widget.task['rawData']?['id'] ?? 
                  widget.task['rawData']?['_doc_id'] ?? 
                  widget.task['id'] ?? '';
        }
      }

      if (taskId.isEmpty) {
        throw Exception('Task ID not found');
      }

      print('[AssignStaff] Auto-assigning $taskType: $taskId to department: $department');

      // Use round-robin service to auto-assign
      final assignedStaff = await _roundRobinService.autoAssignTask(
        taskId: taskId,
        taskType: taskType,
        department: department,
        notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
      );

      if (assignedStaff == null) {
        throw Exception('No available staff found in $department department');
      }

      final staffName = '${assignedStaff['first_name'] ?? ''} ${assignedStaff['last_name'] ?? ''}'.trim();

      print('[AssignStaff] Auto-assigned to: $staffName');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-assigned to $staffName successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onAssignmentComplete?.call();
      }
    } catch (e) {
      print('[AssignStaff] Auto-assignment failed: $e');
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-assign failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleSaveAndAssign() async {
    if (!_formValid || selectedStaffId == null) return;
    setState(() => _isAssigning = true);

    try {
      if (widget.isMaintenanceTask) {
        // Check if this is a checklist item assignment
        final checklistItemId = widget.task['checklist_item_id'];

        if (checklistItemId != null) {
          // Handle checklist item assignment
          final taskId = widget.task['task_id'];
          if (taskId == null) throw Exception('Task ID not found');

          print('[AssignStaff] Assigning staff $selectedStaffId to checklist item $checklistItemId');

          final result = await _adminApiService.assignStaffToChecklistItem(
            taskId,
            checklistItemId,
            selectedStaffId!,
          );

          print('[AssignStaff] Checklist item assignment successful: $result');

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Staff assigned successfully to checklist item'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            widget.onAssignmentComplete?.call();
          }
        } else {
          // Handle whole maintenance task assignment
          final taskId = widget.task['id'] ?? widget.task['task_id'];
          if (taskId == null) throw Exception('Maintenance task ID not found');

          print('[AssignStaff] Assigning staff $selectedStaffId to maintenance task $taskId');

          final result = await _adminApiService.assignStaffToMaintenanceTask(
            taskId,
            selectedStaffId!,
            scheduledDate: selectedDate,
            notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
          );

          print('[AssignStaff] Maintenance task assignment successful: $result');

          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Staff assigned successfully to maintenance task'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            widget.onAssignmentComplete?.call();
          }
        }
      } else {
        // Handle concern slip assignment (original logic)
        final concernSlipId = widget.task['rawData']?['id'] ?? widget.task['rawData']?['_doc_id'] ?? widget.task['id'];
        if (concernSlipId == null) throw Exception('Concern slip ID not found');

        print('[AssignStaff] Assigning staff $selectedStaffId to concern slip $concernSlipId');

        final result = await _apiService.assignStaffToConcernSlip(concernSlipId, selectedStaffId!);

        print('[AssignStaff] Assignment successful: $result');

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff assigned successfully to ${widget.task['id']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          widget.onAssignmentComplete?.call();
        }
      }
    } catch (e) {
      print('[AssignStaff] Assignment failed: $e');
      if (mounted) {
        setState(() => _isAssigning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign staff: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
