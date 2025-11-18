import 'dart:async';
import 'dart:convert';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
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

  int _selectedIndex = 2;
  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

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
    final apiService = APIService(roleOverride: AppRole.staff);
    final taskId = widget.task['id'];

    if (taskId == null || taskId.isEmpty) {
      print('DEBUG: No task ID available for loading inventory reservations');
      return;
    }

    // First, try the staff-visible endpoint for inventory requests tied to the maintenance task.
    try {
      print('DEBUG: Loading inventory requests for task $taskId');
      final respRequests = await apiService.getInventoryRequestsByMaintenanceTask(taskId.toString());
      if (respRequests['success'] == true && respRequests['data'] != null) {
        final requests = List<Map<String, dynamic>>.from(respRequests['data']);
        // Enrich with item details
        for (var r in requests) {
          if (r['inventory_id'] != null) {
            try {
              final itemData = await apiService.getInventoryItemById(r['inventory_id']);
              if (itemData != null) {
                r['item_name'] = itemData['item_name'] ?? itemData['name'] ?? '';
                r['item_code'] = itemData['item_code'] ?? itemData['code'] ?? '';
                r['stock_quantity'] = itemData['available_stock'] ?? itemData['stock'] ?? itemData['current_stock'] ?? itemData['stock_quantity'] ?? 'N/A';
                r['stock_status'] = itemData['status'] ?? itemData['stock_status'] ?? 'Unknown';
              }
            } catch (e) {
              print('DEBUG: Error loading item details for request: $e');
            }
          }
        }

        if (requests.isNotEmpty) {
          // Mark as reservations for maintenance tasks (staff receives them)
          for (var r in requests) {
            r['type'] = 'reservation';
          }
          setState(() {
            _inventoryRequests = requests;
          });
          print('DEBUG: Loaded ${_inventoryRequests.length} inventory reservations for maintenance');
          print('DEBUG: First reservation type: ${requests.first['type']}');
          return; // data found, no need to check reservations
        }
      }
    } catch (e) {
      print('DEBUG: Error loading inventory requests for maintenance task: $e');
      // continue to check reservations below
    }

    // If no requests found, check if there are admin reservations for this task
    try {
      print('DEBUG: Checking for admin inventory reservations for task $taskId');
      final adminApiService = APIService(roleOverride: AppRole.admin);
      final response = await adminApiService.getInventoryReservations(maintenanceTaskId: taskId);
      if (response['success'] == true && response['data'] != null) {
        final reservations = List<Map<String, dynamic>>.from(response['data']);
        print('DEBUG: Raw reservation data: ${reservations.first}');
        // Enrich with item details
        for (var r in reservations) {
          if (r['inventory_id'] != null) {
            try {
              final itemData = await apiService.getInventoryItemById(r['inventory_id']);
              if (itemData != null) {
                r['item_name'] = itemData['item_name'] ?? itemData['name'] ?? '';
                r['item_code'] = itemData['item_code'] ?? itemData['code'] ?? '';
                r['stock_quantity'] = itemData['available_stock'] ?? itemData['stock'] ?? itemData['current_stock'] ?? itemData['stock_quantity'] ?? 'N/A';
                r['stock_status'] = itemData['status'] ?? itemData['stock_status'] ?? 'Unknown';
              }
            } catch (e) {
              print('DEBUG: Error loading item details for reservation: $e');
            }
          }
        }
        if (reservations.isNotEmpty) {
          // Mark as reservations
          for (var r in reservations) {
            r['type'] = 'reservation';
          }
          setState(() {
            _inventoryRequests = reservations; // Show reservations as requests in UI
          });
          print('DEBUG: Loaded ${reservations.length} admin inventory reservations for staff view');
          print('DEBUG: First reservation type: ${reservations.first['type']}');
        }
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Admin access required') || msg.contains('admin')) {
        print('DEBUG: Reservations endpoint requires admin access; staff cannot view reservations.');
        // set a flag visible to the UI so we can show a message if desired
        holdMeta['reservations_admin_only'] = true;
      } else {
        print('DEBUG: Error checking inventory reservations: $e');
      }
    }
  }
  
  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
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
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentForm(
          concernSlipId: widget.task['id'] ?? '',
          concernSlipData: widget.task,
          requestType: 'Maintenance Task',
          showResolutionType: false,
        ),
      ),
    );

    // After returning from the assessment form, refresh the task details
    // from the server so the UI reflects the newly created assessment and
    // updated status (e.g., completed). We also reload inventory reservations
    // and rebuild _checklistItems from the fresh data.
    try {
      final apiService = APIService(roleOverride: AppRole.staff);
      final taskId = widget.task['id'];
      if (taskId != null && taskId.toString().isNotEmpty) {
        final fresh = await apiService.getMaintenanceTaskById(taskId.toString());

  if (fresh.isNotEmpty) {
          // Merge fresh values into the existing task map so callers using
          // the same Map reference (this.widget.task) observe changes.
          fresh.forEach((k, v) {
            widget.task[k] = v;
          });

          // Recompute derived state
          setState(() {
            _checklistItems = _convertChecklistToMap(widget.task['checklist_completed'], widget.task['category'] ?? 'general');
          });

          // Reload inventory requests as these may have changed too
          await _loadInventoryRequests();
        }
      }
    } catch (e) {
      print('DEBUG: Failed to refresh task after assessment: $e');
      // Not fatal - inventory and checklist may be slightly out-of-date.
    }
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

  Future<void> _handleInventoryAction(Map<String, dynamic> request, String action) async {
    final requestId = request['_doc_id'] ?? request['id'] ?? request['_id'] ?? request['request_id'] ?? request['reservation_id'];
    final itemType = request['type'] ?? 'unknown';
    
    print('DEBUG: _handleInventoryAction called with action: $action, type: $itemType, requestId: $requestId');
    
    if (requestId == null) {
      print('DEBUG: Request keys: ${request.keys.toList()}');
      print('DEBUG: Request map: $request'); // Add debug print
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request ID not found')),
      );
      return;
    }

    try {
      final apiService = APIService();

      if (action == 'receive') {
        if (itemType == 'reservation') {
          print('DEBUG: Calling markReservationReceived for reservation $requestId');
          // Mark reservation as received
          final response = await apiService.markReservationReceived(requestId);
          
          if (response['success'] == true) {
            // Deduct stock from inventory after marking as received
            final inventoryId = request['inventory_id'];
            final quantityReceived = request['quantity'] ?? 1; // Default to 1 if not specified
            
            print('DEBUG: Deducting stock - inventoryId: $inventoryId, quantity: $quantityReceived');
            
            if (inventoryId != null && quantityReceived > 0) {
              try {
                // Get current inventory item data
                final itemResp = await apiService.getInventoryItemById(inventoryId);
                if (itemResp != null) {
                  final currentStock = (itemResp['current_stock'] ?? itemResp['quantity_in_stock'] ?? 0) as num;
                  
                  // Calculate new stock (deduct the received quantity)
                  final newStock = (currentStock - quantityReceived).toInt();
                  
                  // Update the inventory item with new stock
                  await apiService.updateInventoryItem(inventoryId, {
                    'current_stock': newStock,
                    'quantity_in_stock': newStock,
                  });
                  
                  print('DEBUG: Stock deducted for reservation: $inventoryId, Old: $currentStock, New: $newStock');
                }
              } catch (stockError) {
                print('DEBUG: Error deducting stock for reservation: $stockError');
                // Reservation was marked as received, but stock deduction failed - log but don't fail the whole operation
              }
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reservation received successfully')),
            );
            // Reload inventory requests to reflect changes
            await _loadInventoryRequests();
          } else {
            throw Exception(response['message'] ?? 'Failed to receive reservation');
          }
        } else {
          // For requests, show message that receive is only for reservations
          print('DEBUG: Receive action called on non-reservation item (type: $itemType)');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receive is only available for reserved items')),
          );
          return; // Don't proceed
        }
      } else if (action == 'request') {
        // Show request sheet to get details
        final result = await showModalBottomSheet<RequestResult>(
          context: context,
          isScrollControlled: true,
          builder: (ctx) => RequestItem(
            itemName: request['item_name'] ?? 'Unknown Item',
            itemId: request['inventory_id'] ?? '',
            unit: request['unit'] ?? 'pcs',
            stock: request['stock_quantity']?.toString() ?? '0',
            maintenanceId: widget.task['id'],
            staffName: widget.task['assigned_staff_name'] ?? widget.task['assigned_to'] ?? 'Unknown Staff',
          ),
        );

        if (result != null) {
          // Create a new request for the same item
          final itemId = request['inventory_id'];
          final quantity = int.tryParse(result.quantity) ?? 1;

          final response = await apiService.createInventoryRequest(
            inventoryId: itemId,
            buildingId: 'default_building_id', // TODO: Get actual building ID
            quantityRequested: quantity,
            purpose: result.notes ?? 'Additional request for maintenance task ${widget.task['id']}',
            requestedBy: widget.currentStaffId,
            maintenanceTaskId: widget.task['id'],
            status: 'pending', // Additional requests need admin approval
          );

          if (response['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Additional request submitted')),
            );
            // Reload inventory requests
            await _loadInventoryRequests();
          } else {
            throw Exception(response['message'] ?? 'Failed to submit request');
          }
        }
      }
    } catch (e) {
      print('Error handling inventory action: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
  // Determine whether an assessment exists (completion notes or staff photos)
  // and only expose an assessedAt timestamp to the details widget when
  // there's actually an assessment recorded.
  final bool _hasAssessment =
    (widget.task['completion_notes'] != null &&
      widget.task['completion_notes'].toString().trim().isNotEmpty) ||
    (widget.task['photos'] is List && (widget.task['photos'] as List).isNotEmpty);

  final DateTime? _assessedAtForDetails = _hasAssessment ? _parseDate(widget.task['updated_at']) : null;
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
                assessedAt: _assessedAtForDetails,
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
                onInventoryAction: _handleInventoryAction,
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
                  widget.task['status'] == 'new' ||
                  widget.task['status'] == 'completed' ||
                  widget.task['status'] == 'done'))
            SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: SizedBox(
                  width: double.infinity,
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
            ),
          NavBar(
            items: _navItems,
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}