import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/request_forms.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:intl/intl.dart' show DateFormat;

class TenantConcernSlipDetailPage extends StatefulWidget {
  final String concernSlipId;

  const TenantConcernSlipDetailPage({super.key, required this.concernSlipId});

  @override
  State<TenantConcernSlipDetailPage> createState() =>
      _TenantConcernSlipDetailPageState();
}

class _TenantConcernSlipDetailPageState
    extends State<TenantConcernSlipDetailPage> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _concernSlipData;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
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
      final apiService = APIService();
      Map<String, dynamic> data;
      
      // Try to determine the request type and call appropriate endpoint
      try {
        // First try as concern slip
        data = await apiService.getConcernSlipById(widget.concernSlipId);
        print('[DEBUG] Successfully fetched as concern slip');
      } catch (e) {
        print('[DEBUG] Failed to fetch as concern slip, trying as job service: $e');
        try {
          // Then try as job service
          data = await apiService.getJobServiceById(widget.concernSlipId);
          // Ensure request_type is set for job services
          if (!data.containsKey('request_type')) {
            data['request_type'] = 'Job Service';
          }
          print('[DEBUG] Successfully fetched as job service');
        } catch (e2) {
          print('[DEBUG] Failed to fetch as job service, trying as work order: $e2');
          try {
            // Finally try as work order
            data = await apiService.getWorkOrderById(widget.concernSlipId);
            // Ensure request_type is set for work orders
            if (!data.containsKey('request_type')) {
              data['request_type'] = 'Work Order Permit';
            }
            print('[DEBUG] Successfully fetched as work order');
          } catch (e3) {
            // If all fail, throw the original concern slip error
            print('[DEBUG] Failed to fetch as work order too: $e3');
            throw e;
          }
        }
      }

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

  void _showHistorySheet() {
    if (_concernSlipData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) =>
              ConcernSlipHistorySheet(concernSlipData: _concernSlipData!),
    );
  }

  void _showEditDialog() {
    if (_concernSlipData == null) return;

    // Only allow editing if status is pending
    final status = (_concernSlipData!['status'] ?? '').toString().toLowerCase();
    if (status != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pending requests can be edited'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => EditConcernSlipPage(
              concernSlipId: widget.concernSlipId,
              concernSlipData: _concernSlipData!,
            ),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadConcernSlipData();
      }
    });
  }

  void _showDeleteDialog() {
    if (_concernSlipData == null) return;

    // Only allow deleting if status is pending
    final status = (_concernSlipData!['status'] ?? '').toString().toLowerCase();
    if (status != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only pending requests can be deleted'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Request'),
            content: const Text(
              'Are you sure you want to delete this request? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
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
      final apiService = APIService();
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

  void _showMoreOptions() {
    if (_concernSlipData == null) return;

    final status = (_concernSlipData!['status'] ?? '').toString().toLowerCase();
    final isPending = status == 'pending';

    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPending) ...[
                  ListTile(
                    leading: const Icon(Icons.edit, color: Color(0xFF2563EB)),
                    title: const Text('Edit Request'),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditDialog();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Request'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteDialog();
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.history, color: Color(0xFF667085)),
                  title: const Text('View History'),
                  onTap: () {
                    Navigator.pop(context);
                    _showHistorySheet();
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'View Details',
        leading: const Row(
          children: [
            Padding(padding: EdgeInsets.only(right: 8), child: BackButton()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load request details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF667085)),
                        ),
                        const SizedBox(height: 24),
                        fx.FilledButton(
                          label: 'Retry',
                          onPressed: _loadConcernSlipData,
                        ),
                      ],
                    ),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildConcernSlipDetails(),
                ),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildConcernSlipDetails() {
    if (_concernSlipData == null) return const SizedBox();

    final data = _concernSlipData!;
    final resolutionType = data['resolution_type']?.toString().toLowerCase();
    
    // Debug logging
    print('[DEBUG] Concern Slip Data:');
    print('  Status: ${data['status']}');
    print('  Resolution Type: ${data['resolution_type']}');
    print('  Resolution Type (lowercase): $resolutionType');
    print('  Resolution Set By: ${data['resolution_set_by']}');
    print('  Resolution Set At: ${data['resolution_set_at']}');
    print('  Should Show Form: ${resolutionType != null && resolutionType.isNotEmpty && resolutionType != 'rejected'}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConcernSlipDetails(
          id: data['formatted_id'] ?? data['id'] ?? '',
          title: data['title'] ?? 'Untitled Request',
          createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
          updatedAt:
              data['updated_at'] != null
                  ? DateTime.tryParse(data['updated_at'])
                  : null,
          requestTypeTag: 'Concern Slip',
          statusTag: data['status'] ?? 'pending',
          priority: data['priority'] ?? 'medium',
          departmentTag: data['category'],
          requestedBy: data['reported_by_name'] ?? data['reported_by'] ?? '',
          unitId: data['unit_id'] ?? '',
          scheduleAvailability: data['schedule_availability'],
          description: data['description'] ?? '',
          attachments: (data['attachments'] as List?)?.cast<String>(),
          assignedStaff: data['assigned_to_name'] ?? data['assigned_to'],
          staffDepartment: data['staff_department'],
          assessedAt:
              data['assessed_at'] != null
                  ? DateTime.tryParse(data['assessed_at'])
                  : null,
          assessment: data['staff_assessment'],
          staffRecommendation: data['staff_recommendation'],
          staffAttachments: (data['assessment_attachments'] as List?)?.cast<String>(),
        ),
        // Show embedded form if resolution type is set and status allows it
        if (resolutionType != null && 
            resolutionType.isNotEmpty && 
            resolutionType != 'rejected' &&
            _shouldShowEmbeddedForm(data['status'], resolutionType))
          _buildEmbeddedForm(resolutionType, data),
      ],
    );
  }

  bool _shouldShowEmbeddedForm(String? status, String resolutionType) {
    // Show embedded form if:
    // 1. Status is 'sent', 'evaluated', or 'approved' (admin has processed it)
    // 2. Resolution type is set to job_service or work_order
    // 3. The concern slip hasn't been completed yet
    final normalizedStatus = (status ?? '').toLowerCase();
    return ['sent', 'evaluated', 'approved'].contains(normalizedStatus) &&
           ['job_service', 'work_order', 'work_permit'].contains(resolutionType);
  }

  Widget _buildEmbeddedForm(String resolutionType, Map<String, dynamic> concernData) {
    final String formType;
    
    // Map resolution_type to form type
    if (resolutionType == 'job_service') {
      formType = 'Job Service';
    } else if (resolutionType == 'work_order' || resolutionType == 'work_permit') {
      formType = 'Work Order';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 24),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assignment,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proceed with $formType',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete the form below to proceed with your request',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmbeddedRequestFormPage(
                    requestType: formType,
                    concernSlipId: concernData['id'] ?? '',
                    concernSlipData: concernData,
                  ),
                ),
              ).then((submitted) {
                if (submitted == true) {
                  // Refresh the concern slip data after form submission
                  _loadConcernSlipData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$formType submitted successfully'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              });
            },
            icon: const Icon(Icons.edit_document),
            label: Text('Fill $formType Form'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditConcernSlipPage extends StatefulWidget {
  final String concernSlipId;
  final Map<String, dynamic> concernSlipData;

  const EditConcernSlipPage({
    super.key,
    required this.concernSlipId,
    required this.concernSlipData,
  });

  @override
  State<EditConcernSlipPage> createState() => _EditConcernSlipPageState();
}

class _EditConcernSlipPageState extends State<EditConcernSlipPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late String _selectedCategory;
  late String _selectedPriority;
  bool _isSaving = false;

  final List<String> _categories = [
    'Electrical',
    'Plumbing',
    'HVAC',
    'Carpentry',
    'Masonry',
    'Maintenance',
    'Security',
    'Fire Safety',
    'General',
  ];

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.concernSlipData['title'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.concernSlipData['description'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.concernSlipData['location'] ?? '',
    );
    _selectedCategory = _capitalizeFirst(
      widget.concernSlipData['category'] ?? 'General',
    );
    _selectedPriority = _capitalizeFirst(
      widget.concernSlipData['priority'] ?? 'Medium',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final apiService = APIService();
      await apiService.updateConcernSlip(
        concernSlipId: widget.concernSlipId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        category: _selectedCategory.toLowerCase(),
        priority: _selectedPriority.toLowerCase(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Request'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _priorities.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedPriority = value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                fx.FilledButton(
                  label: _isSaving ? 'Saving...' : 'Save Changes',
                  onPressed: _isSaving ? () {} : () => _saveChanges(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ConcernSlipHistorySheet extends StatelessWidget {
  final Map<String, dynamic> concernSlipData;

  const ConcernSlipHistorySheet({super.key, required this.concernSlipData});

  @override
  Widget build(BuildContext context) {
    final events = _buildTimelineEvents();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.history, color: Color(0xFF667085)),
                SizedBox(width: 12),
                Text(
                  'Request History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isLast = index == events.length - 1;
                return _TimelineItem(
                  title: event['title']!,
                  subtitle: event['subtitle'],
                  timestamp: event['timestamp']!,
                  isLast: isLast,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Map<String, String>> _buildTimelineEvents() {
    final events = <Map<String, String>>[];

    // Created event
    if (concernSlipData['created_at'] != null) {
      events.add({
        'title': 'Request Created',
        'subtitle': 'Initial submission by tenant',
        'timestamp': _formatTimestamp(concernSlipData['created_at']),
      });
    }

    // Updated event
    if (concernSlipData['updated_at'] != null &&
        concernSlipData['updated_at'] != concernSlipData['created_at']) {
      events.add({
        'title': 'Request Updated',
        'subtitle': 'Details modified',
        'timestamp': _formatTimestamp(concernSlipData['updated_at']),
      });
    }

    // Evaluated event
    if (concernSlipData['evaluated_at'] != null) {
      final status = concernSlipData['status'] ?? '';
      events.add({
        'title': 'Request Evaluated',
        'subtitle': 'Status: ${_capitalizeFirst(status)}',
        'timestamp': _formatTimestamp(concernSlipData['evaluated_at']),
      });
    }

    // Assigned event
    if (concernSlipData['assigned_at'] != null) {
      final staffName = concernSlipData['assigned_to_name'] ?? 'Staff';
      events.add({
        'title': 'Staff Assigned',
        'subtitle': 'Assigned to $staffName',
        'timestamp': _formatTimestamp(concernSlipData['assigned_at']),
      });
    }

    // Assessed event
    if (concernSlipData['assessed_at'] != null) {
      events.add({
        'title': 'Assessment Completed',
        'subtitle': 'Staff submitted assessment',
        'timestamp': _formatTimestamp(concernSlipData['assessed_at']),
      });
    }

    // Returned to tenant event
    if (concernSlipData['returned_to_tenant_at'] != null) {
      events.add({
        'title': 'Returned to Tenant',
        'subtitle': 'Ready for next steps',
        'timestamp': _formatTimestamp(concernSlipData['returned_to_tenant_at']),
      });
    }

    return events.reversed.toList();
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

// Embedded Request Form Page
class EmbeddedRequestFormPage extends StatelessWidget {
  final String requestType; // "Job Service" or "Work Order"
  final String concernSlipId;
  final Map<String, dynamic> concernSlipData;

  const EmbeddedRequestFormPage({
    super.key,
    required this.requestType,
    required this.concernSlipId,
    required this.concernSlipData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Submit $requestType'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card showing this is related to a concern slip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Related to Concern Slip',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            concernSlipData['formatted_id'] ?? concernSlipId,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Import the actual form from RequestForm
              Text(
                'Complete $requestType Form',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in the details below to proceed with your request',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Show the appropriate form based on request type
              RequestFormWrapper(
                requestType: requestType,
                concernSlipId: concernSlipId,
                concernSlipData: concernSlipData,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Wrapper to display the request form inline
class RequestFormWrapper extends StatelessWidget {
  final String requestType;
  final String concernSlipId;
  final Map<String, dynamic> concernSlipData;

  const RequestFormWrapper({
    super.key,
    required this.requestType,
    required this.concernSlipId,
    required this.concernSlipData,
  });

  @override
  Widget build(BuildContext context) {
    // Navigate to the actual RequestForm page
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestForm(
              requestType: requestType,
              concernSlipId: concernSlipId,
            ),
          ),
        ).then((value) {
          // Return true to indicate submission success
          if (value == true) {
            Navigator.pop(context, true);
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Text(
        'Open $requestType Form',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String timestamp;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    this.subtitle,
    required this.timestamp,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 60, color: const Color(0xFFE5E7EB)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timestamp,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
            checklist_complete: const [
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
            checklist_complete: const [
              'Shut off main valve',
              'Inspect joints',
              'Check for leaks',
            ],
            attachments: const ['assets/images/upload1.png'],
            assignedStaff: 'Juan Dela Cruz',
            staffDepartment: 'Plumbing',
            updatedAt: null,
            requestedBy: '',
            scheduleDate: '',
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