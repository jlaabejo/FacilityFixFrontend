import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SetResolutionTypeDialog {
  static void show(
    BuildContext context,
    Map<String, dynamic> concernSlip, {
    VoidCallback? onSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SetResolutionTypeDialogContent(
        concernSlip: concernSlip,
        onSuccess: onSuccess,
      ),
    );
  }
}

class _SetResolutionTypeDialogContent extends StatefulWidget {
  final Map<String, dynamic> concernSlip;
  final VoidCallback? onSuccess;

  const _SetResolutionTypeDialogContent({
    required this.concernSlip,
    this.onSuccess,
  });

  @override
  State<_SetResolutionTypeDialogContent> createState() =>
      _SetResolutionTypeDialogContentState();
}

class _SetResolutionTypeDialogContentState
    extends State<_SetResolutionTypeDialogContent> {
  final ApiService _apiService = ApiService();
  final TextEditingController _notesController = TextEditingController();
  
  String? _selectedResolutionType;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitResolutionType() async {
    if (_selectedResolutionType == null) {
      _showSnackBar('Please select a resolution type', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _apiService.setResolutionType(
        widget.concernSlip['id'],
        resolutionType: _selectedResolutionType!,
        adminNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar(
          'Resolution type set successfully. Status changed to "Sent".',
        );
        widget.onSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnackBar('Failed to set resolution type: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set Resolution Type',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Concern Slip Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Concern: ${widget.concernSlip['formatted_id'] ?? widget.concernSlip['id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.concernSlip['title'] ?? 'No title',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Resolution Type Selection
            const Text(
              'Select Resolution Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildResolutionTypeOption(
              type: 'job_service',
              title: 'Job Service',
              description: 'Assign to internal staff for immediate service',
              icon: Icons.engineering,
              color: Colors.blue,
            ),
            
            const SizedBox(height: 12),
            
            _buildResolutionTypeOption(
              type: 'work_order',
              title: 'Work Order',
              description: 'Create work order permit for external contractors',
              icon: Icons.assignment,
              color: Colors.orange,
            ),
            
            const SizedBox(height: 24),

            // Admin Notes
            const Text(
              'Admin Notes (Optional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add any additional notes...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitResolutionType,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionTypeOption({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedResolutionType == type;
    
    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : () => setState(() => _selectedResolutionType = type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            // Radio button
            Radio<String>(
              value: type,
              groupValue: _selectedResolutionType,
              onChanged: _isSubmitting
                  ? null
                  : (value) => setState(() => _selectedResolutionType = value),
              activeColor: color,
            ),
            
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            
            const SizedBox(width: 16),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
