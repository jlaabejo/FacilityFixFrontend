import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/config/env.dart';
import 'package:facilityfix/staff/form/assessment_form.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/view_details.dart';
import 'package:facilityfix/widgets/modals.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:flutter/material.dart';

// Maintenance Detail Screen using MaintenanceDetails widget
class MaintenanceDetailPage extends StatefulWidget {
  final Map<String, dynamic> task;
  final String currentStaffId;

  const MaintenanceDetailPage({
    Key? key,
    required this.task,
    required this.currentStaffId,
  }) : super(key: key);

  @override
  State<MaintenanceDetailPage> createState() => _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends State<MaintenanceDetailPage> {
  late List<Map<String, dynamic>> _checklistItems;
  bool _isUpdating = false;
  List<Map<String, dynamic>> _inventoryRequests = [];
  Map<String, dynamic> holdMeta = {};

  @override
  void initState() {
    super.initState();
    print('DEBUG: MaintenanceDetailScreen initState called');
    print('DEBUG: Task data keys: ${widget.task.keys.toList()}');
    print('DEBUG: Raw checklist_completed value: ${widget.task['checklist_completed']}');
    print('DEBUG: Raw checklist_completed type: ${widget.task['checklist_completed'].runtimeType}');
    _checklistItems = _convertChecklistToMap(widget.task['checklist_completed'], widget.task['category'] ?? 'general');
    print('DEBUG: Converted checklist items: $_checklistItems');
    print('DEBUG: Checklist items count: ${_checklistItems.length}');

    // Load inventory requests for this task
    _loadInventoryRequests();
  }

  Future<void> _loadInventoryRequests() async {
    try {
      final apiService = APIService(roleOverride: AppRole.staff);
      final taskId = widget.task['id'];

      if (taskId == null || taskId.isEmpty) {
        print('DEBUG: No task ID available for loading inventory requests');
        return;
      }

      print('DEBUG: Loading inventory requests for task $taskId');
      final response = await apiService.getInventoryRequestsByMaintenanceTask(taskId);

      if (response['success'] == true && response['data'] != null) {
        final requests = List<Map<String, dynamic>>.from(response['data']);

        // Enrich with item details and stock information
        for (var request in requests) {
          if (request['inventory_id'] != null) {
            try {
              final itemData = await apiService.getInventoryItemById(request['inventory_id']);
              if (itemData != null) {
                request['item_name'] = itemData['item_name'];
                request['item_code'] = itemData['item_code'];
                // Add stock information
                request['stock_quantity'] = itemData['quantity'] ?? itemData['stock_quantity'] ?? 'N/A';
                request['stock_status'] = itemData['status'] ?? itemData['stock_status'] ?? 'Unknown';
              }
            } catch (e) {
              print('DEBUG: Error loading item details: $e');
            }
          }
        }

        setState(() {
          _inventoryRequests = requests;
        });

        print('DEBUG: Loaded ${_inventoryRequests.length} inventory requests');
      }
    } catch (e) {
      print('DEBUG: Error loading inventory requests: $e');
    }
  }
  
  // Computed properties for checklist progress
  // Only count items visible to current user
  int get completedCount => _checklistItems.where((item) {
    final assignedTo = item['assigned_to']?.toString() ?? '';
    final isVisibleToMe = assignedTo.isEmpty || assignedTo == widget.currentStaffId;
    return isVisibleToMe && item['completed'] == true;
  }).length;

  int get totalCount => _checklistItems.where((item) {
    final assignedTo = item['assigned_to']?.toString() ?? '';
    return assignedTo.isEmpty || assignedTo == widget.currentStaffId;
  }).length;

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime? date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp);
    } else if (timestamp.runtimeType.toString().contains('Timestamp')) {
      // Handle Firestore Timestamp
      try {
        date = (timestamp as dynamic).toDate();
      } catch (e) {
        print('Error converting Timestamp: $e');
      }
    }
    
    return date?.toIso8601String() ?? '';
  }

  List<Map<String, dynamic>> _convertChecklistToMap(dynamic checklist, String category) {
    print('DEBUG _convertChecklistToMap: Input checklist: $checklist');
    print('DEBUG _convertChecklistToMap: Input type: ${checklist.runtimeType}');
    
    if (checklist == null) {
      print('DEBUG _convertChecklistToMap: checklist is null, returning empty list');
      return [];
    }
    
    if (checklist is! List) {
      print('DEBUG _convertChecklistToMap: checklist is not a List (is ${checklist.runtimeType}), returning empty list');
      return [];
    }
    
    print('DEBUG _convertChecklistToMap: checklist is a List with ${checklist.length} items');
    
    final result = checklist
        .where((item) {
          final isMap = item is Map;
          print('DEBUG _convertChecklistToMap: Item is Map? $isMap, item: $item');
          return isMap;
        })


        .map<Map<String, dynamic>>((item) {
          final converted = <String, dynamic>{
            'id': item['id']?.toString() ?? '',
            'task': item['task']?.toString() ?? '',
            'completed': item['completed'] == true,
          };
          final assigned = item['assigned_to'];

          if (assigned != null && assigned.toString().trim().isNotEmpty && category == 'safety') {
            converted['assigned_to'] = assigned.toString();
          }
          return converted;
        })
        .where((item) {
          final hasId = item['id'].toString().isNotEmpty;
          print('DEBUG _convertChecklistToMap: Item has ID? $hasId');
          return hasId;
        })
        .toList();
    
    print('DEBUG _convertChecklistToMap: Final result count: ${result.length}');
    return result;
  }

  Future<void> _toggleChecklistItem(int index) async {
    if (_isUpdating) return;

    setState(() => _isUpdating = true);

    try {
      final item = _checklistItems[index];
      final newCompletedStatus = !item['completed'];

      // Optimistically update UI
      setState(() {
        _checklistItems[index]['completed'] = newCompletedStatus;
      });

      // Update via API
      final apiService = APIService(roleOverride: AppRole.staff);
      await apiService.updateChecklistItem(
        taskId: widget.task['id'],
        itemId: item['id'],
        completed: newCompletedStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newCompletedStatus
                ? 'Task marked as completed'
                : 'Task marked as incomplete'
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error updating checklist item: $e');

      // Revert optimistic update on error
      setState(() {
        _checklistItems[index]['completed'] = !_checklistItems[index]['completed'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating checklist: ${e.toString()}'),
            backgroundColor: Colors.red,
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

  Future<void> _onHoldPressed() async {
    // Check if currently on hold
    bool isOnHold = widget.task['status'] == 'on_hold';

    if (isOnHold) {
      // Resume task - set status back to assigned
      try {
        final apiService = APIService(roleOverride: AppRole.staff);
        final token = await AuthStorage.getToken();
        if (token == null) {
          throw Exception('Authentication required');
        }

        final response = await http.patch(
          Uri.parse('${apiService.baseUrl}/maintenance-tasks/${widget.task['id']}'),
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
          widget.task['status'] = 'assigned';
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
          Uri.parse('${apiService.baseUrl}/maintenance-tasks/${widget.task['id']}'),
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
          widget.task['status'] = 'on_hold';
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
    // Navigate to the assessment form page with maintenance task data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentForm(
          concernSlipId: widget.task['id'] ?? '',
          concernSlipData: widget.task,
          requestType: 'Maintenance Task',
          showResolutionType: false,
        ),
      ),
    ).then((_) {
      // Refresh data when returning from assessment form
      _loadInventoryRequests();
    });
  }

  void _showInventoryItemModal(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            final itemName = request['item_name'] ?? 'Unknown Item';
            final itemCode = request['item_code'] ?? 'N/A';
            final quantityRequested = request['quantity_requested'] ?? 0;
            final status = request['status'] ?? 'pending';
            final notes = request['notes'] ?? '';
            
            // Stock information (if available)
            final stockQuantity = request['stock_quantity'] ?? 'N/A';
            final stockStatus = request['stock_status'] ?? 'Unknown';

            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              itemName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Item Code: $itemCode',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Request Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Quantity Requested', '$quantityRequested'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Status', status.toUpperCase()),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stock Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Stock Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Available Stock', stockQuantity.toString()),
                        const SizedBox(height: 8),
                        _buildInfoRow('Stock Status', stockStatus),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Additional Notes
                  if (notes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Additional Notes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            notes,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: const BackButton(),
        title: 'Maintenance Details',
        actions: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checklist Progress Banner
              if (_checklistItems.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: completedCount == totalCount 
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: completedCount == totalCount
                          ? const Color(0xFF10B981)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        completedCount == totalCount
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        size: 20,
                        color: completedCount == totalCount
                            ? const Color(0xFF10B981)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        completedCount == totalCount
                            ? 'All tasks completed! 🎉'
                            : 'Checklist Progress: $completedCount of $totalCount completed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: completedCount == totalCount
                              ? const Color(0xFF047857)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
              
              // Use MaintenanceDetails widget - it has its own SingleChildScrollView
              MaintenanceDetails(
                // Basic Information
                id: widget.task['id'] ?? '',
                createdAt: _parseDate(widget.task['created_at']) ?? DateTime.now(),
                updatedAt: _parseDate(widget.task['updated_at']),
                departmentTag: widget.task['category'] ?? widget.task['department'],
                requestTypeTag: widget.task['maintenance_type'] ?? widget.task['maintenanceType'] ?? 'internal',
                priority: widget.task['priority'],
                statusTag: widget.task['status'] ?? 'scheduled',
                
                // Tenant / Requester
                requestedBy: widget.task['created_by'] ?? widget.task['assigned_to'] ?? '',
                scheduleDate: _formatTimestamp(widget.task['scheduled_date']),
                
                // Request Details
                title: widget.task['task_title'] ?? widget.task['title'] ?? 'Maintenance Task',
                startedAt: _parseDate(widget.task['started_at']),
                completedAt: _parseDate(widget.task['completed_at']),
                location: widget.task['location'],
                description: widget.task['task_description'] ?? widget.task['description'],
                attachments: widget.task['photos'] is List 
                    ? (widget.task['photos'] as List).map((e) => e.toString()).toList()
                    : null,
                adminNote: widget.task['completion_notes'],
                
                // Staff
                assignedStaff: widget.task['assigned_staff_name'] ?? widget.task['assigned_to'],
                staffDepartment: widget.task['department'],
                staffPhotoUrl: null,
                assessedAt: _parseDate(widget.task['updated_at']),
                assessment: widget.task['completion_notes'],
                staffAttachments: widget.task['photos'] is List 
                    ? (widget.task['photos'] as List).map((e) => e.toString()).toList()
                    : null,
                
                // Tracking
                materialsUsed: widget.task['parts_used'] is List 
                    ? (widget.task['parts_used'] as List).map((e) => e.toString()).toList()
                    : null,
                
                // Interactive checklist and inventory
                checklistItems: _checklistItems,
                inventoryRequests: _inventoryRequests,
                completedCount: completedCount,
                totalCount: totalCount,
                isUpdating: _isUpdating,
                onToggleChecklistItem: _toggleChecklistItem,
                onInventoryItemTap: _showInventoryItemModal,
                currentStaffId: widget.currentStaffId,
                taskCategory: widget.task['category'],
                
                // Action callbacks
                onHold: (widget.task['status'] == 'pending' ||
                        widget.task['status'] == 'scheduled' || 
                        widget.task['status'] == 'assigned' ||
                        widget.task['status'] == 'new' ||
                        widget.task['status'] == 'in_progress' || 
                        widget.task['status'] == 'on_hold')
                    ? _onHoldPressed
                    : null,
                onCreateAssessment: (widget.task['status'] == 'pending' ||
                                    widget.task['status'] == 'scheduled' || 
                                    widget.task['status'] == 'assigned' ||
                                    widget.task['status'] == 'new' ||
                                    widget.task['status'] == 'in_progress' || 
                                    widget.task['status'] == 'on_hold')
                    ? _createAssessment
                    : null,
              ),
            
            ],
          ),
        ),
      ),
      // Bottom bar: On Hold and Create Assessment (similar to Concern Slip)
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.task['assigned_to'] != null &&
              (widget.task['status'] == 'assigned' ||
                  widget.task['status'] == 'on_hold' ||
                  widget.task['status'] == 'pending' ||
                  widget.task['status'] == 'in_progress' ||
                  widget.task['status'] == 'scheduled' ||
                  widget.task['status'] == 'new'))
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
                          label: holdMeta.isNotEmpty && widget.task['status'] == 'on_hold' ? 'Resume Task' : 'On Hold',
                          icon: holdMeta.isNotEmpty && widget.task['status'] == 'on_hold' ? Icons.play_arrow : Icons.pause,
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
        ],
      ),
    );
  }
}