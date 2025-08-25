import 'package:facilityfix/staff/announcement.dart'; 
import 'package:facilityfix/staff/calendar.dart';      
import 'package:facilityfix/staff/home.dart';         
import 'package:facilityfix/staff/inventory.dart';     
import 'package:facilityfix/staff/view_details/full_details.dart';
import 'package:facilityfix/staff/workorder.dart' hide HoldResult;     
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/forms.dart';
import 'package:facilityfix/widgets/helper_models.dart';
import 'package:facilityfix/widgets/pop_up.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:facilityfix/widgets/buttons.dart' as custom_buttons;
import 'package:flutter/material.dart';

class RepairDetails extends StatefulWidget {
  final String viewMode; // 'view detail' | 'add assessment'

  const RepairDetails({
    super.key,
    this.viewMode = 'view detail', required String selectedTabLabel,
  });

  @override
  State<RepairDetails> createState() => _RepairDetailsState();
}

class _RepairDetailsState extends State<RepairDetails> {
  // Bottom nav selected index (Work tab)
  int _selectedIndex = 1;

  // Controls which tab body is shown
  late String selectedTabLabel;

  // Form controllers for the assessment screen
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController recommendationController = TextEditingController();

  HoldResult? holdMeta;

  // Bottom nav items
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
    selectedTabLabel = widget.viewMode.toLowerCase();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    recommendationController.dispose();
    super.dispose();
  }

  /// Handle bottom nav route transitions.
  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destinations[index]));
    }
  }

  void _showAssessmentCompletedDialog() {
    showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Assessment Completed',
        message:
            'You’ve successfully submitted your assessment.\nTap below to view the full details.',
        primaryText: 'View Assessment',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const FullDetails(selectedTabLabel: 'repair detail'),
            ),
          );
        },
      ),
    );
  }

  /// Opens the "Put Request On Hold" sheet (with reason, resume date, note).
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

  /// Builds the main body (view details or assessment form).
  Widget _buildTabContent() {
    final children = <Widget>[];

    // If On Hold—show a compact banner above the details
    if (holdMeta != null) {
      children.add(OnHoldBanner(hold: holdMeta!));
      children.add(const SizedBox(height: 12));
    }

    switch (selectedTabLabel) {
      case 'view detail':
        children.add(
          RepairDetailsScreen(
            title: "Leaking Faucet",
            requestId: "REQ-2025-00123",
            statusTag: holdMeta != null ? 'On Hold' : 'Pending',
            date: "August 2, 2025",
            requestType: "Repair",
            unit: "A 1001",
            description:
                "Hi, I’d like to report a clogged drainage issue in the bathroom...",
            priority: "High",
            assigneeName: "Juan Dela Cruz",
            assigneeRole: "Plumber",
            attachments: const [
              "assets/images/upload1.png",
              "assets/images/upload2.png",
            ],
          ),
        );
        break;

      case 'add assessment':
        children.addAll([
          const Text('Assessment and Recommendation',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          InputField(
            label: 'Assessment',
            controller: descriptionController,
            hintText: 'Enter assessment',
            isRequired: true,
          ),
          const SizedBox(height: 8),
          InputField(
            label: 'Recommendation',
            controller: recommendationController,
            hintText: 'Enter recommendation',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          const Text('Attachment', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const FileAttachmentPicker(label: 'Upload Attachment'),
        ]);
        break;

      default:
        children.add(const Center(child: Text("No requests found.")));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  @override
  Widget build(BuildContext context) {
    final bool isViewMode = selectedTabLabel == 'view detail';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'View Details',
        leading: Row(
          children: const [
            BackButton(),
            SizedBox(width: 8),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Extra bottom padding so content isn't hidden by the sticky action bar.
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: _buildTabContent(),
        ),
      ),

      // Sticky action bar + bottom nav
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sticky action bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  // On Hold / Resume toggle
                  Expanded(
                    child: custom_buttons.OutlinedPillButton(
                      icon: holdMeta != null
                          ? Icons.play_circle_outline   
                          : Icons.pause_circle_outline, 
                      label: holdMeta != null
                          ? 'Resume Task'
                          : 'On Hold',
                      onPressed: () {
                        if (holdMeta != null) {
                          // Resume immediately
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

                  // Primary CTA — Create / Submit Assessment
                  Expanded(
                    child: custom_buttons.FilledButton(
                      label: isViewMode ? "Create Assessment" : "Submit Assessment",

                      withOuterBorder: false,
                      onPressed: () {
                        if (!isViewMode) {
                          // Submit and show success modal
                          _showAssessmentCompletedDialog();
                          setState(() {
                            selectedTabLabel = 'view detail';
                          });
                        } else {
                          // Switch to the assessment form
                          setState(() {
                            selectedTabLabel = 'add assessment';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // App bottom nav
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
