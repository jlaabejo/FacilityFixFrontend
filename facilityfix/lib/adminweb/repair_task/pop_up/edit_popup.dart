import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Edit Dialog Types
enum EditDialogType { concernSlip, jobService, workOrderPermit }

/// Edit Dialog Widget
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
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EditDialog(
        type: type,
        task: task,
        onSave: onSave,
      ),
    );
  }
}

class _EditDialogState extends State<EditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  // Common fields
  DateTime? selectedDate;
  
  // WOP specific fields - date range without time
  DateTime? startDate;
  DateTime? endDate;
  final contractorNameController = TextEditingController();
  final companyController = TextEditingController();
  final contactNumberController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _initializeFields();
  }
  
  void _initializeFields() {
    // Initialize schedule date from task data
    _initializeScheduleDate();
    
    // Initialize WOP contractor fields if type is workOrderPermit
    if (widget.type == EditDialogType.workOrderPermit) {
      contractorNameController.text = widget.task['contractorName'] ?? 
                                       widget.task['rawData']?['contractor_name'] ?? '';
      companyController.text = widget.task['company'] ?? 
                              widget.task['rawData']?['company'] ?? '';
      contactNumberController.text = widget.task['contactNumber'] ?? 
                                     widget.task['rawData']?['contact_number'] ?? '';
      
      // Initialize date range for WOP
      _initializeWOPDateRange();
    }
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
        print('[EditDialog] Error parsing schedule date: $e');
      }
    }
  }
  
  void _initializeWOPDateRange() {
    // For WOP, parse date range from scheduled_date or scheduledDate field
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
        print('[EditDialog] Error parsing WOP date range: $e');
      }
    }
  }
  
  @override
  void dispose() {
    contractorNameController.dispose();
    companyController.dispose();
    contactNumberController.dispose();
    super.dispose();
  }
  
  String get _dialogTitle {
    switch (widget.type) {
      case EditDialogType.concernSlip:
        return 'Edit Concern Slip';
      case EditDialogType.jobService:
        return 'Edit Job Service';
      case EditDialogType.workOrderPermit:
        return 'Edit Work Order Permit';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: DialogContainer(
        maxWidth: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DialogHeader(
              title: _dialogTitle,
              onClose: _isSaving ? null : () => Navigator.of(context).pop(false),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: _buildEditFields(),
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
  
  Widget _buildEditFields() {
    switch (widget.type) {
      case EditDialogType.concernSlip:
        return _buildConcernSlipFields();
      case EditDialogType.jobService:
        return _buildJobServiceFields();
      case EditDialogType.workOrderPermit:
        return _buildWorkOrderPermitFields();
    }
  }
  
  /// Concern Slip Edit Fields
  Widget _buildConcernSlipFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditInfoCard(
          type: widget.type,
          taskId: widget.task['id'] ?? 'N/A',
        ),
        const SizedBox(height: 24),
        
        // Read-only details
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
        
        // Work Description
        EditSectionTitle(title: 'Work Description'),
        const SizedBox(height: 12),
        ReadOnlyTextArea(
          value: widget.task['description'] ?? 'No description available.',
        ),
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], thickness: 1),
        const SizedBox(height: 24),
        
        // Editable field
        EditDateTimePicker(
          label: 'Schedule Availability',
          selectedDate: selectedDate,
          onDateSelected: (date) => setState(() => selectedDate = date),
        ),
      ],
    );
  }
  
  /// Job Service Edit Fields
  Widget _buildJobServiceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditInfoCard(
          type: widget.type,
          taskId: widget.task['serviceId'] ?? widget.task['id'] ?? 'N/A',
        ),
        const SizedBox(height: 24),
        
        // Read-only details
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
        
        // Additional Notes
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
        
        // Editable field
        EditSectionTitle(title: 'Editable Field'),
        const SizedBox(height: 16),
        EditDateTimePicker(
          label: 'Preferred Schedule',
          selectedDate: selectedDate,
          onDateSelected: (date) => setState(() => selectedDate = date),
        ),
      ],
    );
  }
  
  /// Work Order Permit Edit Fields
  Widget _buildWorkOrderPermitFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditInfoCard(
          type: widget.type,
          taskId: widget.task['wopId'] ?? widget.task['id'] ?? 'N/A',
        ),
        const SizedBox(height: 24),
        
        // Read-only details
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
        
        // Specific Instructions (read-only)
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
        
        // Editable fields
        EditSectionTitle(title: 'Contractor Information'),
        const SizedBox(height: 16),
        
        EditTextField(
          controller: contractorNameController,
          label: 'Contractor Name',
          required: true,
        ),
        const SizedBox(height: 16),
        
        EditTextField(
          controller: companyController,
          label: 'Company',
          required: true,
        ),
        const SizedBox(height: 16),
        
        EditTextField(
          controller: contactNumberController,
          label: 'Contact Number',
          required: true,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        
        EditSectionTitle(title: 'Schedule Date Range'),
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
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // TODO: Implement actual save logic here based on widget.type
      print('[EditDialog] Saving ${widget.type} with date: $selectedDate');
      if (widget.type == EditDialogType.workOrderPermit) {
        print('[EditDialog] Contractor: ${contractorNameController.text}');
        print('[EditDialog] Company: ${companyController.text}');
        print('[EditDialog] Contact: ${contactNumberController.text}');
        print('[EditDialog] Date Range: $startDate to $endDate');
      }
      
      if (mounted) {
        widget.onSave?.call();
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved successfully'),
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

/// Dialog Container
class DialogContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DialogContainer({
    super.key,
    required this.child,
    this.maxWidth = 700,
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

/// Dialog Header
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

/// Dialog Footer
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

/// Edit Info Card
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

/// Edit Section Title
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

/// Read Only Field
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

/// Read Only Text Area
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

/// Edit Text Field
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

/// Edit Date Time Picker (for CS and JS - with time)
class EditDateTimePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final Function(DateTime) onDateSelected;

  const EditDateTimePicker({
    super.key,
    required this.label,
    required this.selectedDate,
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
                      InkWell(
                        onTap: () => _selectDateTime(context),
                        child: Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: state.hasError ? Colors.red : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate != null
                              ? DateFormat('MMM d, yyyy h:mm a').format(selectedDate!)
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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedDate != null
            ? TimeOfDay.fromDateTime(selectedDate!)
            : const TimeOfDay(hour: 9, minute: 0),
      );

      if (pickedTime != null) {
        onDateSelected(DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        ));
      }
    }
  }
}

/// Edit Date Range Picker (for WOP - dates only, no time)
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
                  InkWell(
                    onTap: onTap,
                    child: Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: state.hasError ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? DateFormat('MMM d, yyyy').format(selectedDate)
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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12),
    );

    if (pickedDate != null) {
      onStartDateSelected(pickedDate);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2030, 12),
    );

    if (pickedDate != null) {
      onEndDateSelected(pickedDate);
    }
  }
}