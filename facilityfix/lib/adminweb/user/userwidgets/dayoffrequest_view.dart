import 'package:flutter/material.dart';

class DayOffRequestView extends StatefulWidget {
  const DayOffRequestView({super.key});

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

  // ---- Sample Day Off Request Data ----
  final List<Map<String, dynamic>> _dayOffRequests = [
    {
      'id': 'DOR-2024-001',
      'name': 'Juan Dela Cruz',
      'department': 'HVAC',
      'days': '3 Days',
      'status': 'Pending',
      'dateRequested': 'Nov 26, 2025',
      'startDate': 'Dec 1, 2025',
      'endDate': 'Dec 3, 2025',
      'reason': 'Family vacation',
      'staffNotes': 'Family visiting from abroad',
      'adminNote': null,
    },
    {
      'id': 'DOR-2024-002',
      'name': 'Carlos Mendoza',
      'department': 'Maintenance',
      'days': '1 Day',
      'status': 'Approved',
      'dateRequested': 'Nov 26, 2025',
      'startDate': 'Nov 30, 2025',
      'endDate': 'Nov 30, 2025',
      'reason': 'Medical appointment',
      'staffNotes': 'Doctor appointment 9AM',
      'adminNote': null,
    },
    {
      'id': 'DOR-2024-003',
      'name': 'Liza Rodriguez',
      'department': 'Electrical',
      'days': '7 Days',
      'status': 'Rejected',
      'dateRequested': 'Nov 26, 2025',
      'startDate': 'Dec 5, 2025',
      'endDate': 'Dec 11, 2025',
      'reason': 'Personal matters',
      'staffNotes': 'Urgent family matter',
      'adminNote': 'Insufficient coverage - please reschedule',
    },
    {
      'id': 'DOR-2024-005',
      'name': 'John Doe',
      'department': 'Plumbing',
      'days': '2 Days',
      'status': 'Pending',
      'dateRequested': 'Nov 26, 2025',
      'startDate': 'Dec 2, 2025',
      'endDate': 'Dec 3, 2025',
      'reason': 'Emergency leave',
      'staffNotes': 'Vehicle breakdown',
      'adminNote': null,
    },
    {
      'id': 'DOR-2024-006',
      'name': 'Jane Doe',
      'department': 'Masonry',
      'days': '4 Days',
      'status': 'Pending',
      'dateRequested': 'Nov 26, 2025',
      'startDate': 'Dec 10, 2025',
      'endDate': 'Dec 13, 2025',
      'reason': 'Holiday trip',
      'staffNotes': 'Family trip to Baguio',
      'adminNote': null,
    },
  ];

  // ---- Filtered Requests ----
  List<Map<String, dynamic>> get _filteredRequests {
    var filtered = _dayOffRequests;

    // Filter by status
    if (_selectedStatusFilter != 'All Requests') {
      filtered = filtered
          .where((request) => request['status'] == _selectedStatusFilter)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((request) =>
              request['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              request['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
              request['department'].toLowerCase().contains(_searchQuery.toLowerCase()))
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
    return filteredRequests.isEmpty ? 1 : (filteredRequests.length / _itemsPerPage).ceil();
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

  List<Widget> _buildPageNumbers() {
    List<Widget> pageButtons = [];
    
    int startPage = _currentPage - 2;
    int endPage = _currentPage + 2;
    
    if (startPage < 1) {
      startPage = 1;
      endPage = 5;
    }
    
    if (endPage > _totalPages) {
      endPage = _totalPages;
      startPage = _totalPages - 4;
    }
    
    if (startPage < 1) startPage = 1;
    
    for (int i = startPage; i <= endPage; i++) {
      pageButtons.add(
        GestureDetector(
          onTap: () => _goToPage(i),
          child: Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i == _currentPage ? const Color(0xFF1976D2) : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                i.toString().padLeft(2, '0'),
                style: TextStyle(
                  color: i == _currentPage ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return pageButtons;
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
      builder: (context) => AlertDialog(
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
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
              Icon(Icons.visibility_outlined, color: Colors.green[600], size: 18),
              const SizedBox(width: 12),
              Text('View', style: TextStyle(color: Colors.green[600], fontSize: 14)),
            ],
          ),
        ),
        if (isPending) ...[
          PopupMenuItem(
            value: 'approve',
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.blue[600], size: 18),
                const SizedBox(width: 12),
                Text('Approve', style: TextStyle(color: Colors.blue[600], fontSize: 14)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'reject',
            child: Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.orange[600], size: 18),
                const SizedBox(width: 12),
                Text('Reject', style: TextStyle(color: Colors.orange[600], fontSize: 14)),
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
              Text('Delete', style: TextStyle(color: Colors.red[600], fontSize: 14)),
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
        setState(() {
          request['status'] = 'Approved';
          request['adminNote'] = null; // clear any prior admin note when approved
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Approved request ${request['id']}'),
            backgroundColor: Colors.green,
          ),
        );
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
                content: Text('Rejected request ${request['id']}' + (note.trim().isNotEmpty ? ' (note added)' : '')),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
        break;
      case 'delete':
        setState(() {
          _dayOffRequests.removeWhere((r) => r['id'] == request['id']);
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

  Future<String?> _promptForAdminNote(BuildContext context, Map<String, dynamic> request) async {
    final TextEditingController ctrl = TextEditingController(text: request['adminNote'] ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add reject note for ${request['id']}'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Enter admin reject notes...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Submit')),
        ],
      ),
    );
    // Return trimmed text; null if cancelled.
    return result;
  }

  // ---- Handle Checkbox Toggle ----
  void _toggleCheckbox(String requestId, bool isPending) {
    if (!isPending) return; // Only allow checkbox for pending requests
    
    setState(() {
      if (_selectedRequests.contains(requestId)) {
        _selectedRequests.remove(requestId);
      } else {
        _selectedRequests.add(requestId);
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
          if (request['status'] == 'Pending') {
            _selectedRequests.add(request['id']);
          }
        }
      } else {
        // Deselect all pending requests on current page
        for (var request in _getPaginatedRequests()) {
          if (request['status'] == 'Pending') {
            _selectedRequests.remove(request['id']);
          }
        }
      }
    });
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
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
                      items: _statusFilterOptions.map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedStatusFilter = newValue;
                            _currentPage = 1; // Reset to first page on filter change
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
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
                  width: 40,
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
          _filteredRequests.isEmpty
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
                    final isPending = request['status'] == 'Pending';
                    final isSelected = _selectedRequests.contains(request['id']);

                    return InkWell(
                      onTap: () => _handleRequestClick(request),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Checkbox (only for pending requests)
                            SizedBox(
                              width: 40,
                              child: isPending
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        _toggleCheckbox(request['id'], isPending);
                                      },
                                      activeColor: const Color(0xFF1976D2),
                                    )
                                  : const SizedBox(), // Empty space for non-pending
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
                                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
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
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                                        buttonContext.findRenderObject() as RenderBox;
                                    final position = button.localToGlobal(Offset.zero);
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
                  _filteredRequests.isEmpty
                      ? "No day off requests found"
                      : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredRequests.length ? _filteredRequests.length : _currentPage * _itemsPerPage} of ${_filteredRequests.length} requests",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _currentPage > 1 ? _previousPage : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: _currentPage > 1 ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                    ..._buildPageNumbers(),
                    IconButton(
                      onPressed: _currentPage < _totalPages ? _nextPage : null,
                      icon: Icon(
                        Icons.chevron_right,
                        color: _currentPage < _totalPages ? Colors.grey[600] : Colors.grey[400],
                      ),
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