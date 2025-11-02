import 'dart:async';
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/services/chat_helper.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:facilityfix/widgets/modals.dart';

class StaffJobServiceDetailPage extends StatefulWidget {
  final String jobServiceId;

  const StaffJobServiceDetailPage({super.key, required this.jobServiceId});

  @override
  State<StaffJobServiceDetailPage> createState() =>
      _StaffJobServiceDetailPageState();
}

class _StaffJobServiceDetailPageState extends State<StaffJobServiceDetailPage> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _jobServiceData;
  String? _currentUserId;

  // Status update form controllers
  final _statusFormKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();

  // Form state
  String _selectedStatus = 'pending';
  bool _isSubmittingStatus = false;

  // Available status options for job services
  final List<String> _statusOptions = [
    'pending',
    'assigned',
    'in_progress',
    'completed',
    'cancelled',
    'on_hold',
  ];

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  @override
  void initState() {
    super.initState();
    // Ensure we have a valid default status
    if (!_statusOptions.contains(_selectedStatus)) {
      _selectedStatus = _statusOptions.isNotEmpty ? _statusOptions.first : 'pending';
    }
    _loadJobServiceData();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final profile = await AuthStorage.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _currentUserId = profile['uid'] ?? profile['user_id'];
      });
    }
  }

  Future<void> _loadJobServiceData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use staff role for API service
      final apiService = APIService(roleOverride: AppRole.staff);
      final data = await apiService.getJobServiceById(widget.jobServiceId);

      if (mounted) {
        setState(() {
          _jobServiceData = data;
          final currentStatus = (data['status'] ?? 'pending').toString();
          if (!_statusOptions.contains(currentStatus)) {
            _statusOptions.add(currentStatus);
          }
          _selectedStatus = currentStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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
    }
  }

  bool _isAssignedToCurrentUser() {
   return true;
  }

  Future<void> _updateJobServiceStatus(
    String newStatus, {
    String? notes,
  }) async {
    if (_statusOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No valid status options available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentStatus = _jobServiceData?['status'] ?? '';
    if (newStatus == currentStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status has not changed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingStatus = true;
      _selectedStatus = newStatus;
    });

    try {
      final apiService = APIService(roleOverride: AppRole.staff);
      final updated = await apiService.updateJobServiceStatus(
        jobServiceId: widget.jobServiceId,
        status: newStatus,
        notes: notes,
      );

      if (!mounted) return;

      setState(() {
        _isSubmittingStatus = false;
        _jobServiceData = updated;
        final updatedStatus = (updated['status'] ?? newStatus).toString();
        if (!_statusOptions.contains(updatedStatus)) {
          _statusOptions.add(updatedStatus);
        }
        _selectedStatus = updatedStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job service status updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmittingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _completeJobService() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Complete Job Service',
        message: 'Are you sure you want to mark this job service as completed? This action cannot be undone.',
        primaryText: 'Complete',
        secondaryText: 'Cancel',
        onPrimaryPressed: () => Navigator.of(context).pop(true),
        onSecondaryPressed: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmittingStatus = true);

    try {
      final apiService = APIService(roleOverride: AppRole.staff);
      await apiService.completeJobService(widget.jobServiceId);

      if (mounted) {
        setState(() => _isSubmittingStatus = false);
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (_) => CustomPopup(
            title: 'Success',
            message: 'Job service has been marked as completed.',
            primaryText: 'OK',
            onPrimaryPressed: () {
              Navigator.of(context).pop();
              // Refresh the job service data
              _loadJobServiceData();
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete job service: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    try {
      return DateTime.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  Future<void> _openStatusUpdateSheet() async {
    if (_jobServiceData == null || _statusOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update status right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String pendingStatus = _statusOptions.contains(_selectedStatus)
        ? _selectedStatus
        : _statusOptions.first;

    _notesController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: bottomInset + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: _statusFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Update Job Service Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: pendingStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusOptions
                          .map(
                            (status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status.replaceAll('_', ' ').toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => pendingStatus = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    fx.FilledButton(
                      label: _isSubmittingStatus ? 'Updating...' : 'Update Status',
                      backgroundColor: const Color(0xFF005CE7),
                      textColor: Colors.white,
                      withOuterBorder: false,
                      isDisabled: _isSubmittingStatus,
                      onPressed: () {
                        if (_isSubmittingStatus) return;
                        final notes = _notesController.text.trim();
                        Navigator.of(sheetContext).pop();
                        _updateJobServiceStatus(
                          pendingStatus,
                          notes: notes.isEmpty ? null : notes,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    _notesController.clear();
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'on_hold':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _openChat() async {
    if (_jobServiceData == null) return;
    
    final tenantId = _jobServiceData!['tenant_id']?.toString();
    if (tenantId == null || tenantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to start chat: Tenant information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ChatHelper.navigateToJobServiceChat(
      context: context,
      jobServiceId: widget.jobServiceId,
      isStaff: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: const BackButton(),
        title: 'Job Service Details',
        actions: _jobServiceData != null ? [
          ChatButton(
            onPressed: _openChat,
            isStaff: true,
          ),
          const SizedBox(width: 16),
        ] : null,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading job service',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        fx.FilledButton(
                          label: 'Retry',
                          backgroundColor: const Color(0xFF005CE7),
                          textColor: Colors.white,
                          withOuterBorder: false,
                          onPressed: _loadJobServiceData,
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        // Job Service Information
                        if (_jobServiceData != null) ...[
                          Container(
                            margin: const EdgeInsets.all(24),
                            child: JobServiceDetails(
                              id: _jobServiceData!['formatted_id'] ?? _jobServiceData!['id'] ?? '',
                              concernSlipId: _jobServiceData!['concern_slip_id'] ?? '',
                              createdAt: _parseDateTime(_jobServiceData!['created_at']) ?? DateTime.now(),
                              requestTypeTag: _jobServiceData!['request_type'] ?? 'Job Service',
                              statusTag: _jobServiceData!['status'] ?? 'pending',
                              requestedBy: _jobServiceData!['requested_by'] ?? _jobServiceData!['reported_by'] ?? '',
                              requestedByName: _jobServiceData!['requested_by_name'],
                              requestedByEmail: _jobServiceData!['requested_by_email'],
                              unitId: _jobServiceData!['unit_id'] ?? '',
                              updatedAt: _parseDateTime(_jobServiceData!['updated_at']),
                              priority: _jobServiceData!['priority'],
                              assignedStaff: _jobServiceData!['assigned_to'] ?? _jobServiceData!['assigned_staff'],
                              staffDepartment: _jobServiceData!['staff_department'],
                              scheduleAvailability: _jobServiceData!['schedule_availability'],
                              additionalNotes: _jobServiceData!['description'],
                              startedAt: _parseDateTime(_jobServiceData!['start_time']),
                              completedAt: _parseDateTime(_jobServiceData!['end_time']),
                              staffAttachments: _parseStringList(_jobServiceData!['attachments']),
                            ),
                          ),

                          // Status Update Section (only for assigned staff)
                          if (_isAssignedToCurrentUser()) ...[
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.assignment_turned_in,
                                        color: _getStatusColor(_jobServiceData!['status']),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Current Status: ${_formatStatus(_jobServiceData!['status'])}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusColor(_jobServiceData!['status']),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: fx.FilledButton(
                                          label: 'Update Status',
                                          backgroundColor: const Color(0xFF005CE7),
                                          textColor: Colors.white,
                                          withOuterBorder: false,
                                          onPressed: _openStatusUpdateSheet,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      if (_jobServiceData!['status'] != 'completed')
                                        Expanded(
                                          child: fx.FilledButton(
                                            label: 'Mark Complete',
                                            backgroundColor: const Color(0xFF10B981),
                                            textColor: Colors.white,
                                            withOuterBorder: false,
                                            onPressed: _completeJobService,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                        
                        const SizedBox(height: 100), // Extra space for bottom navigation
                      ],
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