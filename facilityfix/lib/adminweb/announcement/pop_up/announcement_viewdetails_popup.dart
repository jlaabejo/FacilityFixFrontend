import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AnnouncementDetailDialog extends StatefulWidget {
  final Map<String, dynamic> announcement;
  final BuildContext rootContext;

  const AnnouncementDetailDialog({
    super.key,
    required this.announcement,
    required this.rootContext,
  });

  @override
  State<AnnouncementDetailDialog> createState() => _AnnouncementDetailDialogState();

  // Static method to show the dialog
  static void show(BuildContext context, Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AnnouncementDetailDialog(
          announcement: announcement,
          rootContext: context,
        );
      },
    );
  }
}

class _AnnouncementDetailDialogState extends State<AnnouncementDetailDialog> {
  bool isPinnedToDashboard = false;

  @override
  void initState() {
    super.initState();
    // Initialize pin state from announcement data
    isPinnedToDashboard = widget.announcement['isPinned'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        constraints: const BoxConstraints(
          maxWidth: 900,
          maxHeight: 800,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Section
            _buildHeader(context),

            // Content Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Announcement Title
                    Text(
                      widget.announcement['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Audience and Type Row
                    _buildAudienceAndTypeRow(),
                    const SizedBox(height: 32),

                    // Location and Schedule Row
                    _buildLocationAndScheduleRow(),
                    const SizedBox(height: 32),

                    // Divider
                    Divider(
                      color: Colors.grey[300],
                      thickness: 1,
                      height: 1,
                    ),
                    const SizedBox(height: 32),

                    // Message Body Section
                    _buildMessageBody(),
                    const SizedBox(height: 32),

                    // Attachments Section (if any)
                    if (widget.announcement['attachments'] != null && 
                        (widget.announcement['attachments'] as List).isNotEmpty)
                      _buildAttachmentsSection(),
                  ],
                ),
              ),
            ),

            // Footer Section
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  // Header with title and close button
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 24, bottom: 16),
      child: Row(
        children: [
          const Text(
            'Announcement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.grey,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // Audience and announcement type chips
  Widget _buildAudienceAndTypeRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audience Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Audience',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              _buildAudienceChips(),
            ],
          ),
        ),
        const SizedBox(width: 48),
        
        // Announcement Type Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Announcement Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              _buildAnnouncementTypeChip(widget.announcement['type'] ?? 'General'),
            ],
          ),
        ),
      ],
    );
  }

  // Location and schedule information
  Widget _buildLocationAndScheduleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Section
        Expanded(
          child: _buildDetailItem(
            'Location Affected (Optional)',
            widget.announcement['location'] ?? 'Not specified',
          ),
        ),
        const SizedBox(width: 48),
        
        // Schedule Visibility Section
        Expanded(
          child: _buildDetailItem(
            'Schedule Visibility',
            _formatScheduleVisibility(),
          ),
        ),
      ],
    );
  }

  // Message body content
  Widget _buildMessageBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Announcement Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            widget.announcement['messageBody'] ?? 
            'No message content available.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  // Attachments section
  Widget _buildAttachmentsSection() {
    final attachments = widget.announcement['attachments'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...attachments.map((attachment) => _buildAttachmentItem(attachment)),
      ],
    );
  }

  // Individual attachment item
  Widget _buildAttachmentItem(Map<String, dynamic> attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // PDF Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.picture_as_pdf,
              color: Colors.red[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment['name'] ?? 'Document.pdf',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  attachment['size'] ?? '0 KB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Download button
          IconButton(
            onPressed: () => _downloadAttachment(attachment),
            icon: Icon(
              Icons.download,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // Footer with pin toggle and action buttons
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Pin to Dashboard toggle
          Row(
            children: [
              Icon(
                Icons.push_pin,
                color: isPinnedToDashboard ? Colors.red[600] : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Pin to Dashboard',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Keep visible at top',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: isPinnedToDashboard,
                onChanged: (value) => _togglePin(value),
                activeColor: Colors.blue[600],
              ),
            ],
          ),
          const Spacer(),
          
          // Action button
          OutlinedButton.icon(
            onPressed: () => _editAnnouncement(),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build audience chips
  Widget _buildAudienceChips() {
    final audiences = widget.announcement['audiences'] as List? ?? ['All'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: audiences.map((audience) {
        return _buildAudienceChip(audience.toString());
      }).toList(),
    );
  }

  // Individual audience chip
  Widget _buildAudienceChip(String audience) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (audience.toLowerCase()) {
      case 'tenants':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        icon = Icons.people;
        break;
      case 'maintenance staff':
      case 'staff':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.build;
        break;
      case 'all':
      default:
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF7B1FA2);
        icon = Icons.group;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            audience,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Announcement type chip
  Widget _buildAnnouncementTypeChip(String type) {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (type.toLowerCase()) {
      case 'maintenance':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.build;
        break;
      case 'utility interruption':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1976D2);
        icon = Icons.flash_off;
        break;
      case 'safety inspection':
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFFF8F00);
        icon = Icons.security;
        break;
      case 'power outage':
        bgColor = const Color(0xFFE1F5FE);
        textColor = const Color(0xFF0277BD);
        icon = Icons.power_off;
        break;
      case 'pest control':
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFFF8F00);
        icon = Icons.pest_control;
        break;
      case 'general announcement':
      case 'general':
      default:
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFFF8F00);
        icon = Icons.campaign;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            type,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build detail items
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Format schedule visibility
  String _formatScheduleVisibility() {
    final scheduledPublishDate = widget.announcement['scheduled_publish_date'];
    final expiryDate = widget.announcement['expiry_date'];
    
    if (scheduledPublishDate == null && expiryDate == null) {
      return 'No schedule specified';
    }
    
    final String startText = scheduledPublishDate != null 
        ? _formatDate(scheduledPublishDate)
        : 'Not scheduled';
    final String endText = expiryDate != null 
        ? _formatDate(expiryDate)
        : 'No expiry';
    
    return '$startText - $endText';
  }

  // Helper method to format date
  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Event handlers for backend integration
  void _togglePin(bool value) async {
    // Update the state first
    setState(() {
      isPinnedToDashboard = value;
    });
    
    // Update backend API to persist the pin status
    await _updateAnnouncementPinStatus(widget.announcement['id'], value);
    
    // Close the dialog
    if (mounted) {
      Navigator.of(context).pop();
    
      // Show the snackbar
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  value 
                    ? 'Announcement pinned to dashboard' 
                    : 'Announcement unpinned from dashboard',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: value ? const Color(0xFF66BB6A) : const Color(0xFF9E9E9E),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 24,
            bottom: 24,
            right: MediaQuery.of(widget.rootContext).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
          elevation: 2,
        ),
      );
    }
  }

  void _editAnnouncement() {
    Navigator.of(context).pop();
    
    // Get the database_id from the announcement data
    final announcementId = widget.announcement['database_id'] ?? widget.announcement['id'];
    
    if (announcementId != null) {
      // Navigate to edit page using the root context
      widget.rootContext.go('/announcement/edit/$announcementId');
    } else {
      // Show error if no ID is found with minimalist styling
      ScaffoldMessenger.of(widget.rootContext).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Flexible(
                child: Text(
                  'Cannot edit: Announcement ID not found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            left: 24,
            bottom: 24,
            right: MediaQuery.of(widget.rootContext).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
          elevation: 2,
        ),
      );
    }
  }

  void _downloadAttachment(Map<String, dynamic> attachment) {
    // TODO: Implement attachment download
    
    // Show snackbar in the root context (outside dialog)
    ScaffoldMessenger.of(widget.rootContext).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                'Downloading ${attachment['name']}...',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF42A5F5),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 24,
          bottom: 24,
          right: MediaQuery.of(widget.rootContext).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        elevation: 2,
      ),
    );
    print('Download attachment: ${attachment['name']}');
  }

  // Backend API methods (implement these according to your backend)
  Future<void> _updateAnnouncementPinStatus(String id, bool isPinned) async {
    // TODO: Implement API call to update pin status
    try {
      // Example API call structure:
      // await AnnouncementService.updatePinStatus(id, isPinned);
      print('Updating pin status for announcement $id to $isPinned');
    } catch (e) {
      print('Error updating pin status: $e');
    }
  }
}