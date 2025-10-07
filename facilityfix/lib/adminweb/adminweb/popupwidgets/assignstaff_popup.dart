import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AssignScheduleWorkDialog extends StatefulWidget {
  final Map<String, dynamic> task;

  const AssignScheduleWorkDialog({
    super.key,
    required this.task,
  });

  @override
  State<AssignScheduleWorkDialog> createState() => _AssignScheduleWorkDialogState();

  static void show(BuildContext context, Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AssignScheduleWorkDialog(task: task);
      },
    );
  }
}

class _AssignScheduleWorkDialogState extends State<AssignScheduleWorkDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _formValid = false;

  String? selectedStaff;
  DateTime? selectedDate;
  final TextEditingController notesController = TextEditingController();

  final List<String> staffList = [
    'John Smith - Plumber',
    'Maria Garcia - Electrician',
    'David Johnson - Maintenance',
    'Sarah Wilson - General Repair',
  ];

  void _revalidate() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (ok != _formValid) setState(() => _formValid = ok);
  }

  @override
  void initState() {
    super.initState();
    notesController.addListener(_revalidate);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revalidate());
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
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
                      _buildUrgencyChip(widget.task['priority'] ?? 'Medium'),
                      const SizedBox(height: 32),
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
          const Text(
            'Assign & Schedule Work',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$priority Urgency',
        style: const TextStyle(color: Color(0xFFFF8F00), fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStaffDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assign Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: selectedStaff,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Select Staff...',
          ),
          items: staffList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) {
            setState(() => selectedStaff = v);
            _revalidate();
          },
          validator: (v) => v == null || v.isEmpty ? 'Please select a staff member' : null,
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    // Use FormField to validate a custom date picker tile
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
            if (selectedDate!.isBefore(floor)) return 'Date can’t be in the past';
            return null;
          },
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _selectDate(context).then((_) => _revalidate()),
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
                        Icon(Icons.calendar_today, color: state.hasError ? Colors.red : Colors.blue[600], size: 20),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate != null ? _fmtDate(selectedDate!) : 'DD / MM / YY',
                          style: TextStyle(
                            color: selectedDate != null
                                ? Colors.black87
                                : (state.hasError ? Colors.red : Colors.grey[500]),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.hasError) ...[
                  const SizedBox(height: 6),
                  Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            );
          },
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
          decoration: InputDecoration(
            hintText: 'Enter Notes....',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          // Optional example: warn if too short when provided
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null; // optional
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
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[600],
              side: BorderSide(color: Colors.blue[600]!),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Back', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: _formValid ? _handleSaveAndAssign : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save, size: 18),
                SizedBox(width: 8),
                Text('Save & Assign Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  void _handleSaveAndAssign() {
    // You can perform backend calls here with selectedStaff, selectedDate, and notesController.text
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Work assigned to $selectedStaff on ${_fmtDate(selectedDate!)}'), backgroundColor: Colors.green),
    );
  }
}
