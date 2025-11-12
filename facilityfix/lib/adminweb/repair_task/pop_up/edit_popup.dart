import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/utils/ui_format.dart';

/// Edit Dialog Types
enum EditDialogType { concernSlip, jobService, workOrderPermit }

/// Base Edit Dialog Widget (kept for backward compatibility)
class EditDialog extends StatefulWidget {
  final EditDialogType type;
  final Map<String, dynamic> task;
  final VoidCallback? onSave;

  const EditDialog({
    super.key,
    required this.type,
    required this.task,
    this.onSave,
  });

  @override
  State<EditDialog> createState() => _EditDialogState();

  static Future<bool?> show(
    BuildContext context, {
    required EditDialogType type,
    required Map<String, dynamic> task,
    VoidCallback? onSave,
  }) {
    // Route to specific dialog based on type
    switch (type) {
      case EditDialogType.concernSlip:
        return ConcernSlipEditDialog.show(context, task: task, onSave: onSave);
      case EditDialogType.jobService:
        return JobServiceEditDialog.show(context, task: task, onSave: onSave);
      case EditDialogType.workOrderPermit:
        return WorkOrderPermitEditDialog.show(context, task: task, onSave: onSave);
    }
  }
}

class _EditDialogState extends State<EditDialog> {
  @override
  Widget build(BuildContext context) {
    // This should never be displayed, but kept for compatibility
    return const SizedBox.shrink();
  }
}

// ============================================================================
// CONCERN SLIP EDIT DIALOG
// ============================================================================

class ConcernSlipEditDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onSave;

  const ConcernSlipEditDialog({
    super.key,
    required this.task,
    this.onSave,
  });

  @override
  State<ConcernSlipEditDialog> createState() => _ConcernSlipEditDialogState();

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> task,
    VoidCallback? onSave,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConcernSlipEditDialog(
        task: task,
        onSave: onSave,
      ),
    );
  }
}

class _ConcernSlipEditDialogState extends State<ConcernSlipEditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  DateTime? selectedDate; // start
  DateTime? selectedEndDate; // optional end

  @override
  void initState() {
    super.initState();
    _initializeScheduleDate();
  }

  void _initializeScheduleDate() {
    final scheduleAvailability = widget.task['dateRequested'] ??
        widget.task['schedule'] ?? widget.task['rawData']?['schedule_availability'];

    if (scheduleAvailability == null) return;

    final s = scheduleAvailability.toString();
    try {
      if (s.contains('T')) {
        // ISO with time - treat as start
        selectedDate = DateTime.tryParse(s);
        selectedEndDate = null;
      } else if (s.contains(' - ')) {
        final parts = s.split(' - ');
  // Try parse full start datetime
  selectedDate = DateFormat('MMM d, yyyy h:mm a').parse(parts[0].trim());

        // Try parse end as time only first, then full datetime
        try {
          final right = parts[1].trim();
          final t = DateFormat('h:mm a').parse(right);
          if (selectedDate != null) {
            selectedEndDate = DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
              t.hour,
              t.minute,
            );
          }
        } catch (_) {
          try {
            selectedEndDate = DateFormat('MMM d, yyyy h:mm a').parse(parts[1].trim());
          } catch (_) {
            selectedEndDate = null;
          }
        }
        // If the parsed end is before the start, do not auto-correct; let user fix it in the UI.
      } else if (s.contains('-')) {
        // Fallback ISO date without time e.g., 2023-09-01
        final parts = s.split('-');
        if (parts.length >= 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            selectedDate = DateTime(y, m, d, 9, 0);
            selectedEndDate = null;
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: DialogContainer(
        maxWidth: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(
              title: 'Edit Concern Slip',
              onClose: _isSaving ? null : () => Navigator.of(context).pop(false),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: _buildFields(),
                ),
              ),
            ),
            DialogFooter(
              onCancel: _isSaving ? null : () => Navigator.of(context).pop(false),
              onSave: _isSaving ? null : _handleSave,
              isSaving: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditInfoCard(
          type: EditDialogType.concernSlip,
          taskId: widget.task['id'] ?? 'N/A',
        ),
        const SizedBox(height: 24),
        
        EditSectionTitle(title: 'Request Details'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ReadOnlyField(
                label: 'REQUESTED BY',
                value: widget.task['rawData']?['reported_by'] ?? widget.task['requestedBy'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ReadOnlyField(
                label: 'DEPARTMENT',
                value: widget.task['department'] ?? 'N/A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ReadOnlyField(
                label: 'BUILDING & UNIT NO.',
                value: widget.task['buildingUnit'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ReadOnlyField(
                label: 'PRIORITY',
                value: widget.task['priority'] ?? 'Low',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1),
        const SizedBox(height: 24),
        
        EditSectionTitle(title: 'Work Description'),
        const SizedBox(height: 12),
        ReadOnlyTextArea(
          value: widget.task['description'] ?? 'No description available.',
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1),
        const SizedBox(height: 24),
        
        EditDateTimePicker(
          label: 'Schedule Availability',
          selectedDate: selectedDate,
          selectedEndDate: selectedEndDate,
          onDateSelected: (start, end) => setState(() {
            selectedDate = start;
            selectedEndDate = end;
          }),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final api = APIService();
      final concernId = widget.task['rawData']?['id'] ?? widget.task['id'] ?? widget.task['_doc_id'];
      
      if (concernId != null && selectedDate != null) {
        await api.updateConcernSlip(
          concernSlipId: concernId.toString(),
          scheduleAvailability: selectedDate!.toIso8601String(),
        );
      }
      
      if (mounted) {
        widget.onSave?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Concern slip updated successfully'),
            backgroundColor: Color(0xFF38A169),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ============================================================================
// JOB SERVICE EDIT DIALOG
// ============================================================================

class JobServiceEditDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onSave;

  const JobServiceEditDialog({
    super.key,
    required this.task,
    this.onSave,
  });

  @override
  State<JobServiceEditDialog> createState() => _JobServiceEditDialogState();

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> task,
    VoidCallback? onSave,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => JobServiceEditDialog(
        task: task,
        onSave: onSave,
      ),
    );
  }
}

class _JobServiceEditDialogState extends State<JobServiceEditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  DateTime? selectedDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    _initializeScheduleDate();
  }

  void _initializeScheduleDate() {
    final scheduleAvailability = widget.task['dateRequested'] ?? 
                                 widget.task['schedule'] ?? 
                                 widget.task['rawData']?['schedule_availability'];
    if (scheduleAvailability != null && scheduleAvailability.isNotEmpty) {
      try {
        final s = scheduleAvailability.toString();
        if (s.contains('T')) {
          selectedDate = DateTime.parse(s);
        } else if (s.contains(' - ')) {
          final parts = s.split(' - ');
          try {
            selectedDate = DateFormat('MMM d, yyyy h:mm a').parse(parts[0].trim());
          } catch (_) {
            try {
              final d = DateFormat('MMM d, yyyy').parse(parts[0].trim());
              selectedDate = DateTime(d.year, d.month, d.day, 9, 0);
            } catch (_) {}
          }
        } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
          final parts = s.split('-');
          selectedDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
            9,
            0,
          );
        }
      } catch (e) {
        print('[JobServiceEditDialog] Error parsing schedule date: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: DialogContainer(
        maxWidth: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(
              title: 'Edit Job Service',
              onClose: _isSaving ? null : () => Navigator.of(context).pop(false),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: _buildFields(),
                ),
              ),
            ),
            DialogFooter(
              onCancel: _isSaving ? null : () => Navigator.of(context).pop(false),
              onSave: _isSaving ? null : _handleSave,
              isSaving: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditInfoCard(
          type: EditDialogType.jobService,
          taskId: widget.task['serviceId'] ?? widget.task['id'] ?? 'N/A',
        ),
        const SizedBox(height: 24),
        
        EditSectionTitle(title: 'Service Details'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ReadOnlyField(
                label: 'REQUESTED BY',
                value: widget.task['requestedBy'] ?? widget.task['created_by'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ReadOnlyField(
                label: 'DEPARTMENT',
                value: widget.task['department'] ?? 'N/A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ReadOnlyField(
                label: 'BUILDING & UNIT NO.',
                value: widget.task['buildingUnit'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ReadOnlyField(
                label: 'PRIORITY',
                value: widget.task['priority'] ?? 'Low',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1),
        const SizedBox(height: 24),
        
        if (widget.task['additionalNotes'] != null || widget.task['rawData']?['additional_notes'] != null) ...[
          EditSectionTitle(title: 'Additional Notes'),
          const SizedBox(height: 12),
          ReadOnlyTextArea(
            value: widget.task['additionalNotes'] ?? widget.task['rawData']?['additional_notes'] ?? 'N/A',
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 24),
        ],
        
        EditSectionTitle(title: 'Schedule Availability'),
        const SizedBox(height: 12),
        EditDateTimePicker(
          label: 'Schedule Availability',
          selectedDate: selectedDate,
          selectedEndDate: selectedEndDate,
          onDateSelected: (start, end) => setState(() {
            selectedDate = start;
            selectedEndDate = end;
          }),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final api = APIService();
      final jobId = widget.task['serviceId'] ?? widget.task['id'] ?? widget.task['rawData']?['id'];
      
      if (jobId != null && selectedDate != null) {
        await api.updateJobService(
          jobServiceId: jobId.toString(),
          scheduleAvailability: selectedDate!.toIso8601String(),
        );
      }
      
      if (mounted) {
        widget.onSave?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job service updated successfully'),
            backgroundColor: Color(0xFF38A169),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ============================================================================
// WORK ORDER PERMIT EDIT DIALOG
// ============================================================================

class WorkOrderPermitEditDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback? onSave;

  const WorkOrderPermitEditDialog({
    super.key,
    required this.task,
    this.onSave,
  });

  @override
  State<WorkOrderPermitEditDialog> createState() => _WorkOrderPermitEditDialogState();

  static Future<bool?> show(
    BuildContext context, {
    required Map<String, dynamic> task,
    VoidCallback? onSave,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WorkOrderPermitEditDialog(
        task: task,
        onSave: onSave,
      ),
    );
  }
}

class _WorkOrderPermitEditDialogState extends State<WorkOrderPermitEditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  DateTime? startDate;
  DateTime? endDate;
  // Support up to 3 contractor entries
  final List<TextEditingController> contractorNameControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> contractorEmailControllers = List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> contractorContactControllers = List.generate(3, (_) => TextEditingController());

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    // Initialize contractor fields (support multiple shapes)
    try {
      // 1) If there's a structured 'contractors' array in task/rawData, use it
      List<dynamic>? contractors;
      if (widget.task['contractors'] is List) contractors = widget.task['contractors'] as List<dynamic>?;
      contractors ??= widget.task['rawData']?['contractors'] as List<dynamic>?;

      if (contractors != null && contractors.isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          if (i < contractors.length) {
            final c = contractors[i];
            if (c is Map) {
              contractorNameControllers[i].text = (c['name'] ?? c['company'] ?? c['contractor_name'] ?? '').toString();
              contractorEmailControllers[i].text = (c['email'] ?? c['contact_email'] ?? '').toString();
              contractorContactControllers[i].text = (c['phone'] ?? c['contact_number'] ?? c['phone_number'] ?? '').toString();
            } else {
              contractorNameControllers[i].text = c.toString();
            }
          }
        }
      } else {
        // 2) Fallback: individual fields may exist (contractorName, contractorName2, ...)
        for (int i = 0; i < 3; i++) {
          // Try common keys with and without numbering
          String? n;
          if (i == 0) {
            n = widget.task['contractorName']?.toString() ?? widget.task['rawData']?['contractor_name']?.toString();
          } else {
            n = widget.task['contractorName${i + 1}']?.toString() ?? widget.task['rawData']?['contractor_name_${i + 1}']?.toString();
          }
          contractorNameControllers[i].text = n ?? '';

          String? e;
          if (i == 0) e = widget.task['email']?.toString() ?? widget.task['rawData']?['email']?.toString();
          else e = widget.task['email${i + 1}']?.toString() ?? widget.task['rawData']?['email_${i + 1}']?.toString();
          contractorEmailControllers[i].text = e ?? '';

          String? p;
          if (i == 0) p = widget.task['contactNumber']?.toString() ?? widget.task['rawData']?['contact_number']?.toString();
          else p = widget.task['contactNumber${i + 1}']?.toString() ?? widget.task['rawData']?['contact_number_${i + 1}']?.toString();
          contractorContactControllers[i].text = p ?? '';
        }
      }
    } catch (_) {
      // ignore parsing issues - leave empty defaults
    }

    
    // Initialize date range
    _initializeWOPDateRange();
  }

  void _initializeWOPDateRange() {
    final scheduledDate = widget.task['scheduledDate'] ?? widget.task['rawData']?['scheduled_date'];
    if (scheduledDate != null && scheduledDate.isNotEmpty) {
      try {
        final s = scheduledDate.toString();
        if (s.contains(' - ')) {
          final parts = s.split(' - ');
          try {
            startDate = DateFormat('MMM d, yyyy').parse(parts[0].trim());
            endDate = DateFormat('MMM d, yyyy').parse(parts[1].trim());
          } catch (_) {
            try {
              startDate = DateTime.parse(parts[0].trim());
              endDate = DateTime.parse(parts[1].trim());
            } catch (_) {}
          }
        } else if (s.contains('T')) {
          startDate = DateTime.parse(s);
          endDate = startDate;
        } else {
          try {
            startDate = DateFormat('MMM d, yyyy').parse(s);
            endDate = startDate;
          } catch (_) {}
        }
      } catch (e) {
        print('[WorkOrderPermitEditDialog] Error parsing date range: $e');
      }
    }
  }

  @override
  void dispose() {
    for (final c in contractorNameControllers) c.dispose();
    for (final c in contractorEmailControllers) c.dispose();
    for (final c in contractorContactControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: DialogContainer(
        maxWidth: 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(
              title: 'Edit Work Order Permit',
              onClose: _isSaving ? null : () => Navigator.of(context).pop(false),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: _buildFields(),
                ),
              ),
            ),
            DialogFooter(
              onCancel: _isSaving ? null : () => Navigator.of(context).pop(false),
              onSave: _isSaving ? null : _handleSave,
              isSaving: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditInfoCard(
          type: EditDialogType.workOrderPermit,
          taskId: widget.task['wopId'] ?? widget.task['id'] ?? 'N/A',
        ),
        const SizedBox(height: 24),
        
        EditSectionTitle(title: 'Request Details'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ReadOnlyField(
                label: 'REQUESTED BY',
                value: widget.task['requestedBy'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ReadOnlyField(
                label: 'DEPARTMENT',
                value: widget.task['department'] ?? 'N/A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ReadOnlyField(
                label: 'BUILDING & UNIT NO.',
                value: widget.task['buildingUnit'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ReadOnlyField(
                label: 'STATUS',
                value: widget.task['status'] ?? 'Pending',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        if (widget.task['specificInstructions'] != null || widget.task['rawData']?['specific_instructions'] != null) ...[
          EditSectionTitle(title: 'Notes'),
          const SizedBox(height: 12),
          ReadOnlyTextArea(
            value: widget.task['specificInstructions'] ?? widget.task['rawData']?['specific_instructions'] ?? 'N/A',
          ),
          const SizedBox(height: 24),
        ],
        
        Divider(color: Colors.grey[200], thickness: 1),
        const SizedBox(height: 24),
        
        EditSectionTitle(title: 'Contractor Information'),
        const SizedBox(height: 16),

        // Render up to 3 contractor input blocks
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Text(
            i == 0 ? 'Primary Contractor' : 'Contractor ${i + 1}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          EditTextField(
            controller: contractorNameControllers[i],
            label: 'Contractor / Company Name',
            required: i == 0,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 8),
          EditTextField(
            controller: contractorContactControllers[i],
            label: 'Contact Number',
            required: i == 0,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          EditTextField(
            controller: contractorEmailControllers[i],
            label: 'Email',
            required: i == 0,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 6),
          const Divider(color: Colors.grey, height: 1),
        ],
        const SizedBox(height: 16),
        
        EditSectionTitle(title: 'Schedule Date'),
        const SizedBox(height: 16),
        
        EditDateRangePicker(
          startDate: startDate,
          endDate: endDate,
          onStartDateSelected: (date) => setState(() => startDate = date),
          onEndDateSelected: (date) => setState(() => endDate = date),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final api = APIService();
      final permitId = widget.task['wopId'] ?? widget.task['permitId'] ?? widget.task['id'] ?? widget.task['rawData']?['id'];
      
      if (permitId != null) {
        await api.updateWorkOrder(
          workOrderId: permitId.toString(),
          workScheduleFrom: startDate?.toIso8601String(),
          workScheduleTo: endDate?.toIso8601String(),
        );
        
        for (int i = 0; i < 3; i++) {
          final name = contractorNameControllers[i].text;
          final email = contractorEmailControllers[i].text;
          final contact = contractorContactControllers[i].text;
          if (name.trim().isNotEmpty || email.trim().isNotEmpty || contact.trim().isNotEmpty) {
            print('[WorkOrderPermitEditDialog] Contractor ${i + 1}: $name | $email | $contact');
          }
        }
        print('[WorkOrderPermitEditDialog] Date Range: $startDate to $endDate');
      }
      
      if (mounted) {
        widget.onSave?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Work order permit updated successfully'),
            backgroundColor: Color(0xFF38A169),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ============================================================================
// SHARED UI COMPONENTS
// ============================================================================

class DialogContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DialogContainer({
    super.key,
    required this.child,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class DialogHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClose;

  const DialogHeader({
    super.key,
    required this.title,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 20, bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class DialogFooter extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool isSaving;

  const DialogFooter({
    super.key,
    this.onCancel,
    this.onSave,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              elevation: 0,
            ),
            child: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

class EditInfoCard extends StatelessWidget {
  final EditDialogType type;
  final String taskId;

  const EditInfoCard({
    super.key,
    required this.type,
    required this.taskId,
  });

  String get _typeLabel {
    switch (type) {
      case EditDialogType.concernSlip:
        return 'CS';
      case EditDialogType.jobService:
        return 'JS';
      case EditDialogType.workOrderPermit:
        return 'WOP';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, color: Colors.blue[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Editing $_typeLabel: $taskId',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditSectionTitle extends StatelessWidget {
  final String title;

  const EditSectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.8,
      ),
    );
  }
}

class ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class ReadOnlyTextArea extends StatelessWidget {
  final String value;

  const ReadOnlyTextArea({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

class EditTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType? keyboardType;
  final int maxLines;

  const EditTextField({
    super.key,
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}

class EditDateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final DateTime? selectedEndDate;
  final Function(DateTime start, DateTime? end) onDateSelected;

  const EditDateTimePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    this.selectedEndDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        FormField<DateTime>(
          validator: (_) {
            if (selectedDate == null) return 'Please select a date';
            final today = DateTime.now();
            final floor = DateTime(today.year, today.month, today.day);
            if (selectedDate!.isBefore(floor)) return 'Date cannot be in the past';
            if (selectedEndDate != null && selectedEndDate!.isBefore(selectedDate!)) return 'End time must be after start time';
            return null;
          },
          builder: (state) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _selectDateTime(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: state.hasError ? Colors.red : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: state.hasError ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
              selectedDate != null
                ? UiDateUtils.dateTimeRange(selectedDate!, selectedEndDate)
                : 'Select date and time',
                          style: TextStyle(
                            color: selectedDate != null
                                ? Colors.black87
                                : (state.hasError ? Colors.red : Colors.grey[500]),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.hasError) ...[
                const SizedBox(height: 6),
                Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _selectDateTime(BuildContext context) async {
    // Pick date first (only Mon-Sat)
    DateTime initial = selectedDate ?? DateTime.now();
    if (initial.weekday == DateTime.sunday) initial = initial.add(const Duration(days: 1));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12),
      selectableDayPredicate: (date) => date.weekday != DateTime.sunday,
    );

    if (pickedDate == null) return;

    // Pick start time
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: selectedDate != null ? TimeOfDay.fromDateTime(selectedDate!) : const TimeOfDay(hour: 9, minute: 0),
    );
    if (startTime == null) return;

    // Validate start time window (9:00 - 17:00)
    if (!_isWithinBusinessHours(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a time between 9:00 AM and 5:00 PM (Mon-Sat).')),
      );
      return;
    }

    // Pick end time (optional)
    final TimeOfDay initialEnd = TimeOfDay(hour: (startTime.hour < 16) ? startTime.hour + 1 : 17, minute: startTime.minute);
    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: selectedEndDate != null ? TimeOfDay.fromDateTime(selectedEndDate!) : initialEnd,
    );

    DateTime startDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, startTime.hour, startTime.minute);
    DateTime? endDateTime;

    if (endTime != null) {
      if (!_isWithinBusinessHours(endTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose an end time between 9:00 AM and 5:00 PM (Mon-Sat).')),
        );
        return;
      }
      endDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, endTime.hour, endTime.minute);

      if (!endDateTime.isAfter(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }
    }

    onDateSelected(startDateTime, endDateTime);
  }

  bool _isWithinBusinessHours(TimeOfDay t) {
    final int h = t.hour;
    final int m = t.minute;
    // allow 9:00 up to 17:00 (inclusive only at exact 17:00)
    final bool valid = (h > 9 && h < 17) || (h == 9) || (h == 17 && m == 0);
    return valid;
  }
}

class EditDateRangePicker extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime) onStartDateSelected;
  final Function(DateTime) onEndDateSelected;

  const EditDateRangePicker({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDateField(
                context,
                label: 'From Date',
                selectedDate: startDate,
                onTap: () => _selectStartDate(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateField(
                context,
                label: 'To Date',
                selectedDate: endDate,
                onTap: () => _selectEndDate(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return FormField<DateTime>(
      validator: (_) {
        if (selectedDate == null) return 'Required';
        if (label == 'To Date' && startDate != null && selectedDate.isBefore(startDate!)) {
          return 'Must be after start date';
        }
        return null;
      },
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: state.hasError ? Colors.red : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: state.hasError ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? (label == 'From Date' && startDate != null && endDate != null
                              ? UiDateUtils.formatDateRange(startDate!, endDate!)
                              : UiDateUtils.fullDate(selectedDate))
                          : 'Select date',
                      style: TextStyle(
                        color: selectedDate != null
                            ? Colors.black87
                            : (state.hasError ? Colors.red : Colors.grey[500]),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.hasError) ...[
            const SizedBox(height: 6),
            Text(
              state.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    DateTime initial = startDate ?? DateTime.now();
    if (initial.weekday == DateTime.sunday) initial = initial.add(const Duration(days: 1));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12),
      selectableDayPredicate: (date) => date.weekday != DateTime.sunday,
    );

    if (pickedDate != null) {
      onStartDateSelected(pickedDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    DateTime initial = endDate ?? startDate ?? DateTime.now();
    if (initial.weekday == DateTime.sunday) initial = initial.add(const Duration(days: 1));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2030, 12),
      selectableDayPredicate: (date) => date.weekday != DateTime.sunday,
    );

    if (pickedDate != null) {
      onEndDateSelected(pickedDate);
    }
  }
}