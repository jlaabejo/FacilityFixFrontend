import 'package:flutter/material.dart';

import 'package:facilityfix/models/work_orders.dart'; // <-- unified WorkOrderDetails class only
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/form/assessment_form.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart'; // WorkOrderPage (list)

import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:facilityfix/widgets/buttons.dart' as custom_buttons;

// Your detail widgets should be exported by this file:
import 'package:facilityfix/widgets/view_details.dart';
// Expecting these classes there:
// - ConcernSlipDetails
// - JobServiceDetails
// - MaintenanceDetails
// - WorkOrderPermitDetails

class WorkOrderDetailsPage extends StatefulWidget {
  final String selectedTabLabel;
  final bool startInAssessment; // kept for compatibility
  final WorkOrderDetails? workOrder; // unified data model instance

  const WorkOrderDetailsPage({
    super.key,
    required this.selectedTabLabel,
    this.startInAssessment = false,
    this.workOrder,
  });

  @override
  State<WorkOrderDetailsPage> createState() => _WorkOrderDetailsState();
}

class _WorkOrderDetailsState extends State<WorkOrderDetailsPage> {
  final int _selectedIndex = 1;
  late String _detailsLabel;

  // Hold metadata for the sticky bar
  HoldResult? holdMeta;

  // ---- SAMPLE DATA lives INSIDE this page ----
  late final List<WorkOrderDetails> _samples;

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

    _detailsLabel = widget.selectedTabLabel.toLowerCase().trim();

    // Build samples now (used only when widget.workOrder == null)
    _samples = _makeSamples();

    // Remap generic labels using actual data (unified model)
    if (widget.workOrder != null &&
        (_detailsLabel == 'repair detail' || _detailsLabel == 'maintenance detail')) {
      _detailsLabel = _autoLabelFromWorkOrder(widget.workOrder!);
      debugPrint('[Details] remapped to: $_detailsLabel');
    }

    debugPrint('DETAILS label="${widget.selectedTabLabel}" '
        'stored="$_detailsLabel" hasWorkOrder=${widget.workOrder != null}');
  }

  // ---------------- SAMPLE DATA (only used when no workOrder is passed) ----------------
  List<WorkOrderDetails> _makeSamples() {
    final now = DateTime.now();
    return [
      // Concern Slip
      WorkOrderDetails(
        id: 'CS-2025-001',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 9)),
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
        assignedPhotoUrl: 'assets/images/avatar.png',
      ),

      // Job Service (from slip)
      WorkOrderDetails(
        id: 'JS-2025-031',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 6)),
        requestTypeTag: 'Job Service',
        departmentTag: 'Plumbing',
        priority: 'High',
        statusTag: 'Assigned',
        resolutionType: 'job_service',
        requestedBy: 'Erika De Guzman',
        concernSlipId: 'CS-2025-001',
        unitId: 'A 1001',
        scheduleAvailability: '2025-08-20T09:00:00',
        additionalNotes: 'Recurring issue, please expedite.',
        title: 'Fix Faucet & Clear Drain',
        description: 'Replace worn gasket and clear debris clog.',
        assignedStaff: 'Juan Dela Cruz',
        staffDepartment: 'Plumbing',
        assignedPhotoUrl: 'assets/images/avatar.png',
        startedAt: now.subtract(const Duration(days: 7, hours: 3)),
        materialsUsed: const ['PTFE tape', 'Gasket #12'],
      ),

      // Work Order (Permit)
      WorkOrderDetails(
        id: 'WO-2025-015',
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 11)),
        requestTypeTag: 'Work Order',
        departmentTag: 'Carpentry',
        priority: 'Medium',
        statusTag: 'Approved',
        resolutionType: 'work_permit',
        requestedBy: 'Admin Jane',
        unitId: 'B 703',
        title: 'Ceiling Repair Permit',
        description: 'Permit for ceiling panel replacement due to moisture damage.',
        location: 'Tower B – Unit 703',
        additionalNotes: 'Coordinate with security for elevator padding.',
        contractorName: 'XYZ Builders',
        contractorNumber: '+63 912 345 6789',
        contractorCompany: 'XYZ Builders Inc.',
        workScheduleFrom: now.add(const Duration(days: 3, hours: 9)),
        workScheduleTo: now.add(const Duration(days: 3, hours: 14)),
        entryEquipments: 'Ladder, cordless drill, safety harness',
        approvedBy: 'Admin Jane',
        approvalDate: now.subtract(const Duration(days: 10)),
        adminNotes: 'Work window strictly observed.',
        materialsUsed: const ['Ceiling panel 60x60', 'Wood screws'],
      ),

      // Maintenance
      WorkOrderDetails(
        id: 'MT-2025-011',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        requestTypeTag: 'Maintenance',
        departmentTag: 'Plumbing',
        priority: 'High',
        statusTag: 'Scheduled',
        requestedBy: 'System – Planned PM',
        scheduleAvailability: '2025-08-30T09:00:00',
        title: 'Quarterly Pipe Inspection',
        description: 'Check main and branch lines for leaks, corrosion, and pressure stability.',
        location: 'Tower A – 5th Floor',
        checklist: [
          'Notify tenants on the affected floor',
          'Shut off water supply safely',
          'Inspect risers and branch lines for leaks/corrosion',
          'Check pressure and flow at endpoints',
          'Restore supply and monitor for 15 minutes',
          'Log findings and anomalies',
        ].join('\n'),
        assignedStaff: 'Juan Dela Cruz',
        staffDepartment: 'Plumbing',
        assignedPhotoUrl: 'assets/images/avatar.png',
        attachments: const ['assets/images/upload3.png'],
      ),
    ];
  }

  // pick a sample matching the label (used if no workOrder is provided)
  WorkOrderDetails _sampleForLabel() {
    switch (_detailsLabel) {
      case 'concern slip assigned':
      case 'concern slip assessed':
        return _samples.firstWhere((e) => e.requestTypeTag == 'Concern Slip',
            orElse: () => _samples.first);
      case 'job service assigned':
      case 'job service assessed':
        return _samples.firstWhere((e) => e.requestTypeTag == 'Job Service',
            orElse: () => _samples.first);
      case 'work order assigned':
      case 'work order assessed':
        return _samples.firstWhere((e) => e.requestTypeTag == 'Work Order',
            orElse: () => _samples.first);
      case 'maintenance task scheduled':
      case 'maintenance task assessed':
        return _samples.firstWhere((e) => e.requestTypeTag == 'Maintenance',
            orElse: () => _samples.first);
      default:
        return _samples.first;
    }
  }

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(), // list page
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

  String get _assessedFullDetailsLabel {
    if (_detailsLabel.contains('maintenance')) return 'assessed maintenance detail';
    return 'assessed repair detail';
  }

  Future<void> _onHoldPressed() async {
    final res = await showHoldSheet(context, initial: holdMeta);
    if (!mounted || res == null) return;
    setState(() => holdMeta = res);

    final until = res.resumeAt != null ? ' — until ${formatDateTime(res.resumeAt!)}' : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Set to On Hold: ${res.reason}$until'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------- Builders: map unified model -> concrete details widgets ----------

  Widget _buildConcernSlip(WorkOrderDetails w, {required bool assessed}) {
    return ConcernSlipDetails(
      // Basic
      id: w.id,
      createdAt: w.createdAt,
      updatedAt: w.updatedAt,
      departmentTag: w.departmentTag,
      requestTypeTag: 'Concern Slip',
      priority: w.priority,
      statusTag: w.statusTag,
      resolutionType: w.resolutionType,

      // Requester
      requestedBy: w.requestedBy ?? '—',
      unitId: w.unitId ?? '—',
      scheduleAvailability: w.scheduleAvailability,

      // Request Details
      title: w.title,
      description: (w.description ?? '').isNotEmpty ? w.description! : '—',
      attachments: w.attachments,

      // Staff / Assessment
      assignedStaff: w.assignedStaff,
      staffDepartment: w.staffDepartment,
      staffPhotoUrl: w.assignedPhotoUrl,
      assessedAt: w.assessedAt,
      assessment: w.assessment,
      staffAttachments: w.staffAttachments,
    );
  }

  Widget _buildJobService(WorkOrderDetails w, {required bool assessed}) {
    return JobServiceDetails(
      // Basic
      id: w.id,
      concernSlipId: w.concernSlipId ?? '—',
      createdAt: w.createdAt,
      updatedAt: w.updatedAt,
      requestTypeTag: 'Job Service',
      priority: w.priority,
      statusTag: w.statusTag,
      resolutionType: w.resolutionType,

      // Tenant / Requester
      requestedBy: w.requestedBy ?? '—',
      unitId: w.unitId ?? '—',
      scheduleAvailability: w.scheduleAvailability,
      additionalNotes: w.additionalNotes,

      // Staff
      assignedStaff: w.assignedStaff,
      staffDepartment: w.staffDepartment,
      staffPhotoUrl: w.assignedPhotoUrl,

      // Documentation
      startedAt: w.startedAt,
      completedAt: w.completedAt,
      completionAt: w.completedAt, // keep mapping if your widget shows both
      assessedAt: w.assessedAt,
      assessment: w.assessment,
      staffAttachments: w.staffAttachments,

      // Tracking
      materialsUsed: w.materialsUsed,
    );
  }

  Widget _buildMaintenance(WorkOrderDetails w, {required bool assessed}) {
    return MaintenanceDetails(
      // Basic
      id: w.id,
      createdAt: w.createdAt,
      updatedAt: w.updatedAt,
      departmentTag: w.departmentTag,
      requestTypeTag: 'Maintenance',
      priority: w.priority,
      statusTag: w.statusTag,
      resolutionType: w.resolutionType,

      // Tenant / requester
      requestedBy: w.requestedBy ?? '—',
      scheduleDate: w.scheduleAvailability, // String? in your widget API

      // Request details
      title: w.title,
      startedAt: w.startedAt,
      completedAt: w.completedAt,
      location: w.location ?? w.unitId, // prefer location, fallback to unit
      description: w.description,
      checklist: (w.checklist ?? '')
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      attachments: w.attachments,
      adminNote: w.adminNotes ?? w.additionalNotes,

      // Staff
      assignedStaff: w.assignedStaff,
      staffDepartment: w.staffDepartment,
      staffPhotoUrl: w.assignedPhotoUrl,
      assessedAt: w.assessedAt,
      assessment: w.assessment,
      staffAttachments: w.staffAttachments,

      // Tracking
      materialsUsed: w.materialsUsed,
    );
  }

  Widget _buildWorkOrderPermit(WorkOrderDetails w) {
    return WorkOrderPermitDetails(
      // Basic
      id: w.id,
      concernSlipId: w.concernSlipId ?? '—',
      createdAt: w.createdAt,
      updatedAt: w.updatedAt,
      requestTypeTag: 'Work Order',
      priority: w.priority,
      statusTag: w.statusTag,
      resolutionType: w.resolutionType,

      // Requester
      requestedBy: w.requestedBy ?? '—',
      unitId: w.unitId,

      // Permit specifics
      contractorName: w.contractorName ?? '—',
      contractorNumber: w.contractorNumber ?? '—',
      contractorCompany: w.contractorCompany,

      // Work window
      workScheduleFrom: w.workScheduleFrom ?? w.createdAt,
      workScheduleTo: w.workScheduleTo ?? w.createdAt,
      entryEquipments: w.entryEquipments,

      // Approvals
      approvedBy: w.approvedBy,
      approvalDate: w.approvalDate,
      denialReason: w.denialReason,
      adminNotes: w.adminNotes,
    );
  }

  // ---------- Infer route label from unified model ----------
  String _autoLabelFromWorkOrder(WorkOrderDetails w) {
    final id = w.id.toUpperCase();
    final type = (w.requestTypeTag).toLowerCase().trim();
    final s = (w.statusTag).toLowerCase().trim();

    bool isMaint() => type.contains('maintenance') || id.startsWith('MT');
    bool isSlip()  => type.contains('concern')    || id.startsWith('CS');
    bool isJS()    => type.contains('job service')|| id.startsWith('JS');
    bool isWO()    => type.contains('work order') || id.startsWith('WO');

    if (isMaint()) {
      return (s == 'scheduled' || s == 'assigned' || s == 'in progress')
          ? 'maintenance task scheduled'
          : 'maintenance task assessed';
    }
    if (isJS()) {
      return (s == 'assigned' || s == 'on hold' || s == 'scheduled')
          ? 'job service assigned'
          : 'job service assessed';
    }
    if (isWO()) {
      return (s == 'assigned' || s == 'scheduled' || s == 'in progress')
          ? 'work order assigned'
          : 'work order assessed';
    }
    if (isSlip()) {
      return (s == 'assigned' || s == 'on hold')
          ? 'concern slip assigned'
          : 'concern slip assessed';
    }
    return 'concern slip assigned';
  }

  // -------------------- main tab content --------------------
  Widget _buildTabContent() {
    // use the passed work order; otherwise pick a suitable sample
    final w = widget.workOrder ?? _sampleForLabel();
    final children = <Widget>[];

    if (holdMeta != null) {
      children.add(const SizedBox(height: 8));
      children.add(OnHoldBanner(hold: holdMeta!));
      children.add(const SizedBox(height: 12));
    }

    switch (_detailsLabel) {
      case 'concern slip assigned':
      case 'concern slip assessed':
        children.add(_buildConcernSlip(w, assessed: _detailsLabel.contains('assessed')));
        break;

      case 'job service assigned':
      case 'job service assessed':
        children.add(_buildJobService(w, assessed: _detailsLabel.contains('assessed')));
        break;

      case 'work order assigned':
      case 'work order assessed':
        children.add(_buildWorkOrderPermit(w));
        break;

      case 'maintenance task scheduled':
      case 'maintenance task assessed':
        children.add(_buildMaintenance(w, assessed: _detailsLabel.contains('assessed')));
        break;

      // generic -> infer from data
      case 'repair detail':
      case 'maintenance detail':
        final mapped = _autoLabelFromWorkOrder(w);
        if (mapped.contains('maintenance')) {
          children.add(_buildMaintenance(w, assessed: mapped.contains('assessed')));
        } else if (mapped.contains('work order')) {
          children.add(_buildWorkOrderPermit(w));
        } else if (mapped.contains('job service')) {
          children.add(_buildJobService(w, assessed: mapped.contains('assessed')));
        } else {
          children.add(_buildConcernSlip(w, assessed: mapped.contains('assessed')));
        }
        break;

      default:
        final mapped = _autoLabelFromWorkOrder(w);
        if (mapped.contains('maintenance')) {
          children.add(_buildMaintenance(w, assessed: mapped.contains('assessed')));
        } else if (mapped.contains('work order')) {
          children.add(_buildWorkOrderPermit(w));
        } else if (mapped.contains('job service')) {
          children.add(_buildJobService(w, assessed: mapped.contains('assessed')));
        } else {
          children.add(_buildConcernSlip(w, assessed: mapped.contains('assessed')));
        }
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...children, const SizedBox(height: 8)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workOrder;

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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: _buildTabContent(),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_detailsLabel != 'assessed repair detail' &&
              _detailsLabel != 'assessed maintenance detail')
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: custom_buttons.OutlinedPillButton(
                        icon: holdMeta != null
                            ? Icons.play_circle_outline
                            : Icons.pause_circle_outline,
                        label: holdMeta != null ? 'Resume Task' : 'On Hold',
                        onPressed: () {
                          if (holdMeta != null) {
                            setState(() => holdMeta = null);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task resumed'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            _onHoldPressed();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: custom_buttons.FilledButton(
                        label: 'Create Assessment',
                        withOuterBorder: false,
                        backgroundColor: const Color(0xFF005CE7),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AssessmentForm(
                                // Use unified fields
                                requestType: w?.requestTypeTag ?? 'Work Order',
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
