import 'package:facilityfix/admin/view_details/full_details.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/widgets/pop_up.dart';
import 'package:flutter/material.dart';

import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/view_details.dart'; // RepairDetailsScreen, MaintenanceDetailsScreen
import 'package:facilityfix/widgets/buttons.dart' as custom_buttons;

import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/inventory.dart';

class WorkOrderDetailsPage extends StatefulWidget {
  final String selectedTabLabel;

  const WorkOrderDetailsPage({
    super.key,
    required this.selectedTabLabel,
  });

  @override
  State<WorkOrderDetailsPage> createState() => _WorkOrderDetailsPageState();
}

class _WorkOrderDetailsPageState extends State<WorkOrderDetailsPage> {
  int _selectedIndex = 1;

  // ---- Full-details route labels (keep these consistent app-wide) ----
  static const String kJobServiceFull      = 'job service full details';
  static const String kWorkPermitFull      = 'work order permit full details';
  static const String kConcernAssignStaff  = 'concern slip assign staff';

  // ---- Kind helpers ----
  String _normalize(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');

  String get _kind {
    final s = _normalize(widget.selectedTabLabel);
    return (s == 'job service request') ? 'job service' : s;
  }

  bool get _isConcernSlip => _kind == 'concern slip';
  bool get _isAssessed    => _kind == 'assessed concern slip';
  bool get _isJobService  => _kind == 'job service';
  bool get _isWorkPermit  => _kind == 'work order permit';

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

  // --------------- Details content ---------------
  Widget _buildDetails() {
    switch (_kind) {
      case 'maintenance':
        return MaintenanceDetailsScreen(
          title: 'Light Inspection',
          maintenanceId: 'PM-GEN-LIGHT-001',
          status: 'In Progress',
          description:
              'Inspecting ceiling and emergency lighting. Check flicker, burnt bulbs, exposed wiring.',
          priority: 'High',
          location: 'Basement',
          dateCreated: 'June 15, 2025',
          recurrence: 'Every 1 month',
          startDate: 'July 30, 2025',
          nextDate: 'August 30, 2025',
          assigneeName: 'Juan Dela Cruz',
          assigneeRole: 'Plumber',
          checklist: const [
            'Visually inspect light conditions',
            'Test switch function',
            'Check emergency lights',
            'Replace burnt-out bulbs',
            'Log condition and report anomalies',
          ],
          attachments: const ['assets/images/upload3.png'],
          adminNote:
              'Emergency lights in basement often have moisture issues — check battery backups.',
        );

      // Concern Slip
      case 'concern slip':
        return RepairDetailsScreen(
          // Basic Information
          title: 'Leaking Faucet',
          requestId: 'REQ-2025-00123',
          statusTag: 'Pending',
          date: 'August 2, 2025',
          requestType: 'Concern Slip',

          // Tenant / Requester Details
          requestedBy: 'Erika De Guzman',
          unit: 'A 1001',
          scheduleAvailability: 'August 19, 2025',

          // Request Details
          priority: 'High',
          department: 'Plumbing',
          description:
              'Tenant reports a clogged drainage issue in the bathroom. Water drains slowly and backs up to the floor. Plunger attempt failed.',

          attachments: const [
            'assets/images/upload1.png',
            'assets/images/upload2.png',
          ],
        );

      // Assessed Concern Slip  (Assessment & Recommendation visible)
      case 'assessed concern slip':
        return RepairDetailsScreen(
          // Basic Information
          title: 'Leaking Faucet',
          requestId: 'REQ-2025-00123',
          statusTag: 'In Review',
          date: 'August 2, 2025',
          requestType: 'Assessed Concern Slip',

          // Tenant / Requester Details
          requestedBy: 'Erika De Guzman',
          unit: 'A 1001',

          // Request Details
          priority: 'High',
          department: 'Plumbing',
          description:
              'Tenant reports slow drainage, backs up to the floor. Initial plunger attempt failed.',

          // Assessed by
          assigneeName: 'Juan Dela Cruz',
          assigneeRole: 'Plumber',
          assessment:
              'Observed mineral build-up and partial blockage. Needs trap clearing and line flush.',
          recommendation:
              'Proceed with service or secure work permit if contractor is required.',

          attachments: const [
            'assets/images/upload1.png',
            'assets/images/upload2.png',
          ],
        );

      // Job Service
      case 'job service':
        return RepairDetailsScreen(
          // Basic Information
          title: 'Leaking Faucet',
          requestId: 'JS-25-00123',
          statusTag: 'Pending',
          date: 'August 2, 2025',
          requestType: 'Job Service',

          // Tenant / Requester Details
          requestedBy: 'Erika De Guzman',
          unit: 'A 1001',
          scheduleAvailability: 'August 19, 2025',

          // Request Details
          priority: 'High',
          department: 'Plumbing',
          description: '',

          // Notes (Job Service specific)
          notes: 'Please notify me 30 minutes before arrival.',

          attachments: const [],
        );

      // Work Order Permit
      case 'work order permit':
        return RepairDetailsScreen(
          // Basic Information
          title: 'Leaking Faucet',
          requestId: 'WO-2025-00123',
          statusTag: 'Pending',
          date: 'August 2, 2025',
          requestType: 'Work Order Permit',

          // Tenant / Requester Details
          requestedBy: 'Erika De Guzman',
          unit: 'A 1001',

          // Request Details
          priority: 'High',
          department: 'Plumbing',
          description: '-', // not displayed when "instructions" are present

          // Permit Details
          scheduleAvailability: '2025-07-19', // validation/date requested
          accountType: 'Air Conditioning',
          instructions:
              'Tenant reports a clogged drainage issue in the bathroom. Water drains slowly and backs up to the floor. Plunger attempt failed.',

          // Contractor profile (optional)
          contractorName: 'John Doe',
          contractorCompany: 'Doe Plumbing Services',
          contractorPhone: '555-1234',

          attachments: const [],
        );

      default:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Unsupported details type.'),
          ),
        );
    }
  }

  // ------------- Shared helpers -------------
  void _goToKind(String kind) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkOrderDetailsPage(selectedTabLabel: kind),
      ),
    );
  }

  /// Generic popup → routes to FullDetails with clean, centered copy.
  Future<void> _showFullDetailsPopup({
    required String fullDetailsLabel,
    String title = 'Success',
    String message =
        'The action has been completed.\nTap below to open the full details.',
    String primaryText = 'Open Full Details',
  }) async {
    return showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: title,
        message: message,
        primaryText: primaryText,
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FullDetails(selectedTabLabel: fullDetailsLabel),
            ),
          );
        },
      ),
    );
  }

  // ------------- Scenario actions -------------
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
      builder: (_) => CustomPopup(
        title: 'Request Rejected',
        message:
            'Reason: ${result.reason}${(result.note?.isNotEmpty ?? false) ? "\n\nNote: ${result.note}" : ""}',
        primaryText: 'OK',
        onPrimaryPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Assign Staff → popup → FullDetails
  Future<void> _openAssign() async {
    final result = await showModalBottomSheet<AssignResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AssignStaffBottomSheet(),
    );
    if (!mounted || result == null) return;

    late final String fullDetailsLabel;
    if (_isConcernSlip) {
      fullDetailsLabel = kConcernAssignStaff;    // route for assigned Concern Slip
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

  Future<void> _decideAssessed() async {
    // From "Assessed Concern Slip" → choose next step
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Continue as'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Job Service'),
              subtitle: const Text('Proceed with internal service assignment'),
              onTap: () => Navigator.pop(ctx, 'job service'),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Work Order Permit'),
              subtitle: const Text('Proceed with contractor permit process'),
              onTap: () => Navigator.pop(ctx, 'work order permit'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );

    if (!mounted || choice == null) return;

    if (choice == 'job service') {
      await _openAssign();
    } else if (choice == 'work order permit') {
      _goToKind(choice);
    }
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
    // 1) Concern Slip → Reject / Accept & Assign
    if (_isConcernSlip) {
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
          label: 'Accept & Assign',
          icon: Icons.person_add_alt,
          onPressed: _openAssign,
          withOuterBorder: false,
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }

    // 2) Assessed Concern Slip → Decide
    if (_isAssessed) {
      return _barSingleButton(
        custom_buttons.FilledButton(
          label: 'Validate & Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _decideAssessed,
          withOuterBorder: false,
          backgroundColor: const Color(0xFF2563EB),
        ),
      );
    }

    // 3) Job Service → Assign Staff / Reject
    if (_isJobService) {
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
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }

    // 4) Work Order Permit → Approve / Reject
    if (_isWorkPermit) {
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
          label: 'Approve Permit',
          icon: Icons.check_circle_outline,
          onPressed: _approvePermit,
          withOuterBorder: false,
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }

    return null;
  }

  Widget _barSingleButton(Widget button) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(children: [Expanded(child: button)]),
      ),
    );
  }

  Widget _barTwoButtons({required Widget left, required Widget right}) {
    return SafeArea(
      top: false,
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
        showHistory: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, extraBottom + bodyPadding.bottom),
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
