import 'dart:async';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/buttons.dart' as custom_buttons;
import 'package:facilityfix/widgets/cards.dart';
import 'package:facilityfix/widgets/tag.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:flutter/material.dart';

class MaintenanceDetailPage extends StatefulWidget {
  final String maintenanceTaskId;

  const MaintenanceDetailPage({
    super.key,
    required this.maintenanceTaskId,
  });

  @override
  State<MaintenanceDetailPage> createState() => _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends State<MaintenanceDetailPage> {
  Map<String, dynamic>? _maintenanceTask;
  bool _isLoading = true;
  bool _isUpdating = false;

  // Status update form
  String _selectedStatus = '';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _completionNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaintenanceTaskDetails();
  }

  Future<void> _loadMaintenanceTaskDetails() async {
    setState(() => _isLoading = true);

    try {
      final apiService = APIService(roleOverride: AppRole.staff);
      
      // Get maintenance task details by ID
      final task = await apiService.getMaintenanceTaskById(widget.maintenanceTaskId);
      
      if (mounted) {
        setState(() {
          _maintenanceTask = task;
          // Normalize status to match dropdown values
          final apiStatus = task['status'] ?? 'scheduled';
          _selectedStatus = _normalizeStatusForDropdown(apiStatus);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading maintenance task details: $e');
      if (mounted) {
        setState(() {
          _maintenanceTask = null;
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading maintenance task: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Helper method to normalize status values between API and dropdown
  String _normalizeStatusForDropdown(String apiStatus) {
    switch (apiStatus.toLowerCase().trim()) {
      case 'in progress':
      case 'in_progress':
        return 'in_progress';
      case 'completed':
      case 'done':
        return 'completed';
      case 'scheduled':
      case 'new':
        return 'scheduled';
      case 'on hold':
      case 'on_hold':
        return 'on_hold';
      case 'cancelled':
      case 'canceled':
        return 'cancelled';
      default:
        return 'scheduled';
    }
  }

  // Helper method to convert dropdown value back to API format
  String _normalizeStatusForAPI(String dropdownStatus) {
    switch (dropdownStatus) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'scheduled':
        return 'Scheduled';
      case 'on_hold':
        return 'On Hold';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  Future<void> _updateMaintenanceTask() async {
    if (_maintenanceTask == null) return;

    setState(() => _isUpdating = true);

    try {
      final apiService = APIService(roleOverride: AppRole.staff);
      
      // Prepare update data
      final updateData = <String, dynamic>{
        'status': _normalizeStatusForAPI(_selectedStatus),
      };

      // Add notes if provided
      if (_notesController.text.trim().isNotEmpty) {
        updateData['completion_notes'] = _notesController.text.trim();
      }

      // Add completion notes if status is completed
      if (_selectedStatus == 'completed' && _completionNotesController.text.trim().isNotEmpty) {
        updateData['completion_notes'] = _completionNotesController.text.trim();
      }

      // Add timestamps based on status
      final now = DateTime.now().toIso8601String();
      if (_selectedStatus == 'in_progress' && _maintenanceTask!['started_at'] == null) {
        updateData['started_at'] = now;
      } else if (_selectedStatus == 'completed' && _maintenanceTask!['completed_at'] == null) {
        updateData['completed_at'] = now;
      }

      await apiService.updateMaintenanceTask(widget.maintenanceTaskId, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maintenance task updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Refresh the task details
        await _loadMaintenanceTaskDetails();
      }
    } catch (e) {
      print('Error updating maintenance task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating task: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Maintenance Task'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'on_hold', child: Text('On Hold')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? 'scheduled';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Work Notes (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Add work progress notes...',
                ),
                maxLines: 3,
              ),
              if (_selectedStatus == 'completed') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _completionNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Completion Notes',
                    border: OutlineInputBorder(),
                    hintText: 'Describe work completed...',
                  ),
                  maxLines: 3,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isUpdating 
                ? null 
                : () {
                    Navigator.of(context).pop();
                    _updateMaintenanceTask();
                  },
            child: _isUpdating 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: const Color(0xFF6B7280)),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '—';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  @override
  void dispose() {
    _notesController.dispose();
    _completionNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: CustomAppBar(
        title: 'Maintenance Details',
        actions: [
          if (_maintenanceTask != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showUpdateDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _maintenanceTask == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Color(0xFF9CA3AF),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Maintenance task not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The requested maintenance task could not be loaded.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMaintenanceTaskDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _maintenanceTask!['task_title'] ?? 
                                          _maintenanceTask!['title'] ?? 
                                          'Maintenance Task',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _maintenanceTask!['formatted_id'] ?? 
                                          _maintenanceTask!['id'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      StatusTag(status: _maintenanceTask!['status'] ?? 'scheduled'),
                                      const SizedBox(height: 8),
                                      if (_maintenanceTask!['priority'] != null)
                                        PriorityTag(priority: _maintenanceTask!['priority']),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Task Information
                        _buildSection(
                          'Task Information',
                          [
                            _buildInfoRow(
                              'Description',
                              _maintenanceTask!['task_description'] ?? 
                              _maintenanceTask!['description'] ?? '',
                              icon: Icons.description,
                            ),
                            _buildInfoRow(
                              'Location',
                              _maintenanceTask!['location'] ?? '',
                              icon: Icons.place,
                            ),
                            _buildInfoRow(
                              'Category',
                              _maintenanceTask!['category'] ?? '',
                              icon: Icons.category,
                            ),
                            _buildInfoRow(
                              'Type',
                              _maintenanceTask!['maintenanceType'] ?? 
                              _maintenanceTask!['maintenance_type'] ?? '',
                              icon: Icons.build,
                            ),
                            _buildInfoRow(
                              'Recurrence',
                              _maintenanceTask!['recurrence_type'] ?? 'none',
                              icon: Icons.repeat,
                            ),
                          ],
                        ),

                        // Scheduling Information
                        _buildSection(
                          'Scheduling',
                          [
                            _buildInfoRow(
                              'Scheduled Date',
                              _formatDate(_maintenanceTask!['scheduled_date']),
                              icon: Icons.schedule,
                            ),
                            _buildInfoRow(
                              'Started At',
                              _formatDate(_maintenanceTask!['started_at']),
                              icon: Icons.play_arrow,
                            ),
                            _buildInfoRow(
                              'Completed At',
                              _formatDate(_maintenanceTask!['completed_at']),
                              icon: Icons.check_circle,
                            ),
                            _buildInfoRow(
                              'Estimated Duration',
                              _formatDuration(_maintenanceTask!['estimated_duration']),
                              icon: Icons.timer,
                            ),
                            _buildInfoRow(
                              'Actual Duration',
                              _formatDuration(_maintenanceTask!['actual_duration']),
                              icon: Icons.timer_outlined,
                            ),
                          ],
                        ),

                        // Work Details
                        if (_maintenanceTask!['completion_notes'] != null ||
                            (_maintenanceTask!['parts_used'] as List?)?.isNotEmpty == true ||
                            (_maintenanceTask!['tools_used'] as List?)?.isNotEmpty == true)
                          _buildSection(
                            'Work Details',
                            [
                              if (_maintenanceTask!['completion_notes'] != null)
                                _buildInfoRow(
                                  'Completion Notes',
                                  _maintenanceTask!['completion_notes'] ?? '',
                                  icon: Icons.note,
                                ),
                              if ((_maintenanceTask!['parts_used'] as List?)?.isNotEmpty == true)
                                _buildInfoRow(
                                  'Parts Used',
                                  (_maintenanceTask!['parts_used'] as List)
                                      .map((part) => part.toString())
                                      .join(', '),
                                  icon: Icons.engineering,
                                ),
                              if ((_maintenanceTask!['tools_used'] as List?)?.isNotEmpty == true)
                                _buildInfoRow(
                                  'Tools Used',
                                  (_maintenanceTask!['tools_used'] as List)
                                      .join(', '),
                                  icon: Icons.handyman,
                                ),
                            ],
                          ),

                        const SizedBox(height: 32),

                        // Update Button
                        if (_maintenanceTask!['status'] != 'completed')
                          SizedBox(
                            width: double.infinity,
                            child: custom_buttons.FilledButton(
                              label: 'Update Task Status',
                              onPressed: _showUpdateDialog,
                              leadingIcon: Icons.edit,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}