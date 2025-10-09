import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/view_details.dart'; // RepairDetailsScreen, MaintenanceDetailsScreen
import 'package:facilityfix/widgets/buttons.dart' as custom_buttons;
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:intl/intl.dart';

class WorkOrderDetailsPage extends StatefulWidget {
  final String selectedTabLabel;
  final Map<String, dynamic>? concernSlipData;

  const WorkOrderDetailsPage({
    super.key,
    required this.selectedTabLabel,
    this.concernSlipData,
  });

  @override
  State<WorkOrderDetailsPage> createState() => _WorkOrderDetailsPageState();
}

class _WorkOrderDetailsPageState extends State<WorkOrderDetailsPage> {
  int _selectedIndex = 1;

  // ---- Full-details route labels (keep these consistent app-wide) ----
  static const String kJobServiceFull = 'job service full details';
  static const String kWorkPermitFull = 'work order permit full details';
  static const String kConcernAssignStaff = 'concern slip assign staff';

  // ---- Kind helpers ----
  String _normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  String get _kind {
    final s = _normalize(widget.selectedTabLabel);
    // Slight alias for safety
    return (s == 'job service request') ? 'job service' : s;
  }

  // Base type flags
  bool get _isConcernSlip => _kind.startsWith('concern slip');
  bool get _isJobService => _kind.startsWith('job service');
  bool get _isWorkPermit => _kind.startsWith('work order');
  bool get _isMaintenance => _kind == 'maintenance';

  // --- Granular status flags (used ONLY to decide if sticky actions show) ---
  // Concern Slip
  bool get _isConcernSlipPending => _kind == 'concern slip';
  bool get _isConcernSlipAssigned => _kind == 'concern slip assigned';
  bool get _isConcernSlipDone =>
      _kind == 'concern slip assessed' || _kind == 'assessed concern slip';

  // Job Service
  bool get _isJobServicePending => _kind == 'job service';
  bool get _isJobServiceAssigned => _kind == 'job service assigned';
  bool get _isJobServiceDone => _kind == 'job service assessed';

  // Work Order
  bool get _isWorkOrderPending => _kind == 'work order';
  bool get _isWorkOrderApproved => _kind == 'work order approved';

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Done';
      default:
        return 'Pending';
    }
  }

  String _formatPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }

  String _formatCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'plumbing':
        return 'Plumbing';
      case 'electrical':
        return 'Electrical';
      case 'hvac':
        return 'HVAC';
      case 'general':
        return 'General';
      default:
        return 'General';
    }
  }

  // ---------------- Bottom Nav ----------------
  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

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

  // ---------------- Builder for detail body ----------------
  Widget _buildDetails() {
    final data = widget.concernSlipData;

    switch (_kind) {
      // ---------- Concern Slip ----------
      // Concern Slip (Default)
      case 'concern slip':
        return ConcernSlipDetails(
          id: 'CS-2025-001',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Concern Slip',
          departmentTag: 'Plumbing',
          priority: 'High',
          statusTag: 'Assigned',
          requestedBy: 'Erika De Guzman',
          unitId: 'A 1001',
          scheduleAvailability: '2025-08-19T14:30:00',
          title: 'Leaking Faucet',
          description: 'Clogged drainage in the bathroom. Water backs up after 2–3 minutes.',
          attachments: const ['assets/images/upload1.png', 'assets/images/upload2.png'],
        );

      // Concern Slip (Assigned)
      case 'concern slip assigned':
        return ConcernSlipDetails(
          id: 'CS-2025-001',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Concern Slip',
          departmentTag: 'Plumbing',
          priority: 'High',
          statusTag: 'Assigned',
          requestedBy: 'Erika De Guzman',
          unitId: 'A 1001',
          scheduleAvailability: '2025-08-19T14:30:00',
          title: 'Leaking Faucet',
          description: 'Clogged drainage in the bathroom. Water backs up after 2–3 minutes.',
          attachments: const ['assets/images/upload1.png', 'assets/images/upload2.png'],
          assignedStaff: 'Juan Dela Cruz',
          staffDepartment: 'Plumbing',
          staffPhotoUrl: 'assets/images/avatar.png',
        );

      // Concern Slip (Assessed)
      case 'concern slip assessed':
        return ConcernSlipDetails(
          id: 'CS-2025-001',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Concern Slip',
          departmentTag: 'Plumbing',
          priority: 'High',
          statusTag: 'Assigned',
          requestedBy: 'Erika De Guzman',
          unitId: 'A 1001',
          scheduleAvailability: '2025-08-19T14:30:00',
          title: 'Leaking Faucet',
          description: 'Clogged drainage in the bathroom. Water backs up after 2–3 minutes.',
          attachments: const ['assets/images/upload1.png', 'assets/images/upload2.png'],
          assignedStaff: 'Juan Dela Cruz',
          staffDepartment: 'Plumbing',
          staffPhotoUrl: 'assets/images/avatar.png',
          assessedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          assessment: 'asdfghjkaajjsjsajs',
        );

      // ---------- Job Service ----------
      // Job Service (Default)
      case 'job service':
        return JobServiceDetails(
          id: 'JS-2025-031',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt:DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Job Service',
          priority: 'High',
          statusTag: 'Done',
          resolutionType: 'job_service',
          requestedBy: 'Erika De Guzman',
          concernSlipId: 'CS-2025-001',
          unitId: 'A 1001',
          scheduleAvailability: '2025-08-20T09:00:00',
          additionalNotes: 'Recurring issue, please expedite.',
        );

      // Job Service (Assigned)
      case 'job service assigned':
        return JobServiceDetails(
          id: 'JS-2025-031',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt:DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Job Service',
          priority: 'High',
          statusTag: 'Done',
          resolutionType: 'job_service',
          requestedBy: 'Erika De Guzman',
          concernSlipId: 'CS-2025-001',
          unitId: 'A 1001',
          scheduleAvailability: '2025-08-20T09:00:00',
          additionalNotes: 'Recurring issue, please expedite.',
          assignedStaff: 'Juan Dela Cruz',
          staffDepartment: 'Plumbing',
          staffPhotoUrl: 'assets/images/avatar.png',
        );

      // Job Service (On Hold)
      case 'job service on hold':
        return JobServiceDetails(
          id: 'JS-2025-031',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt:DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Job Service',
          priority: 'Low',
          statusTag: 'On Hld',
          resolutionType: 'job_service',
          requestedBy: 'Erika De Guzman',
          concernSlipId: 'CS-2025-001',
          unitId: 'A 1001',
          scheduleAvailability: '2025-08-20T09:00:00',
          additionalNotes: 'Recurring issue, please expedite.',
          assignedStaff: 'Juan Dela Cruz',
          staffDepartment: 'Plumbing',
          staffPhotoUrl: 'assets/images/avatar.png',
          startedAt:DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          materialsUsed: const ['PTFE tape', 'Gasket #12'],
        );

      // Job Service (Assessed)
      case 'job service assessed':
        return JobServiceDetails(
          id: 'JS-2025-031',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt:DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Job Service',
          priority: 'High',
          statusTag: 'Done',
          resolutionType: 'job_service',
          requestedBy: 'Erika De Guzman',
          concernSlipId: 'CS-2025-001',
          unitId: 'A 1001',
          scheduleAvailability: '2025-08-20T09:00:00',
          additionalNotes: 'Recurring issue, please expedite.',
          assignedStaff: 'Juan Dela Cruz',
          staffDepartment: 'Plumbing',
          staffPhotoUrl: 'assets/images/avatar.png',
          startedAt:DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          materialsUsed: const ['PTFE tape', 'Gasket #12'],
        );

      // ---------- Work Order Permit ----------
      // Work Order (Pending/Approved) — sample detail blocks preserved
      case 'work order':
        return WorkOrderPermitDetails(
          id: 'WO-2025-015',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Work Order',
          priority: 'Medium',
          statusTag: 'Approved',
          resolutionType: 'work_permit',
          requestedBy: 'Admin Jane',
          unitId: 'B 703',
          contractorNumber: '+63 912 345 6789',
          contractorCompany: 'XYZ Builders Inc.',
          workScheduleFrom: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          workScheduleTo: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          entryEquipments: 'Ladder, cordless drill, safety harness',
          approvedBy: 'Admin Jane',
          approvalDate: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          adminNotes: 'Work window strictly observed.', concernSlipId: 'sss', contractorName: 'sss',
        );

      case 'work order approved':
        return WorkOrderPermitDetails(
          id: 'WO-2025-015',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Work Order',
          priority: 'Medium',
          statusTag: 'Approved',
          resolutionType: 'work_permit',
          requestedBy: 'Admin Jane',
          unitId: 'B 703',
          contractorNumber: '+63 912 345 6789',
          contractorCompany: 'XYZ Builders Inc.',
          workScheduleFrom: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          workScheduleTo: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          entryEquipments: 'Ladder, cordless drill, safety harness',
          approvedBy: 'Admin Jane',
          approvalDate: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          adminNotes: 'Work window strictly observed.', concernSlipId: 'sss', contractorName: 'sss',
        );

      // ---------- Maintenance ----------
      case 'maintenance detail':
        return MaintenanceDetails(
          id: 'MT-2025-011',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Maintenance',
          departmentTag: 'Plumbing',
          priority: 'High',
          statusTag: 'Scheduled',
          requestedBy: 'System – Planned PM',
          scheduleDate: '2025-08-30T09:00:00',
          title: 'Quarterly Pipe Inspection',
          description: 'Check main and branch lines for leaks, corrosion, and pressure stability.',
          location: 'Tower A – 5th Floor',
          checklist: const [
            'Notify tenants on the affected floor',
            'Shut off water supply safely',
            'Inspect risers and branch lines for leaks/corrosion',
            'Check pressure and flow at endpoints',
            'Restore supply and monitor for 15 minutes',
            'Log findings and anomalies',
          ],
          assignedStaff: 'Juan Dela Cruz',
          staffDepartment: 'Plumbing',
          staffPhotoUrl: 'assets/images/avatar.png',
          attachments: const ['assets/images/upload3.png'],
        );

      case 'maintenance assessed':
        return MaintenanceDetails(
          id: 'MT-2025-011',
          createdAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          updatedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          requestTypeTag: 'Maintenance',
          departmentTag: 'Plumbing',
          priority: 'High',
          statusTag: 'Scheduled',
          requestedBy: 'System – Planned PM',
          scheduleDate: '2025-08-30T09:00:00',
          title: 'Quarterly Pipe Inspection',
          description: 'Check main and branch lines for leaks, corrosion, and pressure stability.',
          location: 'Tower A – 5th Floor',
          checklist: const [
            'Notify tenants on the affected floor',
            'Shut off water supply safely',
            'Inspect risers and branch lines for leaks/corrosion',
            'Check pressure and flow at endpoints',
            'Restore supply and monitor for 15 minutes',
            'Log findings and anomalies',
          ],
          assignedStaff: 'Juan Dela Cruz',
          staffDepartment: 'Plumbing',
          staffPhotoUrl: 'assets/images/avatar.png',
          assessedAt: DateFormat('MMMM d, yyyy').parse('August 22, 2025'),
          assessment: 'Hello',
          attachments: const ['assets/images/upload3.png'],
        );

      // ---------- Fallback ----------
      default:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Unsupported details type.'),
          ),
        );
    }
  }

  // ------------- Shared helpers (routing to FullDetails, etc.) -------------
  void _goToKind(String kind) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkOrderDetailsPage(selectedTabLabel: kind),
      ),
    );
  }

  Future<void> _showFullDetailsPopup({
    required String fullDetailsLabel,
    String title = 'Success',
    String message =
        'The action has been completed.\nTap below to open the full details.',
    String primaryText = 'Open Full Details',
  }) async {
    return showDialog(
      context: context,
      builder:
          (_) => CustomPopup(
                title: title,
                message: message,
                primaryText: primaryText,
                onPrimaryPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => WorkOrderPage()),
                  );
                },
              ),
    );
  }

  // ------------ Scenario actions (Reject / Assign / Accept) ------------
  Future<void> _openReject() async {
    final result = await showModalBottomSheet<RejectResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const RejectBottomSheet(),
    );
    if (!mounted || result == null) return;

    await showDialog(
      context: context,
      builder:
          (_) => CustomPopup(
                title: 'Request Rejected',
                message:
                    'Reason: ${result.reason}${(result.note?.isNotEmpty ?? false) ? "\n\nNote: ${result.note}" : ""}',
                primaryText: 'OK',
                onPrimaryPressed: () => Navigator.of(context).pop(),
              ),
    );
  }

  Future<void> _openAssign() async {
    final result = await showModalBottomSheet<AssignResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AssignStaffBottomSheet(),
    );
    if (!mounted || result == null) return;

    late final String fullDetailsLabel;
    if (_isConcernSlip || _isConcernSlipAssigned || _isConcernSlipDone) {
      fullDetailsLabel = kConcernAssignStaff;
    } else if (_isWorkPermit) {
      fullDetailsLabel = kWorkPermitFull;
    } else {
      fullDetailsLabel = kJobServiceFull;
    }

    await _showFullDetailsPopup(
      fullDetailsLabel: fullDetailsLabel,
      title: 'Assigned Successfully',
      message:
          'You’ve successfully assigned this request.\nTap below to view the full details.',
      primaryText: 'View Full Details',
    );
  }

  Future<void> _approvePermit() async {
    if (!mounted) return;
    await _showFullDetailsPopup(
      fullDetailsLabel: kWorkPermitFull,
      title: 'Permit Approved',
      message:
          'The Work Order Permit has been approved.\nTap below to view the full permit details.',
      primaryText: 'View Work Permit',
    );
  }

  // ------------- Sticky bars -------------
  Widget? _buildStickyBar() {
    // Concern Slip → show actions only on pending
    if (_isConcernSlip && _isConcernSlipPending) {
      return _barTwoButtons(
        left: custom_buttons.OutlinedPillButton(
          icon: Icons.delete_outline,
          label: 'Reject',
          onPressed: _openReject,
          height: 44,
          borderRadius: 24,
          foregroundColor: Colors.red,
          borderColor: Colors.red,
          backgroundColor: Colors.white,
          tooltip: 'Reject this request',
        ),
        right: custom_buttons.FilledButton(
          label: 'Assign Staff',
          icon: Icons.person_add_alt,
          onPressed: _openAssign,
          withOuterBorder: false,
          backgroundColor: const Color(0xFF005CE7),
        ),
      );
    }

    // Job Service → show actions only on pending
    if (_isJobService && _isJobServicePending) {
      return _barTwoButtons(
        left: custom_buttons.OutlinedPillButton(
          icon: Icons.delete_outline,
          label: 'Reject',
          onPressed: _openReject,
          height: 44,
          borderRadius: 24,
          foregroundColor: Colors.red,
          borderColor: Colors.red,
          backgroundColor: Colors.white,
          tooltip: 'Reject this job service',
        ),
        right: custom_buttons.FilledButton(
          label: 'Assign Staff',
          icon: Icons.person_add_alt,
          onPressed: _openAssign,
          withOuterBorder: false,
          backgroundColor: const Color(0xFF005CE7),
        ),
      );
    }

    // Work Order → show actions only when pending (hide on approved)
    if (_isWorkPermit && _isWorkOrderPending) {
      return _barTwoButtons(
        left: custom_buttons.OutlinedPillButton(
          icon: Icons.delete_outline,
          label: 'Reject',
          onPressed: _openReject,
          height: 44,
          borderRadius: 24,
          foregroundColor: Colors.red,
          borderColor: Colors.red,
          backgroundColor: Colors.white,
          tooltip: 'Reject this permit',
        ),
        right: custom_buttons.FilledButton(
          label: 'Accept',
          icon: Icons.check_circle_outline,
          onPressed: _approvePermit,
          withOuterBorder: false,
          backgroundColor: const Color(0xFF005CE7),
        ),
      );
    }

    // Maintenance: no sticky bar by default (read-only), customize if needed.
    if (_isMaintenance) return null;

    // All other cases: no sticky bar
    return null;
  }

  // NOTE: SafeArea(bottom:false) so we don't double-apply system inset.
  Widget _barSingleButton(Widget button) {
    return SafeArea(
      top: false,
      bottom: false, // <-- important to prevent extra white band
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16), // exact 8px bottom
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(children: [Expanded(child: button)]),
      ),
    );
  }

  // NOTE: SafeArea(bottom:false) so we don't double-apply system inset.
  Widget _barTwoButtons({required Widget left, required Widget right}) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sticky = _buildStickyBar();
    final bodyPadding = MediaQuery.of(context).padding;

    // Give the scroll body room so it's not hidden behind the sticky bar + navbar.
    // Tweak these if your sticky bar height changes.
    final extraBottom = sticky == null ? 24.0 : 120.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'View Details',
        leading: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: BackButton(),
        ),
        showMore: true,
        showHistory: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            extraBottom + bodyPadding.bottom,
          ),
          child: _buildDetails(),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sticky != null) sticky,
          NavBar(
            items: _navItems,
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}
