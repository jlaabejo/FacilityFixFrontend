import 'package:flutter/material.dart';
import '../../widgets/tags.dart';

class InventoryRequestDetailsDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> requestData,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5,
            constraints: const BoxConstraints(
              maxWidth: 700,
              maxHeight: 700,
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
            child: _InventoryRequestDetailsContent(requestData: requestData),
          ),
        );
      },
    );
  }
}

class _InventoryRequestDetailsContent extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const _InventoryRequestDetailsContent({required this.requestData});

  @override
  State<_InventoryRequestDetailsContent> createState() =>
      _InventoryRequestDetailsContentState();
}

class _InventoryRequestDetailsContentState
    extends State<_InventoryRequestDetailsContent> {
  late Map<String, dynamic> _requestData;

  @override
  void initState() {
    super.initState();
    _requestData = Map<String, dynamic>.from(widget.requestData);
  }

  /// Format request ID to show as REQ-XXXXX
  String _formatRequestId(dynamic id) {
    if (id == null || id.toString() == 'N/A') return 'N/A';
    
    final idStr = id.toString();
    
    // If already formatted (starts with REQ-), return as is
    if (idStr.toUpperCase().startsWith('REQ-')) {
      return idStr.toUpperCase();
    }
    
    // If it's a Firebase document ID (long alphanumeric), take last 8 chars
    if (idStr.length > 15) {
      return 'REQ-${idStr.substring(idStr.length - 8).toUpperCase()}';
    }
    
    // If it's a short ID, format with padding
    if (idStr.length <= 5) {
      return 'REQ-${idStr.padLeft(5, '0')}';
    }
    
    // Otherwise, use as is with REQ- prefix
    return 'REQ-$idStr';
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
                // Request header with ID and Status
                _buildRequestHeader(),
                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Request Information Section
                _buildSectionTitle("Request Information"),
                const SizedBox(height: 12),
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            "Item Name", _requestData['itemName'] ?? 'N/A'),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: _buildInfoTile(
                            "Maintenance Task ID",
                            _requestData['maintenanceTaskId']?.toString() ?? 'No Maintenance Task',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoTile("Quantity Requested",
                          _requestData['quantityRequested']?.toString() ?? '0'),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: _buildInfoTile("Quantity Approved",
                          _requestData['quantityApproved']?.toString() ?? '0'),
                    ),
                  ],
                ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Requester Details
                _buildSectionTitle("Requester Details"),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildInfoTile("Staff Name",
                          _requestData['requestedBy'] ?? 
                          _requestData['requested_by'] ?? 
                          _requestData['requester_name'] ?? 
                          _requestData['staff_name'] ?? 
                          'Unknown'),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      child: _buildInfoTile("Staff Department",
                          _requestData['staffDepartment'] ?? 
                          _requestData['staff_department'] ?? 
                          _requestData['department'] ?? 
                          _requestData['requester_department'] ?? 
                          'N/A'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Admin Response
                _buildSectionTitle("Admin Response"),
                const SizedBox(height: 12),
                _buildInfoTile("Response Date",
                    _requestData['approvedDate'] ?? 'N/A'),

                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Additional Notes
                _buildSectionTitle("Additional Notes"),
                const SizedBox(height: 12),
                if (_requestData['adminNotes'] != null &&
                    _requestData['adminNotes'].toString().isNotEmpty &&
                    _requestData['adminNotes'] != 'No notes')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      _requestData['adminNotes'].toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  )
                else
                  Text(
                    'No additional notes',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        // Footer with action buttons
        _buildFooter(),
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
            'Request Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
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

  // Request header with ID and status
  Widget _buildRequestHeader() {
    final rawRequestId = _requestData['requestId'] ?? _requestData['_doc_id'] ?? _requestData['id'] ?? 'N/A';
    final requestId = _formatRequestId(rawRequestId);
    final itemName = _requestData['itemName'] ?? 'Unknown Item';
    final status = (_requestData['status'] ?? 'pending').toString();
    final requestedDate = _requestData['requestedDate'] ?? 'N/A';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                requestId,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Date Requested: $requestedDate',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        StatusTag(status),
      ],
    );
  }

  // Footer with divider and action buttons
  Widget _buildFooter() {
    final status = (_requestData['status'] ?? 'pending').toString().toLowerCase();
    final isPending = status == 'pending';

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
          if (isPending) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop({
                  'action': 'reject',
                  'requestData': _requestData,
                });
              },
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[600],
                side: BorderSide(color: Colors.red[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop({
                  'action': 'approve',
                  'requestData': _requestData,
                });
              },
              icon: const Icon(Icons.check_circle_outline, size: 16),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
            ),
          ] else
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {Color? valueColor}) {
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
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
