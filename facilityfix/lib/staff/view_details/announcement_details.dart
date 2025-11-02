import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:intl/intl.dart';

class AnnouncementDetailsPage extends StatefulWidget {
  final String announcementId;
  
  const AnnouncementDetailsPage({
    super.key,
    required this.announcementId,
  });

  @override
  State<AnnouncementDetailsPage> createState() => _AnnouncementDetailsState();
}

class _AnnouncementDetailsState extends State<AnnouncementDetailsPage> {
  final int _selectedIndex = 2;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  late final APIService _apiService;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _announcement;

  @override
  void initState() {
    super.initState();
    _apiService = APIService();
    _fetchAnnouncementDetails();
  }

  Future<void> _fetchAnnouncementDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getAnnouncementById(widget.announcementId);
      setState(() {
        _announcement = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load announcement details: $e';
        _isLoading = false;
      });
      print('[AnnouncementDetails] Error: $e');
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

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateOnly(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _markAsRead() async {
    try {
      await _apiService.markAnnouncementViewed(widget.announcementId);

      // Refresh the announcement details to reflect the change
      await _fetchAnnouncementDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as read'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[AnnouncementDetails] Error marking as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as read: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              child: const BackButton(),
            ),
            Text('View Details'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchAnnouncementDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        AnnouncementDetails(
                          id: _announcement?['formatted_id'] ??
                              _announcement?['id'] ??
                              'N/A',
                          title: _announcement?['title'] ?? 'Untitled',
                          createdAt: _formatDateOnly(_announcement?['created_at']),
                          announcementType: _announcement?['type'] ?? 'general',
                          description: _announcement?['content'] ?? 'No description available',
                          locationAffected: _announcement?['location_affected'] ?? 'N/A',
                          scheduleStart: _announcement?['scheduled_publish_date'] != null
                              ? _formatDate(_announcement?['scheduled_publish_date'])
                              : 'Not scheduled',
                          scheduleEnd: _announcement?['expiry_date'] != null
                              ? _formatDate(_announcement?['expiry_date'])
                              : 'No expiry',
                          contactNumber: _announcement?['contact_number'] ?? 'N/A',
                          contactEmail: _announcement?['contact_email'] ?? 'N/A',
                          isRead: _announcement?['is_read'] ?? false,
                          onMarkAsRead: _announcement?['is_read'] == true ? null : _markAsRead,
                        ),
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
