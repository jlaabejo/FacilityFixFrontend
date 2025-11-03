import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'assignstaff_popup.dart';
import '../../services/api_service.dart';

enum DetailMode { view, edit }

class MaintenanceTaskDetailDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final DetailMode mode;

  const MaintenanceTaskDetailDialog({
    super.key,
    required this.task,
    required this.mode,
  });

  static Future<Map<String, dynamic>?> showView(
    BuildContext context,
    Map<String, dynamic> task,
  ) {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => MaintenanceTaskDetailDialog(task: task, mode: DetailMode.view),
    );
  }

  static Future<Map<String, dynamic>?> showEdit(
    BuildContext context,
    Map<String, dynamic> task,
  ) {
    return showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => MaintenanceTaskDetailDialog(task: task, mode: DetailMode.edit),
    );
  }

  @override
  State<MaintenanceTaskDetailDialog> createState() => _MaintenanceTaskDetailDialogState();
}

class _MaintenanceTaskDetailDialogState extends State<MaintenanceTaskDetailDialog> {
  // --- Form + validity state
  final _formKey = GlobalKey<FormState>();
  bool _formValid = false;

  // --- API Service
  final _apiService = ApiService();

  // --- Inventory Requests State
  List<Map<String, dynamic>> _inventoryRequests = [];
  bool _loadingInventoryRequests = false;

  // --- Controllers
  late final TextEditingController _titleCtrl;
  late final TextEditingController _idCtrl;
  late final TextEditingController _dateRequestedCtrl;
  late final TextEditingController _priorityCtrl;
  late final TextEditingController _statusCtrl;
  late final TextEditingController _requestedByCtrl;
  late final TextEditingController _departmentCtrl;
  late final TextEditingController _buildingUnitCtrl;
  late final TextEditingController _scheduleCtrl;
  late final TextEditingController _maintenanceTypeCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _recurrenceCtrl;
  late final TextEditingController _descriptionCtrl;

  bool get _isEdit => widget.mode == DetailMode.edit;

  // --- Allowed values
  static const _priorities = ['High', 'Medium', 'Low'];
  static const _statuses = ['New', 'In Progress', 'Pending', 'Completed', 'Cancelled'];
  static const _types = ['Internal', 'External'];

  @override
  void initState() {
    super.initState();

    final t = widget.task;
    _titleCtrl = TextEditingController(text: t['task'] ?? t['title'] ?? '');
    _idCtrl = TextEditingController(text: t['id'] ?? '');
    _dateRequestedCtrl = TextEditingController(text: t['dateRequested'] ?? t['date'] ?? '');
    _priorityCtrl = TextEditingController(text: _coerceToAllowed(t['priority'], _priorities, 'Low'));
    _statusCtrl = TextEditingController(text: _coerceToAllowed(t['status'], _statuses, 'New'));
    _requestedByCtrl = TextEditingController(text: t['requestedBy'] ?? '');
    _departmentCtrl = TextEditingController(text: t['department'] ?? '');
    _buildingUnitCtrl = TextEditingController(text: t['buildingUnit'] ?? t['location'] ?? '');
    _scheduleCtrl = TextEditingController(text: t['schedule'] ?? t['date'] ?? '');
    _maintenanceTypeCtrl = TextEditingController(text: _coerceToAllowed(t['maintenanceType'], _types, 'Internal'));
    _locationCtrl = TextEditingController(text: t['location'] ?? '');
    _recurrenceCtrl = TextEditingController(text: t['recurrence'] ?? '');
    _descriptionCtrl = TextEditingController(text: t['description'] ?? '');

    // Re-validate whenever user types
    for (final c in [
      _titleCtrl,
      _idCtrl,
      _dateRequestedCtrl,
      _priorityCtrl,
      _statusCtrl,
      _requestedByCtrl,
      _departmentCtrl,
      _buildingUnitCtrl,
      _scheduleCtrl,
      _maintenanceTypeCtrl,
      _locationCtrl,
      _recurrenceCtrl,
      _descriptionCtrl,
    ]) {
      c.addListener(_revalidate);
    }

    // Initial validation pass after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revalidate();
      _loadInventoryRequests();
    });
  }

  Future<void> _loadInventoryRequests() async {
    final taskId = widget.task['id'];
    if (taskId == null || taskId.toString().isEmpty) return;

    setState(() => _loadingInventoryRequests = true);

    try {
      final response = await _apiService.getInventoryRequestsByMaintenanceTask(taskId.toString());
      if (response['success'] == true && mounted) {
        setState(() {
          _inventoryRequests = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _loadingInventoryRequests = false;
        });
      }
    } catch (e) {
      print('[v0] Error loading inventory requests: $e');
      if (mounted) {
        setState(() => _loadingInventoryRequests = false);
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _idCtrl,
      _dateRequestedCtrl,
      _priorityCtrl,
      _statusCtrl,
      _requestedByCtrl,
      _departmentCtrl,
      _buildingUnitCtrl,
      _scheduleCtrl,
      _maintenanceTypeCtrl,
      _locationCtrl,
      _recurrenceCtrl,
      _descriptionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _revalidate() {
    if (!_isEdit) return;
    final ok = _formKey.currentState?.validate() ?? false;
    if (ok != _formValid) setState(() => _formValid = ok);
  }

  String _coerceToAllowed(dynamic value, List<String> allowed, String fallback) {
    final v = (value ?? '').toString().trim();
    final hit = allowed.firstWhere(
      (o) => o.toLowerCase() == v.toLowerCase(),
      orElse: () => '',
    );
    return hit.isEmpty ? fallback : hit;
  }

  Map<String, dynamic> _buildUpdatedTask() {
    return {
      ...widget.task,
      'task': _titleCtrl.text.trim(),
      'title': _titleCtrl.text.trim(),
      'id': _idCtrl.text.trim(),
      'dateRequested': _dateRequestedCtrl.text.trim(),
      'priority': _priorityCtrl.text.trim(),
      'status': _statusCtrl.text.trim(),
      'requestedBy': _requestedByCtrl.text.trim(),
      'department': _departmentCtrl.text.trim(),
      'buildingUnit': _buildingUnitCtrl.text.trim(),
      'schedule': _scheduleCtrl.text.trim(),
      'maintenanceType': _maintenanceTypeCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'recurrence': _recurrenceCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
    };
  }

  bool get _canProceedToAssignInView {
    final status = (widget.task['status'] ?? '').toString().toLowerCase();
    final type = (widget.task['maintenanceType'] ?? 'Internal').toString().toLowerCase();
    return status == 'new' && type == 'internal';
  }

  // --- Validators
  String? _required(String? v, {String label = 'This field'}) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _idValidator(String? v) {
    final msg = _required(v, label: 'Reference Number');
    if (msg != null) return msg;
    final re = RegExp(r'^[A-Za-z0-9-]{3,}$');
    if (!re.hasMatch(v!.trim())) return 'Use letters, numbers, and dashes only';
    return null;
  }

  DateTime? _parseFlexibleDate(String v) {
    // Accept: YYYY-MM-DD, MM-DD-YYYY, MM/DD/YYYY
    final s = v.trim();
    final tryFormats = [
      RegExp(r'^\d{4}-\d{2}-\d{2}$'), // 2025-05-21
      RegExp(r'^\d{2}-\d{2}-\d{4}$'), // 05-21-2025
      RegExp(r'^\d{2}/\d{2}/\d{4}$'), // 05/21/2025
    ];
    if (!tryFormats.any((r) => r.hasMatch(s))) return null;

    try {
      if (s.contains('-') && s.indexOf('-') == 4) {
        // YYYY-MM-DD
        return DateTime.parse(s);
      } else {
        // MM-DD-YYYY or MM/DD/YYYY
        final parts = s.contains('-') ? s.split('-') : s.split('/');
        final mm = int.parse(parts[0]);
        final dd = int.parse(parts[1]);
        final yyyy = int.parse(parts[2]);
        return DateTime(yyyy, mm, dd);
      }
    } catch (_) {
      return null;
    }
  }

  String? _dateRequestedValidator(String? v) {
    final msg = _required(v, label: 'Date Requested');
    if (msg != null) return msg;
    final d = _parseFlexibleDate(v!);
    if (d == null) return 'Invalid date. Try YYYY-MM-DD or MM-DD-YYYY';
    // Date requested can be in the past; no further constraint
    return null;
  }

  String? _scheduleValidator(String? v) {
    final msg = _required(v, label: 'Schedule Date');
    if (msg != null) return msg;
    final d = _parseFlexibleDate(v!);
    if (d == null) return 'Invalid date. Try YYYY-MM-DD or MM-DD-YYYY';
    final today = DateTime.now();
    final todayFloor = DateTime(today.year, today.month, today.day);
    if (d.isBefore(todayFloor)) return 'Schedule must be today or later';
    return null;
  }

  String? _dropdownAllowed(String? v, List<String> allowed, String label) {
    final msg = _required(v, label: label);
    if (msg != null) return msg;
    final ok = allowed.any((o) => o.toLowerCase() == v!.toLowerCase());
    return ok ? null : 'Invalid $label';
  }

  String? _descriptionValidator(String? v) {
    final msg = _required(v, label: 'Description');
    if (msg != null) return msg;
    if (v!.trim().length < 10) return 'Please add at least 10 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.75,
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 760),
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
          children: [
            _header(context),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _isEdit ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title(),
                      const SizedBox(height: 24),
                      _detailsGrid(),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300], height: 1),
                      const SizedBox(height: 16),
                      _workDescription(),
                      const SizedBox(height: 24),
                      _inventoryRequestsSection(),
                    ],
                  ),
                ),
              ),
            ),
            
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _chipField(
    String label,
    String value,
    Widget Function(String) buildChip,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        buildChip(value),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 28, right: 12, top: 22, bottom: 14),
      child: Row(
        children: [
          Text(
            _isEdit ? 'Edit Maintenance Task' : 'Maintenance Task',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
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

  Widget _title() {
    if (_isEdit) {
      return TextFormField(
        controller: _titleCtrl,
        decoration: const InputDecoration(
          labelText: 'Task Title',
          border: OutlineInputBorder(),
        ),
        inputFormatters: [LengthLimitingTextInputFormatter(80)],
        validator: (v) => _required(v, label: 'Task Title'),
        onChanged: (_) => _revalidate(),
      );
    }
    return Text(
      widget.task['task'] ?? widget.task['title'] ?? 'No Title',
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
    );
  }

  Widget _detailsGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                label: 'REFERENCE NUMBER',
                child: TextFormField(
                  controller: _idCtrl,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9-]'))],
                  validator: _idValidator,
                ),
                displayWhenView: _idCtrl.text,
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _field(
                label: 'DATE REQUESTED',
                child: TextFormField(
                  controller: _dateRequestedCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'YYYY-MM-DD or MM-DD-YYYY',
                  ),
                  validator: _dateRequestedValidator,
                ),
                displayWhenView: _dateRequestedCtrl.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey[300], height: 1),
        const SizedBox(height: 16),

        // Priority & Status
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _isEdit
                  ? _dropdownField(
                      label: 'PRIORITY',
                      value: _priorityCtrl.text,
                      items: _priorities,
                      onChanged: (v) {
                        setState(() => _priorityCtrl.text = v ?? _priorityCtrl.text);
                        _revalidate();
                      },
                      validator: (v) => _dropdownAllowed(v, _priorities, 'Priority'),
                    )
                  : _chipField('PRIORITY', (widget.task['priority'] ?? 'Low').toString(), _priorityChip),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _isEdit
                  ? _dropdownField(
                      label: 'STATUS',
                      value: _statusCtrl.text,
                      items: _statuses,
                      onChanged: (v) {
                        setState(() => _statusCtrl.text = v ?? _statusCtrl.text);
                        _revalidate();
                      },
                      validator: (v) => _dropdownAllowed(v, _statuses, 'Status'),
                    )
                  : _chipField('STATUS', (widget.task['status'] ?? 'New').toString(), _statusChip),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Requested By & Department
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                label: 'REQUESTED BY',
                child: TextFormField(
                  controller: _requestedByCtrl,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  validator: (v) => _required(v, label: 'Requested By'),
                ),
                displayWhenView: _requestedByCtrl.text,
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _field(
                label: 'DEPARTMENT',
                child: TextFormField(
                  controller: _departmentCtrl,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  validator: (v) => _required(v, label: 'Department'),
                ),
                displayWhenView: _departmentCtrl.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Building/Unit & Schedule
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                label: 'BLDG & UNIT / LOCATION',
                child: TextFormField(
                  controller: _buildingUnitCtrl,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                  validator: (v) => _required(v, label: 'Location'),
                ),
                displayWhenView: _buildingUnitCtrl.text,
              ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _field(
                label: 'SCHEDULE AVAILABILITY / DATE',
                child: TextFormField(
                  controller: _scheduleCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'YYYY-MM-DD or MM-DD-YYYY',
                  ),
                  validator: _scheduleValidator,
                ),
                displayWhenView: _scheduleCtrl.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Maintenance Type & Recurrence
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _isEdit
                  ? _dropdownField(
                      label: 'MAINTENANCE TYPE',
                      value: _maintenanceTypeCtrl.text,
                      items: _types,
                      onChanged: (v) {
                        setState(() => _maintenanceTypeCtrl.text = v ?? _maintenanceTypeCtrl.text);
                        _revalidate();
                      },
                      validator: (v) => _dropdownAllowed(v, _types, 'Maintenance Type'),
                    )
                  : _field(
                      label: 'MAINTENANCE TYPE',
                      displayWhenView: _maintenanceTypeCtrl.text,
                    ),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: _field(
                label: 'RECURRENCE',
                child: TextFormField(
                  controller: _recurrenceCtrl,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                ),
                displayWhenView: _recurrenceCtrl.text.isEmpty ? '—' : _recurrenceCtrl.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Label + child in edit, or label + text in view
  Widget _field({required String label, Widget? child, String? displayWhenView}) {
    if (_isEdit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _labelStyle),
          const SizedBox(height: 8),
          if (child != null) child,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        Text(
          (displayWhenView ?? '—').isEmpty ? '—' : displayWhenView!,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: items.firstWhere((e) => e.toLowerCase() == value.toLowerCase(), orElse: () => items.first),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
          validator: validator,
        ),
      ],
    );
  }

  TextStyle get _labelStyle => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
        letterSpacing: 0.5,
      );

  Widget _workDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Work Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 12),
        if (_isEdit)
          TextFormField(
            controller: _descriptionCtrl,
            maxLines: 6,
            decoration: const InputDecoration(
              alignLabelWithHint: true,
              hintText: 'Describe the work...',
              border: OutlineInputBorder(),
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(600)],
            validator: _descriptionValidator,
          )
        else
          Text(
            _descriptionCtrl.text.isEmpty ? '—' : _descriptionCtrl.text,
            style: TextStyle(fontSize: 15, height: 1.6, color: Colors.grey[800]),
          ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_isEdit) ...[
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _formValid
                  ? () {
                      _formKey.currentState?.save();
                      final updated = _buildUpdatedTask();
                      Navigator.of(context).pop(updated);
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _formValid
                  ? () {
                      _formKey.currentState?.save();
                      final updated = _buildUpdatedTask();
                      Navigator.of(context).pop(updated);
                      AssignScheduleWorkDialog.show(context, updated);
                    }
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
              child: const Text('Next'),
            ),
          ] else ...[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            const Spacer(),
            if (_canProceedToAssignInView)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  AssignScheduleWorkDialog.show(context, widget.task);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
                child: const Text('Next'),
              ),
          ],
        ],
      ),
    );
  }

  // Chips
  Widget _priorityChip(String priority) {
    Color bgColor;
    Color textColor;
    switch (priority.toLowerCase()) {
      case 'high':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'medium':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF8F00);
        break;
      default:
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)),
      child: Text(priority, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    Color bg, fg;
    if (s == 'in progress') {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFFF8F00);
    } else if (s == 'completed') {
      bg = const Color(0xFFE8F5E8);
      fg = const Color(0xFF2E7D32);
    } else if (s == 'cancelled') {
      bg = const Color(0xFFF5F5F5);
      fg = const Color(0xFF616161);
    } else if (s == 'new' || s == 'pending') {
      bg = const Color(0xFFE3F2FD);
      fg = const Color(0xFF1976D2);
    } else {
      bg = const Color(0xFFE8F4FD);
      fg = const Color(0xFF1976D2);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _inventoryRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey[300], height: 1),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.grey[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Inventory Requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            if (_loadingInventoryRequests)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_inventoryRequests.isEmpty && !_loadingInventoryRequests)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
                const SizedBox(width: 12),
                Text(
                  'No inventory requests linked to this maintenance task',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          )
        else if (_inventoryRequests.isNotEmpty)
          ...List.generate(_inventoryRequests.length, (index) {
            final request = _inventoryRequests[index];
            return _inventoryRequestCard(request);
          }),
      ],
    );
  }

  Widget _inventoryRequestCard(Map<String, dynamic> request) {
    final itemName = request['item_name'] ?? 'Unknown Item';
    final quantity = request['quantity_requested'] ?? request['quantity'] ?? 0;
    final status = request['status'] ?? 'pending';
    final purpose = request['purpose'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (purpose.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        purpose,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildInventoryStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.numbers, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Quantity: $quantity',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      case 'approved':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'denied':
      case 'rejected':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFD32F2F);
        break;
      case 'fulfilled':
      case 'completed':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
