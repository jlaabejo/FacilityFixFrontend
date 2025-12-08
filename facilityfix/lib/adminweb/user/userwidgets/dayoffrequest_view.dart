import 'dart:math';
import 'package:facilityfix/services/api_services_mobile.dart';
import 'package:flutter/material.dart';

class DayOffRequestView extends StatefulWidget {
  final VoidCallback? onChange;
  const DayOffRequestView({super.key, this.onChange});

  @override
  State<DayOffRequestView> createState() => _DayOffRequestViewState();
}

class _DayOffRequestViewState extends State<DayOffRequestView> {
  String _searchQuery = '';
  String _selectedStatusFilter = 'All Requests';
  Set<String> _selectedRequests = {};
  bool _selectAll = false;

  // ---- Pagination ----
  int _currentPage = 1;
  final int _itemsPerPage = 7;

  // ---- Status Filter Options ----
  final List<String> _statusFilterOptions = [
    'All Requests',
    'Pending',
    'Approved',
    'Rejected',
  ];

  List<Map<String, dynamic>> _dayOffRequests = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDayOffRequests();
  }

  Future<void> _loadDayOffRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });

      final apiService = APIService();
      var requests = await apiService.getDayOffRequests();

      // Enrich requests with staff user data
      requests = await _enrichRequestsWithUserData(requests, apiService);

      if (mounted) {
        setState(() {
          _dayOffRequests = _mapApiResponseToTableFormat(requests);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  /// Enrich day off requests with staff user information
  Future<List<Map<String, dynamic>>> _enrichRequestsWithUserData(
    List<Map<String, dynamic>> requests,
    APIService apiService,
  ) async {
    final enrichedRequests = <Map<String, dynamic>>[];

    for (final request in requests) {
      final enrichedRequest = Map<String, dynamic>.from(request);

      // Check if we have a user_id or staff_id to fetch user details
      final userId = request['user_id'] ?? request['staff_id'];

      if (userId != null && userId.toString().isNotEmpty) {
        try {
          final userData = await apiService.getUserById(userId.toString());
          if (userData != null) {
            // Add user data to the request for name extraction
            enrichedRequest['_user_data'] = userData;

            // Also add individual fields for easy access
            enrichedRequest['first_name'] = userData['first_name'];
            enrichedRequest['last_name'] = userData['last_name'];
            enrichedRequest['email'] = userData['email'];
          }
        } catch (e) {
          print('[DEBUG] Failed to fetch user data for $userId: $e');
          // Continue with incomplete data; fallbacks will handle this
        }
      }

      enrichedRequests.add(enrichedRequest);
    }

    return enrichedRequests;
  }

  List<Map<String, dynamic>> _mapApiResponseToTableFormat(
    List<Map<String, dynamic>> apiRequests,
  ) {
    return apiRequests.map((request) {
      final requestDate = request['request_date'] as String?;
      final requestedAt = request['requested_at'] as String?;

      // Parse dates for display
      String formatDate(String? dateStr) {
        if (dateStr == null) return 'N/A';
        try {
          final date = DateTime.parse(dateStr);
          return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        } catch (e) {
          return dateStr;
        }
      }

      // Calculate number of days
      int calculateDays(String? dateStr) {
        if (dateStr == null) return 0;
        try {
          final date = DateTime.parse(dateStr);
          final today = DateTime.now();
          final difference = date.difference(today).inDays;
          return difference > 0 ? difference + 1 : 1;
        } catch (e) {
          return 1;
        }
      }

      // Extract staff name from the API response with comprehensive fallbacks
      String getStaffName() {
        // Priority 1: Direct staff_name field
        if (request['staff_name'] != null &&
            request['staff_name'].toString().isNotEmpty &&
            request['staff_name'].toString() != 'Unknown') {
          return request['staff_name'].toString();
        }

        // Priority 2: Enriched user data from getUserById
        if (request['_user_data'] is Map<String, dynamic>) {
          final userData = request['_user_data'] as Map<String, dynamic>;
          final firstName = userData['first_name']?.toString().trim() ?? '';
          final lastName = userData['last_name']?.toString().trim() ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            return '$firstName $lastName'.trim();
          }
        }

        // Priority 3: Nested user/staff object with name fields
        if (request['user'] is Map<String, dynamic>) {
          final user = request['user'] as Map<String, dynamic>;
          final firstName = user['first_name']?.toString().trim() ?? '';
          final lastName = user['last_name']?.toString().trim() ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            return '$firstName $lastName'.trim();
          }
          if (user['full_name'] != null &&
              user['full_name'].toString().isNotEmpty) {
            return user['full_name'].toString();
          }
          if (user['name'] != null && user['name'].toString().isNotEmpty) {
            return user['name'].toString();
          }
        }

        // Priority 4: Staff nested object
        if (request['staff'] is Map<String, dynamic>) {
          final staff = request['staff'] as Map<String, dynamic>;
          final firstName = staff['first_name']?.toString().trim() ?? '';
          final lastName = staff['last_name']?.toString().trim() ?? '';
          if (firstName.isNotEmpty || lastName.isNotEmpty) {
            return '$firstName $lastName'.trim();
          }
          if (staff['full_name'] != null &&
              staff['full_name'].toString().isNotEmpty) {
            return staff['full_name'].toString();
          }
          if (staff['name'] != null && staff['name'].toString().isNotEmpty) {
            return staff['name'].toString();
          }
        }

        // Priority 5: Top-level first_name and last_name fields
        final firstName = request['first_name']?.toString().trim() ?? '';
        final lastName = request['last_name']?.toString().trim() ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          return '$firstName $lastName'.trim();
        }

        // Priority 6: Top-level name or full_name field
        if (request['name'] != null && request['name'].toString().isNotEmpty) {
          return request['name'].toString();
        }
        if (request['full_name'] != null &&
            request['full_name'].toString().isNotEmpty) {
          return request['full_name'].toString();
        }

        // Priority 7: Display staff_id if name cannot be determined (for debugging)
        final staffId =
            request['staff_id']?.toString() ?? request['user_id']?.toString();
        if (staffId != null && staffId.isNotEmpty) {
          return 'Staff #$staffId';
        }

        // Final fallback
        return 'Unknown Staff';
      }

      return {
        'id': request['formatted_id'] ?? request['id'] ?? 'N/A',
        'name': getStaffName(),
        'department': request['department'] ?? 'N/A',
        'days':
            '${calculateDays(request['request_date'])} Day${calculateDays(request['request_date']) > 1 ? 's' : ''}',
        'status': request['status'] ?? 'Pending',
        'dateRequested': formatDate(requestedAt ?? request['created_at']),
        'startDate': formatDate(request['request_date']),
        'endDate': formatDate(request['request_date']),
        'reason': request['reason'] ?? 'N/A',
        'staffNotes': request['description'] ?? request['reason'] ?? 'N/A',
        'adminNote': request['admin_notes'],
        'requestId': request['id'], // Store actual ID for API calls
      };
    }).toList();
  }

  // ---- Filtered Requests ----
  List<Map<String, dynamic>> get _filteredRequests {
    var filtered = _dayOffRequests;

    // Filter by status
    if (_selectedStatusFilter != 'All Requests') {
      filtered =
          filtered
              .where(
                (request) =>
                    request['status']?.toString().toLowerCase() ==
                    _selectedStatusFilter.toLowerCase(),
              )
              .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (request) =>
                    (request['name']?.toString() ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (request['id']?.toString() ?? '').toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (request['department']?.toString() ?? '')
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()),
              )
              .toList();
    }

    return filtered;
  }

  // ---- Pagination Helper Methods ----
  List<Map<String, dynamic>> _getPaginatedRequests() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    final filteredRequests = _filteredRequests;
    if (startIndex >= filteredRequests.length) return [];

    return filteredRequests.sublist(
      startIndex,
      endIndex > filteredRequests.length ? filteredRequests.length : endIndex,
    );
  }

  int get _totalPages {
    final filteredRequests = _filteredRequests;
    return filteredRequests.isEmpty
        ? 1
        : (filteredRequests.length / _itemsPerPage).ceil();
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  // ---- Build Status Badge ----
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (status) {
      case 'Pending':
        bgColor = Colors.orange[50]!;
        borderColor = Colors.orange[300]!;
        textColor = Colors.orange[700]!;
        break;
      case 'Approved':
        bgColor = Colors.green[50]!;
        borderColor = Colors.green[300]!;
        textColor = Colors.green[700]!;
        break;
      case 'Rejected':
        bgColor = Colors.red[50]!;
        borderColor = Colors.red[300]!;
        textColor = Colors.red[700]!;
        break;
      default:
        bgColor = Colors.grey[50]!;
        borderColor = Colors.grey[300]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  // ---- Handle Request Click ----
  void _handleRequestClick(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Request ${request['id']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Name:', request['name']),
                  _buildDetailRow('Department:', request['department']),
                  _buildDetailRow('Days:', request['days']),
                  _buildDetailRow('Start Date:', request['startDate']),
                  _buildDetailRow('End Date:', request['endDate']),
                  _buildDetailRow('Status:', request['status']),
                  _buildDetailRow('Date Requested:', request['dateRequested']),
                  _buildDetailRow('Reason:', request['reason']),
                  _buildDetailRow('Staff Notes:', request['staffNotes'] ?? '—'),
                  _buildDetailRow('Admin Notes:', request['adminNote'] ?? '—'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // ---- Show Action Menu ----
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> request,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final bool isPending = request['status'] == 'Pending';

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: Colors.green[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'View',
                style: TextStyle(color: Colors.green[600], fontSize: 14),
              ),
            ],
          ),
        ),
        if (isPending) ...[
          PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.blue[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Approve',
                  style: TextStyle(color: Colors.blue[600], fontSize: 14),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Colors.orange[600],
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Reject',
                  style: TextStyle(color: Colors.orange[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[600], size: 18),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(color: Colors.red[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
    ).then((value) {
      if (value != null) {
        _handleActionSelection(value, request);
      }
    });
  }

  void _handleActionSelection(String action, Map<String, dynamic> request) {
    switch (action) {
      case 'view':
        _handleRequestClick(request);
        break;
      case 'approve':
        _confirmApprove(request);
        break;
      case 'reject':
        _promptForAdminNote(context, request).then((note) {
          if (note != null) {
            setState(() {
              request['status'] = 'Rejected';
              request['adminNote'] = note.trim().isEmpty ? null : note.trim();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Rejected request ${request['id']}' +
                      (note.trim().isNotEmpty ? ' (note added)' : ''),
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
        break;
      case 'delete':
        setState(() {
          _dayOffRequests.removeWhere(
            (r) => r['requestId'] == request['requestId'],
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted request ${request['id']}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  Future<void> _confirmApprove(Map<String, dynamic> request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Approve Request ${request['id']}'),
            content: Text('Approve day-off request for ${request['name']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Approve'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final apiService = APIService();
      final response = await apiService.approveDayOffRequest(
        request['requestId'].toString(),
      );
      // Update UI only when the backend call succeeds
      if (response['request_id'] != null) {
        setState(() {
          request['status'] = 'Approved';
          request['adminNote'] = null;
        });
        // Notify parent to refresh overview / staff availability on admin page
        widget.onChange?.call();
        // Attempt to reload list to reflect any schedule availability changes
        await _loadDayOffRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved request ${request['id']}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approve failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _promptForAdminNote(
    BuildContext context,
    Map<String, dynamic> request,
  ) async {
    final TextEditingController ctrl = TextEditingController(
      text: request['adminNote'] ?? '',
    );
    final result = await showDialog<String?>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Add reject note for ${request['id']}'),
            content: TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter admin reject notes...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text('Submit'),
              ),
            ],
          ),
    );
    // Return trimmed text; null if cancelled.
    return result;
  }

  // ---- Handle Checkbox Toggle ----
  void _toggleCheckbox(String? requestId, bool isPending) {
    // Ensure requestId is a non-null, non-empty String
    final id = (requestId ?? '').toString();
    if (!isPending || id.isEmpty) return;
    setState(() {
      if (_selectedRequests.contains(id)) {
        _selectedRequests.remove(id);
      } else {
        _selectedRequests.add(id);
      }
    });
  }

  // ---- Toggle Select All ----
  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        // Select all pending requests on current page
        for (var request in _getPaginatedRequests()) {
          if (request['status']?.toString().toLowerCase() == 'pending') {
            _selectedRequests.add(request['requestId']);
          }
        }
      } else {
        // Deselect all pending requests on current page
        for (var request in _getPaginatedRequests()) {
          if (request['status']?.toString().toLowerCase() == 'pending') {
            _selectedRequests.remove(request['requestId']);
          }
        }
      }
    });
  }

  // ---- Build Page Numbers ----
  List<Widget> _buildPageNumbers() {
    final pages = <Widget>[];
    final totalPages = _totalPages;

    // Show first page
    if (_currentPage > 1) {
      pages.add(
        TextButton(onPressed: () => _goToPage(1), child: const Text('1')),
      );
      if (_currentPage > 3) {
        pages.add(const Text('...'));
      }
    }

    // Show current page and neighbors
    for (
      int i = max(1, _currentPage - 1);
      i <= min(totalPages, _currentPage + 1);
      i++
    ) {
      if (i == _currentPage) {
        pages.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$i',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        );
      } else {
        pages.add(TextButton(onPressed: () => _goToPage(i), child: Text('$i')));
      }
    }

    // Show last page
    if (_currentPage < totalPages - 1) {
      if (_currentPage < totalPages - 2) {
        pages.add(const Text('...'));
      }
      pages.add(
        TextButton(
          onPressed: () => _goToPage(totalPages),
          child: Text('$totalPages'),
        ),
      );
    }

    return pages;
  }

  Future<void> _bulkApproveDayOffRequests() async {
    if (_selectedRequests.isEmpty) return;

    final selectedIds = _selectedRequests.toList();

    // Show confirmation dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Approve Day Off Requests'),
            content: Text(
              'Are you sure you want to approve ${selectedIds.length} day-off request(s)? The staff members will be notified.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _processApprovalsForDayOff(selectedIds);
                },
                child: const Text('Approve'),
              ),
            ],
          ),
    );
  }

  Future<void> _bulkRejectDayOffRequests() async {
    if (_selectedRequests.isEmpty) return;

    final selectedIds = _selectedRequests.toList();

    // Show rejection reason dialog
    String rejectionReason = '';
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reject Day Off Requests'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to reject ${selectedIds.length} day-off request(s)?',
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => rejectionReason = value,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter rejection reason...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (rejectionReason.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a rejection reason'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await _processRejectionsForDayOff(
                    selectedIds,
                    rejectionReason,
                  );
                },
                child: const Text('Reject'),
              ),
            ],
          ),
    );
  }

  Future<void> _processApprovalsForDayOff(List<String> requestIds) async {
    setState(() => _isLoading = true);

    try {
      final apiService = APIService();
      final result = await apiService.bulkApproveDayOffRequests(requestIds);

      final successCount = result['approved_count'] ?? 0;
      final failureCount = result['failed_count'] ?? 0;
      final errors = result['errors'] ?? [];

      setState(() {
        _isLoading = false;
        _selectedRequests.clear();
        _selectAll = false;
      });

      await _loadDayOffRequests();

      // Show results dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Bulk Approval Complete'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Successfully approved: $successCount',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (failureCount > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Failed: $failureCount',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (errors is List && errors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: SingleChildScrollView(
                            child: Text(
                              'Failed requests:\n${errors.join('\n')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk approval: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processRejectionsForDayOff(
    List<String> requestIds,
    String reason,
  ) async {
    setState(() => _isLoading = true);

    try {
      final apiService = APIService();
      final result = await apiService.bulkRejectDayOffRequests(
        requestIds,
        reason,
      );

      final successCount = result['rejected_count'] ?? 0;
      final failureCount = result['failed_count'] ?? 0;
      final errors = result['errors'] ?? [];

      setState(() {
        _isLoading = false;
        _selectedRequests.clear();
        _selectAll = false;
      });

      await _loadDayOffRequests();

      // Show results dialog
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Bulk Rejection Complete'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Successfully rejected: $successCount',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (failureCount > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Failed: $failureCount',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (errors is List && errors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: SingleChildScrollView(
                            child: Text(
                              'Failed requests:\n${errors.join('\n')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk rejection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Title and Filters
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Day Off Request Manager',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // Search Field
                Container(
                  width: 300,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPage = 1; // Reset to first page on search
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search staff...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Status Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      items:
                          _statusFilterOptions.map((String status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(
                                status,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatusFilter = newValue;
                            _currentPage =
                                1; // Reset to first page on filter change
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading Indicator
          if (_isLoading) Center(child: CircularProgressIndicator()),
          // Error Message
          if (_loadError != null)
            Center(
              child: Text(
                'Error loading day off requests: $_loadError',
                style: TextStyle(color: Colors.red),
              ),
            ),
          // Table Header
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Checkbox column header
                SizedBox(
                  width: 48,
                  child: Checkbox(
                    value: _selectAll,
                    onChanged: _toggleSelectAll,
                    activeColor: const Color(0xFF1976D2),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'REQUEST ID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DEPARTMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'DAYS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'NOTES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'DATE REQUESTED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // ADMIN NOTES column removed from table header (kept in view dialog only)
                const SizedBox(width: 48), // Space for menu icon
              ],
            ),
          ),

          // Table Body
          _filteredRequests.isEmpty && !_isLoading && _loadError == null
              ? Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No day off requests found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _getPaginatedRequests().length,
                itemBuilder: (context, index) {
                  final request = _getPaginatedRequests()[index];
                  final isPending =
                      request['status']?.toString().toLowerCase() == 'pending';
                  // Always use a non-null, non-empty String for requestId
                  final String requestId =
                      (request['requestId'] ?? request['id'] ?? '').toString();
                  final isSelected =
                      requestId.isNotEmpty &&
                      _selectedRequests.contains(requestId);

                  return InkWell(
                    onTap: () => _handleRequestClick(request),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox (only for pending requests)
                          SizedBox(
                            width: 48,
                            child:
                                isPending
                                    ? Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        _toggleCheckbox(requestId, isPending);
                                      },
                                      activeColor: const Color(0xFF1976D2),
                                    )
                                    : Checkbox(
                                      value:
                                          false, // Render unchecked for non-pending
                                      onChanged: null, // Disable interaction
                                    ),
                          ),
                          // Request ID
                          Expanded(
                            flex: 2,
                            child: Text(
                              request['id'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Name
                          Expanded(
                            flex: 2,
                            child: Text(
                              request['name'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          // Department
                          Expanded(
                            flex: 2,
                            child: Text(
                              request['department'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          // Days
                          Expanded(
                            flex: 1,
                            child: Text(
                              request['days'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          // Staff notes
                          Expanded(
                            flex: 3,
                            child: Text(
                              request['staffNotes'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _buildStatusBadge(request['status']),
                            ),
                          ),
                          // Date Requested
                          Expanded(
                            flex: 2,
                            child: Text(
                              request['dateRequested'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          // Admin notes column removed from table; value still visible in view details
                          // Menu Icon
                          Builder(
                            builder: (BuildContext buttonContext) {
                              return IconButton(
                                icon: const Icon(Icons.more_vert),
                                iconSize: 20,
                                color: Colors.grey[600],
                                onPressed: () {
                                  final RenderBox button =
                                      buttonContext.findRenderObject()
                                          as RenderBox;
                                  final position = button.localToGlobal(
                                    Offset.zero,
                                  );
                                  _showActionMenu(context, request, position);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

          // Footer with Pagination
          Divider(height: 1, thickness: 1, color: Colors.grey[400]),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _filteredRequests.isEmpty && !_isLoading && _loadError == null
                      ? "No day off requests found"
                      : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredRequests.length ? _filteredRequests.length : _currentPage * _itemsPerPage} of ${_filteredRequests.length} requests",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton(
                        onPressed:
                            _selectedRequests.isNotEmpty
                                ? _bulkApproveDayOffRequests
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedRequests.isNotEmpty
                                  ? Colors.green[600]
                                  : Colors.grey[300],
                          disabledBackgroundColor: Colors.grey[300],
                          foregroundColor:
                              _selectedRequests.isNotEmpty
                                  ? Colors.white
                                  : Colors.grey[600],
                          disabledForegroundColor: Colors.grey[600],
                          elevation: _selectedRequests.isNotEmpty ? 2 : 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Approve',
                          style: TextStyle(
                            color:
                                _selectedRequests.isNotEmpty
                                    ? Colors.white
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: ElevatedButton(
                        onPressed:
                            _selectedRequests.isNotEmpty
                                ? _bulkRejectDayOffRequests
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _selectedRequests.isNotEmpty
                                  ? Colors.red[600]
                                  : Colors.grey[300],
                          disabledBackgroundColor: Colors.grey[300],
                          foregroundColor:
                              _selectedRequests.isNotEmpty
                                  ? Colors.white
                                  : Colors.grey[600],
                          disabledForegroundColor: Colors.grey[600],
                          elevation: _selectedRequests.isNotEmpty ? 2 : 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Reject',
                          style: TextStyle(
                            color:
                                _selectedRequests.isNotEmpty
                                    ? Colors.white
                                    : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    // Previous button (disable when on first page)
                    IconButton(
                      onPressed:
                          _currentPage > 1
                              ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                              : null,
                      icon: const Icon(Icons.chevron_left),
                      color: _currentPage > 1 ? Colors.blue : Colors.grey[400],
                      disabledColor: Colors.grey[300],
                    ),
                    // Page numbers (1-based indexing)
                    ...List.generate(_totalPages, (index) {
                      final pageNum = index + 1;
                      final isCurrent = _currentPage == pageNum;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _currentPage = pageNum;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  isCurrent ? Colors.blue : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color:
                                    isCurrent ? Colors.blue : Colors.grey[300]!,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$pageNum',
                              style: TextStyle(
                                color:
                                    isCurrent ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    // Next button (disable when on last page)
                    IconButton(
                      onPressed:
                          _currentPage < _totalPages
                              ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                              : null,
                      icon: const Icon(Icons.chevron_right),
                      color:
                          _currentPage < _totalPages
                              ? Colors.blue
                              : Colors.grey[400],
                      disabledColor: Colors.grey[300],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
