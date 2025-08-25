import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/request_forms.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/view_details.dart'; // RepairDetailsScreen, AnnouncementDetailScreen
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;

class ViewDetailsPage extends StatefulWidget {
  final String? selectedTabLabel;
  final String? requestType;

  const ViewDetailsPage({
    super.key,
    this.selectedTabLabel,
    this.requestType,
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

  /// We return both the content widget and (optionally) a CTA button config.
  _DetailsPayload _buildPayload(BuildContext context) {
    final raw = (widget.selectedTabLabel?.trim().isNotEmpty ?? false)
        ? widget.selectedTabLabel!
        : (widget.requestType ?? '');
    final label = raw.trim().toLowerCase();

    switch (label) {
      case 'repair detail':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: RepairDetailsScreen(
            title: "Leaking Faucet",
            requestId: "REQ-2025-00123",
            statusTag: 'Pending',
            date: "August 2, 2025",
            requestType: "Repair",
            unit: "A 1001",
            description:
                "Hi, I’d like to report a clogged drainage issue in the bathroom of my unit. The water is draining very slowly, and it’s starting to back up onto the floor. I’ve already tried using a plunger but it didn’t help. It’s been like this since yesterday and is getting worse. Please send someone to check and fix it as soon as possible. Thank you!",
            priority: "High",
            assigneeName: "Juan Dela Cruz",
            assigneeRole: "Plumber",
            attachments: const [
              "assets/images/upload1.png",
              "assets/images/upload2.png",
            ],
            // IMPORTANT: no inline button in the detail widget
            actionLabel: null,
            onAction: null,
          ),
          // No CTA at page level either
          ctaLabel: null,
          onCtaPressed: null,
        );

      case 'announcement detail':
        _selectedIndex = 2;
        return _DetailsPayload(
          child: AnnouncementDetailScreen(
            title: 'Water Interruption Notice',
            datePosted: 'August 6, 2025',
            classification: 'Utility Interruption',
            description: 'Water supply will be interrupted due to mainline repair.',
            locationAffected: 'Building A & B',
            scheduleStart: 'August 7, 2025 - 8:00 AM',
            scheduleEnd: 'August 7, 2025 - 5:00 PM',
            contactNumber: '0917 123 4567',
            contactEmail: 'support@condoadmin.ph',
          ),
          ctaLabel: null,
          onCtaPressed: null,
        );

      // Step 1: Work Order Permit details -> Next -> go to Job Service Request form
      case 'work order permit details':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: RepairDetailsScreen(
            title: "Leaking Faucet",
            requestId: "REQ-2025-00123",
            statusTag: 'Pending',
            date: "August 2, 2025",
            requestType: "Repair",
            unit: "A 1001",
            description:
                "Hi, I’d like to report a clogged drainage issue in the bathroom of my unit...",
            priority: "High",
            assigneeName: "Juan Dela Cruz",
            assigneeRole: "Plumber",
            assessment:
                "The unit’s drainage pipe is blocked, causing overflow. Minor cleaning and pipe flush are needed.",
            recommendation: "Clear clogged drainage pipe.",
            attachments: const [
              "assets/images/upload1.png",
              "assets/images/upload2.png",
            ],
            // Keep inline button OFF
            actionLabel: null,
            onAction: null,
          ),
          ctaLabel: 'Next',
          onCtaPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const RequestForm(requestType: 'Job Service Request'),
              ),
            );
          },
        );

      // Step 2: Job Service details -> Next -> go to Work Order Permit form
      case 'job service permit details':
        _selectedIndex = 1;
        return _DetailsPayload(
          child: RepairDetailsScreen(
            title: "Leaking Faucet",
            requestId: "REQ-2025-00123",
            statusTag: 'Pending',
            date: "August 2, 2025",
            requestType: "Repair",
            unit: "A 1001",
            description:
                "Hi, I’d like to report a clogged drainage issue in the bathroom of my unit...",
            priority: "High",
            assigneeName: "Juan Dela Cruz",
            assigneeRole: "Plumber",
            assessment:
                "The unit’s drainage pipe is blocked, causing overflow. Minor cleaning and pipe flush are needed.",
            recommendation: "Clear clogged drainage pipe.",
            attachments: const [
              "assets/images/upload1.png",
              "assets/images/upload2.png",
            ],
            // Keep inline button OFF
            actionLabel: null,
            onAction: null,
          ),
          ctaLabel: 'Next',
          onCtaPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const RequestForm(requestType: 'Work Order Permit'),
              ),
            );
          },
        );

      default:
        _selectedIndex = 1;
        return _DetailsPayload(
          child: const Center(child: Text("No requests found.")),
          ctaLabel: null,
          onCtaPressed: null,
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
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: BackButton(),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable content (pad bottom so it doesn't hide behind CTA)
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, payload.hasCta ? 120 : 24),
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

/// Small carrier for page content + optional CTA
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
