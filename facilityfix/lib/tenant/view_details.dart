import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/view_details.dart'; // RepairDetailsScreen, AnnouncementDetailScreen
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:intl/intl.dart' show DateFormat;

class ViewDetailsPage extends StatefulWidget {
  final String? selectedTabLabel;
  final String? requestTypeTag;

  const ViewDetailsPage({
    super.key,
    this.selectedTabLabel,
    this.requestTypeTag,
  });

  @override
  State<ViewDetailsPage> createState() => _ViewDetailsPageState();
}

class _ViewDetailsPageState extends State<ViewDetailsPage> {
  int _selectedIndex = 1;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const ProfilePage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  _DetailsPayload _buildPayload(BuildContext context) {
    String normalize(String s) => s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    final raw =
        (widget.selectedTabLabel?.trim().isNotEmpty ?? false)
            ? widget.selectedTabLabel!
            : (widget.requestTypeTag ?? '');
    final label = normalize(raw);

    switch (label) {
      // ---------------- Concern Slip ----------------
      // Default Concern Slip
      case 'concern slip':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: ConcernSlipDetails(
            // Basic Information
            title: "Leaking Faucet",
            id: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Concern Slip",
            statusTag: 'Pending',
            priority: 'High',

            // Requestor Details
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            scheduleAvailability: "August 19, 2025 2:30 PM",

            // Request Details
            description:
                "I’d like to report a clogged drainage issue in the bathroom.",
            attachments: const [
              "assets/images/upload1.png",
              "assets/images/upload2.png",
            ],
          ),
        );

      // Concern Slip (Assigned)
      case 'concern slip assigned':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: ConcernSlipDetails(
            title: "Leaking Faucet",
            id: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Concern Slip",
            statusTag: 'Assigned',
            priority: 'High',
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            scheduleAvailability: "August 19, 2025 2:30 PM",
            description:
                "I’d like to report a clogged drainage issue in the bathroom.",
            attachments: const [
              "assets/images/upload1.png",
              "assets/images/upload2.png",
            ],
            assignedStaff: 'Juan Dela Cruz',
            staffDepartment: 'Plumbing',
          ),
        );

      // Concern Slip (Assessed)
      case 'concern slip assessed':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: ConcernSlipDetails(
            title: "Leaking Faucet",
            id: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Concern Slip",
            statusTag: 'Assigned',
            priority: 'High',
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            scheduleAvailability: "August 19, 2025 2:30 PM",
            description:
                "I’d like to report a clogged drainage issue in the bathroom.",
            attachments: const [
              "assets/images/upload1.png",
              "assets/images/upload2.png",
            ],
            assignedStaff: 'Juan Dela Cruz',
            staffDepartment: 'Plumbing',
            assessedAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            assessment: 'Drainage is clogged due to accumulated debris.',
            staffAttachments: const ["assets/images/upload2.png"],
          ),
        );

      // ---------------- Job Service ----------------
      case 'job service':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: JobServiceDetails(
            id: "JS-2025-031",
            concernSlipId: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Job Service",
            statusTag: 'Pending',
            priority: 'High',
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            scheduleAvailability: "August 19, 2025 2:30 PM",
            additionalNotes: "Please expedite; recurring issue.",
          ),
        );

      case 'job service assigned':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: JobServiceDetails(
            id: "JS-2025-031",
            concernSlipId: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Job Service",
            statusTag: 'Assigned',
            priority: 'High',
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            scheduleAvailability: "August 19, 2025 2:30 PM",
            additionalNotes: "Please expedite; recurring issue.",
            assignedStaff: 'Juan Dela Cruz',
            staffDepartment: 'Plumbing',
            startedAt: DateTime(2025, 8, 20, 9, 0),
            completedAt: null,
            completionAt: null,
            assessedAt: null,
            assessment: null,
            staffAttachments: null,
            materialsUsed: const ['Plunger', 'Drain snake'],
          ),
        );

      case 'job service on hold':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: JobServiceDetails(
            id: "JS-2025-031",
            concernSlipId: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Job Service",
            statusTag: 'On Hold',
            priority: 'High',
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            scheduleAvailability: "August 19, 2025 2:30 PM",
            additionalNotes: "Please expedite; recurring issue.",
            assignedStaff: 'Juan Dela Cruz',
            staffDepartment: 'Plumbing',
            startedAt: DateTime(2025, 8, 20, 9, 0),
            assessedAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            assessment: 'Drainage is clogged due to accumulated debris.',
            staffAttachments: const ["assets/images/upload2.png"],
            materialsUsed: const ['Plunger', 'Drain snake'],
          ),
        );

      case 'job service assessed':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: JobServiceDetails(
            id: "JS-2025-031",
            concernSlipId: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Job Service",
            statusTag: 'Done',
            priority: 'High',
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            scheduleAvailability: "August 19, 2025 2:30 PM",
            additionalNotes: "Please expedite; recurring issue.",
            assignedStaff: 'Juan Dela Cruz',
            staffDepartment: 'Plumbing',
            startedAt: DateTime(2025, 8, 20, 9, 0),
            completedAt: DateTime(2025, 8, 20, 10, 15),
            completionAt: DateTime(2025, 8, 20, 10, 15),
            assessedAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            assessment: 'Drainage is clogged due to accumulated debris.',
            staffAttachments: const ["assets/images/upload2.png"],
            materialsUsed: const ['Plunger', 'Drain snake'],
          ),
        );

      // ---------------- Work Order ----------------
      case 'work order':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: WorkOrderPermitDetails(
            id: "WO-2025-014",
            concernSlipId: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Work Order",
            statusTag: 'Pending',
            priority: 'High',
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            contractorName: 'CoolAir Services PH',
            contractorCompany: 'CoolAir Services PH',
            contractorNumber: '+63 917 555 1234',
            workScheduleFrom: DateFormat(
              'MMMM d, yyyy h a',
            ).parse('August 31, 2025 2 PM'),
            workScheduleTo: DateFormat(
              'MMMM d, yyyy h a',
            ).parse('August 31, 2025 6 PM'),
            entryEquipments: 'Cooler',
            adminNotes:
                "AC unit is not cooling effectively; inspection requested.",
          ),
        );

      case 'work order approved':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: WorkOrderPermitDetails(
            id: "WO-2025-014",
            concernSlipId: "CS-2025-00123",
            createdAt: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            requestTypeTag: "Work Order",
            statusTag: 'Reject',
            priority: 'High',
            requestedBy: 'Erika De Guzman',
            unitId: "A 1001",
            contractorName: 'CoolAir Services PH',
            contractorCompany: 'CoolAir Services PH',
            contractorNumber: '+63 917 555 1234',
            workScheduleFrom: DateFormat(
              'MMMM d, yyyy h a',
            ).parse('August 31, 2025 2 PM'),
            workScheduleTo: DateFormat(
              'MMMM d, yyyy h a',
            ).parse('August 31, 2025 6 PM'),
            entryEquipments: 'Cooler',
            adminNotes:
                "AC unit is not cooling effectively; inspection requested.",
            approvedBy: 'Marco De Guzman',
            approvalDate: DateFormat('MMMM d, yyyy').parse('August 2, 2025'),
            denialReason: "May bagyo",
          ),
        );

      // ---------------- Maintenance ----------------
      case 'maintenance detail':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: MaintenanceDetails(
            title: 'Quarterly Pipe Inspection',
            id: 'MT-P-2025-011',
            createdAt: DateFormat('MMMM d, yyyy').parse('August 30, 2025'),
            requestTypeTag: 'Maintenance Task',
            statusTag: 'Scheduled',
            location: 'Tower A - 5th Floor',
            description:
                'Routine quarterly inspection of the main water lines on 5F.',
            checklist: const [
              'Shut off main valve',
              'Inspect joints',
              'Check for leaks',
            ],
            attachments: const ['assets/images/upload1.png'],
            assignedStaff: 'Juan Dela Cruz',
            staffDepartment: 'Plumbing',
            scheduleDate: 'August 30, 2025 10:00 AM',
            requestedBy: 'Admin',
          ),
        );

      case 'maintenance assessed':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: MaintenanceDetails(
            title: 'Quarterly Pipe Inspection',
            id: 'MT-P-2025-011',
            createdAt: DateFormat('MMMM d, yyyy').parse('August 30, 2025'),
            requestTypeTag: 'Maintenance Task',
            statusTag: 'Done',
            location: 'Tower A - 5th Floor',
            description:
                'Routine quarterly inspection of the main water lines on 5F.',
            checklist: const [
              'Shut off main valve',
              'Inspect joints',
              'Check for leaks',
            ],
            attachments: const ['assets/images/upload1.png'],
            assignedStaff: 'Juan Dela Cruz',
            staffDepartment: 'Plumbing',
            updatedAt: null,
            requestedBy: '', scheduleDate: '',
          ),
        );

      // ---------------- Announcement Detail ----------------
      case 'announcement detail':
        _selectedIndex = 2;
        return _DetailsPayload(
          child: AnnouncementDetails(
            // Basic Information
            id: 'ANN-2025-0011',
            title: 'Water Interruption Notice',
            createdAt: 'August 6, 2025',
            announcementType: 'Utility Interruption',

            // AAnnouncement Details
            description:
                'Water supply will be interrupted due to mainline repair.',
            locationAffected: 'Building A & B',

            // Schedule Information
            scheduleStart: 'August 7, 2025 - 8:00 AM',
            scheduleEnd: 'August 7, 2025 - 5:00 PM',

            // Contact Information
            contactNumber: '0917 123 4567',
            contactEmail: 'support@condoadmin.ph',
          ),
        );

      // ---------------- Default ----------------
      default:
        _selectedIndex = 1;
        return const _DetailsPayload(
          child: Center(child: Text("No requests found.")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = _buildPayload(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'View Details',
        leading: const Row(
          children: [
            Padding(padding: EdgeInsets.only(right: 8), child: BackButton()),
          ],
        ),
        showMore: true,
        showHistory: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                payload.hasCta ? 120 : 24,
              ),
              child: payload.child,
            ),
            if (payload.hasCta)
              Positioned(
                left: 24,
                right: 24,
                bottom: 16,
                child: SafeArea(
                  top: false,
                  child: fx.FilledButton(
                    label: payload.ctaLabel!,
                    onPressed: payload.onCtaPressed!,
                  ),
                ),
              ),
          ],
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

class _DetailsPayload {
  final Widget child;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;

  const _DetailsPayload({
    required this.child,
    this.ctaLabel,
    this.onCtaPressed,
  });

  bool get hasCta => ctaLabel != null && onCtaPressed != null;
}
