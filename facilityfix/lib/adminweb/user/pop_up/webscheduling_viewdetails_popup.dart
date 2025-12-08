import 'package:flutter/material.dart';
import '../../services/api_service_web.dart';
import '../../../services/auth_storage.dart';

class WebSchedulingViewDetailsDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> scheduleData,
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
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
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
            child: _WebSchedulingViewDetailsContent(scheduleData: scheduleData),
          ),
        );
      },
    );
  }
}

class _WebSchedulingViewDetailsContent extends StatefulWidget {
  final Map<String, dynamic> scheduleData;

  const _WebSchedulingViewDetailsContent({required this.scheduleData});

  @override
  State<_WebSchedulingViewDetailsContent> createState() =>
      _WebSchedulingViewDetailsContentState();
}

class _WebSchedulingViewDetailsContentState
    extends State<_WebSchedulingViewDetailsContent> {
  late Map<String, dynamic> _scheduleData;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _scheduleData = Map<String, dynamic>.from(widget.scheduleData);
    _loadScheduleDetails();
  }

  Future<void> _loadScheduleDetails() async {
    try {
      final id =
          _scheduleData['id'] ??
          _scheduleData['scheduleId'] ??
          _scheduleData['_doc_id'];
      print('[SchedulingDetails] Loading full schedule details for ID: $id');

      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        _api.setAuthToken(token);
      }

      // TODO: Replace with actual API endpoint
      // final resp = await _api.getScheduleDetails(id.toString());
      // if (resp['success'] == true && resp['data'] is Map) {
      //   setState(() {
      //     _scheduleData = Map<String, dynamic>.from(resp['data']);
      //   });
      // }
    } catch (e) {
      print('[SchedulingDetails] Error loading schedule details: $e');
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
                // Header title
                _buildScheduleHeader(),
                const SizedBox(height: 12),
                _buildStaffAvailabilityOverview(),
                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Basic Info removed (now available in the overview above to avoid redundancy)
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Schedule Details Section
                _buildSectionTitle("Schedule Details"),
                const SizedBox(height: 16),
                _buildRequestDetailsGrid(),
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
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          const Text(
            'View Details of Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(_scheduleData),
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

  // Schedule header with title
  Widget _buildScheduleHeader() {
    final staffName =
        _scheduleData['staffName'] ?? _scheduleData['name'] ?? 'Staff Member';
    final id =
        _scheduleData['id'] ??
        _scheduleData['scheduleId'] ??
        _scheduleData['_doc_id'] ??
        'N/A';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          staffName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'ID: $id',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(width: 12),
            // Add Availability ID if present and different from ID
            Builder(
              builder: (ctx) {
                final availId =
                    _scheduleData['availability_id'] ??
                    _scheduleData['availabilityId'] ??
                    _scheduleData['avail_id'];
                if (availId == null || availId.toString().trim().isEmpty)
                  return const SizedBox.shrink();
                return Text(
                  'Availability ID: $availId',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // Small overview panel that summarizes the staff's availability
  Widget _buildStaffAvailabilityOverview() {
    final staffName =
        _scheduleData['staffName'] ?? _scheduleData['name'] ?? 'Staff Member';
    final department = _scheduleData['department'] ?? 'N/A';
    final weekDates = _formatWeekDates();
    final availability = _getAvailabilityStatus();
    final lastUpdated = _formatDate(
      _scheduleData['lastUpdated'] ?? _scheduleData['updated_at'],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      department,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(weekDates, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _statusChipWidget(
                    availability['text'] ?? '',
                    availability['color'] as Color,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  lastUpdated,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerDayAvailability() {
    // Determine availability map per day if present in payload
    Map<String, dynamic>? daysMap;
    // Try multiple possible field names
    final candidate =
        _scheduleData['per_day'] ??
        _scheduleData['dayAvailability'] ??
        _scheduleData['availability'] ??
        _scheduleData['availabilityData'];

    if (candidate is Map<String, dynamic>) {
      daysMap = candidate;
    } else if (candidate is List) {
      // Accept list of {day: 'Mon', available: true} objects
      daysMap = {};
      for (final el in candidate) {
        if (el is Map) {
          final day = (el['day'] ?? el['name'])?.toString();
          final available =
              el['available'] ?? el['isAvailable'] ?? el['status'];
          if (day != null) daysMap[day] = available;
        }
      }
    } else {
      return const SizedBox.shrink();
    }

    if (daysMap == null || daysMap.isEmpty) return const SizedBox.shrink();

    // Normalize keys: allow 'Monday'/'monday'/'MON' etc
    final normalized = <String, dynamic>{};
    daysMap.forEach((k, v) {
      try {
        final keyStr = k.toString().toLowerCase();
        final dayNames = [
          'monday',
          'tuesday',
          'wednesday',
          'thursday',
          'friday',
          'saturday',
          'sunday',
        ];
        final shortNames = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

        String normalizedKey = keyStr;
        for (int i = 0; i < dayNames.length; i++) {
          if (keyStr == dayNames[i] || keyStr == shortNames[i]) {
            normalizedKey = dayNames[i];
            break;
          }
        }
        normalized[normalizedKey] = v;
      } catch (e) {
        normalized[k.toString().toLowerCase()] = v;
      }
    });

    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final dayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final widgets = <Widget>[];
    for (int i = 0; i < dayNames.length; i++) {
      final val = normalized[dayKeys[i]];
      bool isAvail = false;
      String label = 'Unavailable';

      if (val is bool) {
        isAvail = val;
        label = isAvail ? 'Available' : 'Unavailable';
      } else if (val is String) {
        final low = val.toLowerCase();
        isAvail =
            low.contains('avail') ||
            low == 'true' ||
            low == '1' ||
            low == 'yes';
        label = isAvail ? 'Available' : 'Unavailable';
      }

      widgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          decoration: BoxDecoration(
            color: isAvail ? const Color(0xFFE7F7EF) : const Color(0xFFF5F6F7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isAvail ? const Color(0xFF0FAF62) : const Color(0xFFE5E6E8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayNames[i].substring(0, 3),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color:
                      isAvail
                          ? const Color(0xFF0FAF62)
                          : const Color(0xFF9AA0A6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF626C70), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _buildSectionTitle('Weekly Availability'),
        const SizedBox(height: 8),
        Wrap(children: widgets),
        const SizedBox(height: 12),
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
                "Staff Name",
                _scheduleData['staffName'] ?? _scheduleData['name'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _buildInfoTile(
                "Department",
                _scheduleData['department'] ?? 'N/A',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Request details grid
  Widget _buildRequestDetailsGrid() {
    final availabilityStatus = _getAvailabilityStatus();
    final weekDates = _formatWeekDates();
    final perDay = _buildPerDayAvailability();

    // Keep schedule details minimal to avoid duplication with the overview
    // Show supplemental fields (notes/remarks) or other non-duplicated info
    final note =
        (_scheduleData['notes'] ?? _scheduleData['remarks'] ?? '').toString();
    final extraFields = <Widget>[];
    if (note.trim().isNotEmpty) {
      extraFields.add(_buildInfoTile('Notes', note));
    }

    if (extraFields.isEmpty && perDay.runtimeType == SizedBox) {
      // Nothing extra to show — keep a minimal placeholder
      extraFields.add(
        const Text(
          'No additional schedule details available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...extraFields, perDay],
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

  // Get availability status
  Map<String, dynamic> _getAvailabilityStatus() {
    final status =
        (_scheduleData['statusAvailable'] ?? 'Available')
            .toString()
            .toLowerCase();

    switch (status) {
      case 'available':
        return {'text': 'Available', 'color': Colors.green[700]!};
      case 'partially available':
      case 'partial':
        return {'text': 'Partially Available', 'color': Colors.orange[700]!};
      case 'unavailable':
      case 'not available':
        return {'text': 'Unavailable', 'color': Colors.red[700]!};
      case 'on leave':
        return {'text': 'On Leave', 'color': Colors.blue[700]!};
      default:
        return {'text': status, 'color': Colors.grey[700]!};
    }
  }

  // Format week dates
  String _formatWeekDates() {
    final startDate =
        _scheduleData['weekStartDate'] ??
        _scheduleData['start_date'] ??
        _scheduleData['weekAvailability'];

    if (startDate == null) {
      return 'N/A';
    }

    try {
      DateTime dateTime;
      if (startDate is String) {
        dateTime = DateTime.parse(startDate);
      } else if (startDate is DateTime) {
        dateTime = startDate;
      } else {
        return startDate.toString();
      }

      // Calculate week start (Monday) and end (Sunday)
      final dayOfWeek = dateTime.weekday;
      final weekStart = dateTime.subtract(Duration(days: dayOfWeek - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      return '${_formatShortDate(weekStart)} - ${_formatShortDate(weekEnd)}';
    } catch (e) {
      return startDate.toString();
    }
  }

  String _formatShortDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _statusChipWidget(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
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

      final local = dateTime.toLocal();
      final datePart =
          '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)}';
      final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = _twoDigits(local.minute);
      final ampm = local.hour >= 12 ? 'PM' : 'AM';
      return '$datePart | ${hour12.toString().padLeft(2, '0')}:$minute $ampm';
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
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to schedule edit page
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
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
