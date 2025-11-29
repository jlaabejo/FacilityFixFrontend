import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../../services/auth_storage.dart';

class WebDayOffViewDetailsDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> dayOffData,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            constraints: const BoxConstraints(
              maxWidth: 1000,
              maxHeight: 900,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _WebDayOffViewDetailsContent(dayOffData: dayOffData),
          ),
        );
      },
    );
  }
}

class _WebDayOffViewDetailsContent extends StatefulWidget {
  final Map<String, dynamic> dayOffData;

  const _WebDayOffViewDetailsContent({required this.dayOffData});

  @override
  State<_WebDayOffViewDetailsContent> createState() =>
      _WebDayOffViewDetailsContentState();
}

class _WebDayOffViewDetailsContentState
    extends State<_WebDayOffViewDetailsContent> {
  late Map<String, dynamic> _dayOffData;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _dayOffData = Map<String, dynamic>.from(widget.dayOffData);
    _loadDayOffDetails();
  }

  Future<void> _loadDayOffDetails() async {
    try {
      final id = _dayOffData['id'] ??
          _dayOffData['requestId'] ??
          _dayOffData['_doc_id'];
      print('[DayOffDetails] Loading full day off details for ID: $id');

      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        _api.setAuthToken(token);
      }

      // TODO: Replace with actual API endpoint
      // final resp = await _api.getDayOffDetails(id.toString());
      // if (resp['success'] == true && resp['data'] is Map) {
      //   setState(() {
      //     _dayOffData = Map<String, dynamic>.from(resp['data']);
      //   });
      // }
    } catch (e) {
      print('[DayOffDetails] Error loading day off details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Section
        _buildHeader(context),

        // Content with scroll
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Off request header
                _buildDayOffHeader(),
                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Basic Information Section
                _buildSectionTitle("Basic Information"),
                const SizedBox(height: 16),
                _buildBasicInfoGrid(),
                const SizedBox(height: 24),

                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Request Information Section
                _buildSectionTitle("Request Information"),
                const SizedBox(height: 16),
                _buildRequestInfoGrid(),
                const SizedBox(height: 24),

                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Reason and Notes Section
                _buildSectionTitle("Additional Details"),
                const SizedBox(height: 16),
                _buildAdditionalDetailsSection(),
              ],
            ),
          ),
        ),

        // Footer with action buttons
        _buildFooter(context),
      ],
    );
  }

  // Header with title and close button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 20, bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'Day Off Request Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(_dayOffData),
            icon: const Icon(Icons.close, color: Colors.grey, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Section title
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.8,
      ),
    );
  }

  // Day Off request header
  Widget _buildDayOffHeader() {
    final staffName = _dayOffData['name'] ?? _dayOffData['staffName'] ?? 'Staff Member';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day off request',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          staffName,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // Basic information grid
  Widget _buildBasicInfoGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoTile(
                "Name",
                _dayOffData['name'] ?? _dayOffData['staffName'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _buildInfoTile(
                "ID",
                _dayOffData['id'] ?? _dayOffData['staffId'] ?? 'N/A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoTile(
                "Department",
                _dayOffData['department'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 48),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  // Request information grid
  Widget _buildRequestInfoGrid() {
    final statusInfo = _getStatusInfo();

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoTile(
                "Date Requested",
                _formatDate(_dayOffData['dateRequested'] ??
                    _dayOffData['date_req'] ??
                    _dayOffData['created_at']),
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _buildStatusTile(
                "Status",
                statusInfo['text'],
                statusInfo['color'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoTile(
                "Days",
                "${_dayOffData['days'] ?? 0} day(s)",
              ),
            ),
            const SizedBox(width: 48),
            Expanded(child: Container()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoTile(
                "Start Date",
                _formatDate(_dayOffData['startDate'] ?? _dayOffData['start_date']),
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _buildInfoTile(
                "End Date",
                _formatDate(_dayOffData['endDate'] ?? _dayOffData['end_date']),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Additional details section (reason and notes)
  Widget _buildAdditionalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reason
        _buildSectionLabel("Reason"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            _dayOffData['reason'] ?? 'No reason provided',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Additional notes
        _buildSectionLabel("Additional Notes"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            _dayOffData['additionalNotes'] ??
                _dayOffData['additional_notes'] ??
                'No additional notes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Admin notes
        _buildSectionLabel("Admin Notes"),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Text(
            _dayOffData['adminNotes'] ?? _dayOffData['admin_notes'] ?? 'No admin notes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // Build info tile
  Widget _buildInfoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Build status tile with color
  Widget _buildStatusTile(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: valueColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: valueColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Section label for text areas
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey[600],
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
    );
  }

  // Get status info
  Map<String, dynamic> _getStatusInfo() {
    final status =
        (_dayOffData['status'] ?? 'pending').toString().toLowerCase();

    switch (status) {
      case 'approved':
        return {
          'text': 'Approved',
          'color': Colors.green[700]!,
        };
      case 'pending':
        return {
          'text': 'Pending',
          'color': Colors.orange[700]!,
        };
      case 'rejected':
      case 'denied':
        return {
          'text': 'Rejected',
          'color': Colors.red[700]!,
        };
      case 'cancelled':
        return {
          'text': 'Cancelled',
          'color': Colors.grey[700]!,
        };
      default:
        return {
          'text': status,
          'color': Colors.grey[700]!,
        };
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return date.toString();
      }

      return '${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';
    } catch (e) {
      return date.toString();
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  // Footer with divider and action buttons
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to day off edit page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit functionality coming soon'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
