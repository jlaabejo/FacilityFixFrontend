import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/staff/form/assessment_form.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;

class StaffConcernSlipDetailPage extends StatefulWidget {
  final String concernSlipId;

  const StaffConcernSlipDetailPage({super.key, required this.concernSlipId});

  @override
  State<StaffConcernSlipDetailPage> createState() =>
      _StaffConcernSlipDetailPageState();
      
}

class _StaffConcernSlipDetailPageState
    extends State<StaffConcernSlipDetailPage> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _concernSlipData;
  
  // On hold state
  Map<String, dynamic> holdMeta = {};

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  @override
  void initState() {
    super.initState();
    _loadConcernSlipData();
  }

  Future<void> _loadConcernSlipData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use staff role for API service
      final apiService = APIService(roleOverride: AppRole.staff);
      final data = await apiService.getConcernSlipById(widget.concernSlipId);

      // Enrich data with user names if we have user IDs
      await _enrichWithUserNames(data, apiService);

      if (mounted) {
        setState(() {
          _concernSlipData = data;
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

  /// Fetch and populate user names when we have user IDs
  Future<void> _enrichWithUserNames(Map<String, dynamic> data, APIService apiService) async {
    try {
      // Fetch reported_by name if we have the ID but not the name
      if (data.containsKey('reported_by') &&
          data['reported_by'] != null &&
          !data.containsKey('reported_by_name')) {
        final userId = data['reported_by'].toString();
        print('[DEBUG] Fetching user name for reported_by: $userId');
        final userData = await apiService.getUserById(userId);
        if (userData != null) {
          final firstName = userData['first_name'] ?? '';
          final lastName = userData['last_name'] ?? '';
          data['reported_by_name'] = '$firstName $lastName'.trim();
          print('[DEBUG] Set reported_by_name to: ${data['reported_by_name']}');
        }
      }

      // Fetch assigned_to name if we have the ID but not the name
      if (data.containsKey('assigned_to') &&
          data['assigned_to'] != null &&
          !data.containsKey('assigned_to_name')) {
        final userId = data['assigned_to'].toString();
        print('[DEBUG] Fetching user name for assigned_to: $userId');
        final userData = await apiService.getUserById(userId);
        if (userData != null) {
          final firstName = userData['first_name'] ?? '';
          final lastName = userData['last_name'] ?? '';
          data['assigned_to_name'] = '$firstName $lastName'.trim();
          print('[DEBUG] Set assigned_to_name to: ${data['assigned_to_name']}');
        }
      }
    } catch (e) {
      print('[DEBUG] Error enriching user names: $e');
      // Don't fail the entire load if we can't fetch user names
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

  Future<void> _onHoldPressed() async {
    // Check if currently on hold
    bool isOnHold = _concernSlipData?['status'] == 'on_hold';

    if (isOnHold) {
      // Resume task - set status back to assigned
      try {
        final apiService = APIService(roleOverride: AppRole.staff);
        final token = await AuthStorage.getToken();
        if (token == null) {
          throw Exception('Authentication required');
        }

        final response = await http.patch(
          Uri.parse('${apiService.baseUrl}/concern-slips/${widget.concernSlipId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'status': 'assigned'}),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Failed to resume task: ${response.body}');
        }
        
        setState(() {
          _concernSlipData!['status'] = 'assigned';
          holdMeta = {};
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task resumed successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to resume task: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Put on hold - show bottom sheet
      final result = await showHoldSheet(context);
      
      if (result == null) return; // User cancelled
      
      try {
        final apiService = APIService(roleOverride: AppRole.staff);
        final token = await AuthStorage.getToken();
        if (token == null) {
          throw Exception('Authentication required');
        }

        final body = <String, dynamic>{
          'status': 'on_hold',
          'hold_reason': result.reason,
        };
        
        if (result.note != null && result.note!.isNotEmpty) {
          body['hold_notes'] = result.note;
        }
        
        if (result.resumeAt != null) {
          body['resume_at'] = result.resumeAt!.toIso8601String();
        }

        final response = await http.patch(
          Uri.parse('${apiService.baseUrl}/concern-slips/${widget.concernSlipId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw Exception('Failed to put task on hold: ${response.body}');
        }
        
        setState(() {
          _concernSlipData!['status'] = 'on_hold';
          holdMeta = {
            'reason': result.reason,
            'notes': result.note,
            'resume_at': result.resumeAt?.toIso8601String(),
            'timestamp': DateTime.now().toIso8601String(),
          };
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task put on hold'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to put task on hold: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _createAssessment() async {
    // Navigate to the assessment form page with concern slip data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentForm(
          concernSlipId: widget.concernSlipId,
          concernSlipData: _concernSlipData,
          requestType: 'Concern Slip',
        ),
      ),
    ).then((_) {
      // Refresh data when returning from assessment form
      _loadConcernSlipData();
    });
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

  bool _isDeletableStatus(dynamic status) {
    if (status == null) return false;
    final s = status.toString().toLowerCase().trim();
    return s == 'pending' || s == 'complete' || s == 'completed' || s == 'done';
  }

  // Map various backend status strings to canonical, human-friendly labels
  // used in the UI. This only affects display; internal logic should still
  // operate on the raw status values.
  String _displayStatus(dynamic raw) {
    if (raw == null) return 'pending';
    final s = raw.toString().toLowerCase().trim();

    if (s.contains('pending')) return 'pending';
    if (s == 'sent to client' || s == 'sent_to_client' || s == 'sent to tenant' || s == 'sent') return 'inspected';
    if (s.contains('inspected') || s.contains('sent')) return 'inspected';
    if (s.contains('to inspect') || s.contains('to be inspect') || s.contains('to_be_inspect') || s.contains('to_inspect')) return 'to inspect';
    // Map assigned -> to inspect per request
    if (s == 'assigned') return 'to inspect';
    if (s.contains('in progress') || s.contains('in_progress')) return 'in progress';
    if (s.contains('on hold') || s.contains('on_hold')) return 'on hold';

    // Fallback: return the normalized token (lowercase)
    return s.isEmpty ? 'pending' : s;
  }

  void _showDeleteDialog() {
    if (_concernSlipData == null) return;

    final status = (_concernSlipData!['status'] ?? '').toString().toLowerCase();
    if (!_isDeletableStatus(status)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only pending or completed requests can be deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteConcernSlip();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConcernSlip() async {
    try {
      final apiService = APIService(roleOverride: AppRole.staff);
      await apiService.deleteConcernSlip(widget.concernSlipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WorkOrderPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete request: $e'),
            backgroundColor: Colors.red,
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
        leading: const BackButton(),
        title: 'Concern Slip Details',
        showMore: true,
        // Show delete when status is pending or completed
        showDelete: _concernSlipData != null && _isDeletableStatus(_concernSlipData!['status']),
        onDeleteTap: _showDeleteDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading concern slip',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 24),
                      fx.FilledButton(
                        label: 'Retry',
                        backgroundColor: const Color(0xFF005CE7),
                        textColor: Colors.white,
                        onPressed: _loadConcernSlipData,
                      ),
                    ],
                  ),
                )
              : _concernSlipData == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                      child: Column(
                        children: [
                          // Display the concern slip details
                          ConcernSlipDetails(
                            id: _concernSlipData!['formatted_id'] ??
                                _concernSlipData!['id'] ??
                                '',
                            createdAt: _parseDateTime(
                                    _concernSlipData!['created_at']) ??
                                DateTime.now(),
                            updatedAt:
                                _parseDateTime(_concernSlipData!['updated_at']),
                            departmentTag: _concernSlipData!['category'],
                            requestTypeTag:
                                _concernSlipData!['request_type'] ??
                                    'Concern Slip',
                            priority: _concernSlipData!['priority'],
                            // Display a normalized, human-friendly status label while
                            // preserving the raw status value for internal logic.
                            statusTag: _displayStatus(_concernSlipData!['status'] ?? 'pending'),
                            resolutionType:
                                _concernSlipData!['resolution_type'],
                            requestedBy: _concernSlipData!['reported_by_name'] ?? _concernSlipData!['reported_by'] ?? '',
                            unitId: _concernSlipData!['unit_id'] ?? '',
                            scheduleAvailability:
                                _concernSlipData!['schedule_availability'],
                            title: _concernSlipData!['title'] ?? 'Untitled',
                            description:
                                _concernSlipData!['description'] ?? '',
                            attachments: _parseStringList(
                                _concernSlipData!['attachments']),
                            assignedStaff: _concernSlipData!['assigned_to_name'] ?? _concernSlipData!['assigned_to'],
                            staffDepartment:
                                _concernSlipData!['staff_department'],
                            assessedAt:
                                _parseDateTime(_concernSlipData!['assessed_at']),
                            assessment: _concernSlipData!['staff_assessment'],
                            staffAttachments: _parseStringList(
                                _concernSlipData!['staff_attachments']),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show On Hold and Create Assessment buttons if staff is assigned and status is assigned
          if (_concernSlipData != null &&
              _concernSlipData!['assigned_to'] != null &&
              _concernSlipData!['staff_assessment'] == null &&
              (_concernSlipData!['status'] == 'assigned' || _concernSlipData!['status'] == 'on_hold'))
            SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: fx.OutlinedPillButton(
                          label: holdMeta.isNotEmpty && _concernSlipData!['status'] == 'on_hold'
                              ? 'Resume Task'
                              : 'On Hold',
                          icon: holdMeta.isNotEmpty && _concernSlipData!['status'] == 'on_hold'
                              ? Icons.play_arrow
                              : Icons.pause,
                          borderColor: const Color(0xFF005CE7),
                          foregroundColor: const Color(0xFF005CE7),
                          onPressed: _onHoldPressed,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: fx.FilledButton(
                          label: 'Create Assessment',
                          backgroundColor: const Color(0xFF005CE7),
                          textColor: Colors.white,
                          withOuterBorder: false,
                          onPressed: _createAssessment,
                        ),
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
