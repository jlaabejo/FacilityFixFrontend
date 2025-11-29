import 'package:flutter/material.dart';
import '../../widgets/tags.dart';
import '../../services/api_service.dart';
import 'maintenance_history_details_popup.dart';
import '../../../services/auth_storage.dart';
import 'package:go_router/go_router.dart';

class EquipmentViewDetailsDialog {
  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    Map<String, dynamic> equipmentData,
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
              maxWidth: 900,
              maxHeight: 800,
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
            child: _EquipmentViewDetailsContent(equipmentData: equipmentData),
          ),
        );
      },
    );
  }
}

class _EquipmentViewDetailsContent extends StatefulWidget {
  final Map<String, dynamic> equipmentData;

  const _EquipmentViewDetailsContent({required this.equipmentData});

  @override
  State<_EquipmentViewDetailsContent> createState() =>
      _EquipmentViewDetailsContentState();
}

class _EquipmentViewDetailsContentState
    extends State<_EquipmentViewDetailsContent> {
  late Map<String, dynamic> _equipmentData;
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _buildingInventory = [];
  String? _buildingId;

  @override
  void initState() {
    super.initState();
    _equipmentData = Map<String, dynamic>.from(widget.equipmentData);
    _loadEquipmentDetails();
    _initBuildingInventory();
  }

  Future<void> _initBuildingInventory() async {
    try {
      final profile = await AuthStorage.getProfile();
      _buildingId = profile != null ? (profile['building_id'] ?? profile['buildingId'] ?? profile['building'])?.toString() : null;
      final resp = await _api.getInventoryItems(buildingId: _buildingId ?? 'default_building_id');
      if (resp['success'] == true && resp['data'] is List) {
        setState(() {
          _buildingInventory = List<Map<String, dynamic>>.from(resp['data']);
        });
      }
    } catch (e) {
      print('[EquipmentDetails] Failed to load building inventory: $e');
    }
  }

  Future<void> _loadEquipmentDetails() async {
    try {
      final id = _equipmentData['id'] ??
          _equipmentData['equipmentId'] ??
          _equipmentData['_doc_id'];
      print('[EquipmentDetails] Loading full equipment details for ID: $id');

      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        _api.setAuthToken(token);
      }

      // Call admin API to fetch full equipment details
      final detailResp = await _api.getEquipmentDetails(id.toString());
      if (detailResp != null && detailResp.isNotEmpty) {
        setState(() {
          // normalize payload structure: some APIs return {data: {...}} or object directly
          if (detailResp.containsKey('data') && detailResp['data'] is Map) {
            _equipmentData = Map<String, dynamic>.from(detailResp['data']);
          } else {
            _equipmentData = Map<String, dynamic>.from(detailResp);
          }
        });
      }
    } catch (e) {
      print('[EquipmentDetails] Error loading equipment details: $e');
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
                // Equipment Title and ID + Status
                _buildEquipmentHeader(),
                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], thickness: 1, height: 1),
                const SizedBox(height: 24),

                // Equipment Information Section
                _buildSectionTitle("Equipment Information"),
                const SizedBox(height: 16),
                _buildEquipmentInfoGrid(),

                // Operational details section
                const SizedBox(height: 8),
                _buildSectionTitle("OPERATIONAL DETAILS AND CLASSIFICATION"),
                const SizedBox(height: 16),
                _buildOpsDetailsGrid(),

                const SizedBox(height: 24),
                Divider(color: Colors.grey[200], height: 1),
                const SizedBox(height: 24),

                // Status and timeline section
                _buildSectionTitle("STATUS AND TIMELINE"),
                const SizedBox(height: 8),
                _buildTimelinedetailsGrid(),
                const SizedBox(height: 16),
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
            'Equipment Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(_equipmentData),
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

  // Equipment header with name and ID
  Widget _buildEquipmentHeader() {
    final status = (_equipmentData['status'] ?? 'Operational').toString();
    final equipmentName =
        _equipmentData['name'] ?? _equipmentData['equipmentName'] ?? 'Equipment';
    final equipmentId = _equipmentData['id'] ?? _equipmentData['equipmentId'] ?? _equipmentData['_doc_id'] ?? 'N/A';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
              equipmentName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              ),
              const SizedBox(height: 8),
              Text(
              equipmentId,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              ),
              const SizedBox(height: 8),
              // Created by and Created at displayed in header
              Text(
              _equipmentData['created_by'] ?? _equipmentData['createdBy'] ?? 'N/A',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
              _formatDate(_equipmentData['created_at'] ?? _equipmentData['createdAt'] ?? _equipmentData['created']),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(status)[0],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(status)[1],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Get status color and dot color
  List<Color> _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
        return [Colors.green[50]!, Colors.green[700]!];
      case 'needs maintenance':
        return [Colors.orange[50]!, Colors.orange[700]!];
      case 'under repair':
        return [Colors.blue[50]!, Colors.blue[700]!];
      case 'out of service':
        return [Colors.red[50]!, Colors.red[700]!];
      default:
        return [Colors.grey[50]!, Colors.grey[700]!];
    }
  }

  // Equipment information grid
  Widget _buildEquipmentInfoGrid() {
    return Column(
      children: [
        // Manufacturer & Model (Equipment Information)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoTile(
                label: "MANUFACTURER",
                value: _equipmentData['manufacturer'] ?? _equipmentData['brand'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _buildInfoTile(
                label: "MODEL NUMBER",
                value: _equipmentData['model_number'] ?? _equipmentData['model'] ?? 'N/A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Asset Tag & Serial (Equipment Information)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoTile(
                label: "ASSET TAG",
                value: _equipmentData['asset_tag'] ?? _equipmentData['assetTag'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _buildInfoTile(
                label: "SERIAL NUMBER",
                value: _equipmentData['serial_number'] ?? _equipmentData['serialNumber'] ?? 'N/A',
              ),
            ),
          ],
        ),

        
        const SizedBox(height: 24),
        Divider(color: Colors.grey[200], height: 1),
        const SizedBox(height: 24),
      ],
    );
  }

  // Build info tile with icon
  Widget _buildInfoTile({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
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

  // Operational Details Grid
  Widget _buildOpsDetailsGrid() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInfoTile(
                label: "LOCATION",
                value: _equipmentData['location'] ?? _equipmentData['area'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _buildInfoTile(
                label: "CATEGORY",
                value: _equipmentData['category'] ?? _equipmentData['type'] ?? _equipmentData['equipment_type'] ?? 'N/A',
              ),
            ),
            const SizedBox(width: 48),
            Expanded(
              child: _buildInfoTile(
                label: "EQUIPMENT TYPE",
                value: _equipmentData['equipment_type'] ?? _equipmentData['equipmentType'] ?? _equipmentData['type'] ?? 'N/A',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Timeline Details Grid
  Widget _buildTimelinedetailsGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildInfoTile(
            label: "ACQUISITION DATE",
            value: _formatDate(_equipmentData['acquisitionDate'] ?? _equipmentData['acquired_date'] ?? _equipmentData['acquisition_date']),
          ),
        ),
        const SizedBox(width: 48),
        Expanded(
          child: _buildInfoTile(
            label: "INSTALLATION DATE",
            value: _formatDate(_equipmentData['installationDate'] ?? _equipmentData['installation_date'] ?? _equipmentData['install_date']),
          ),
        ),
      ],
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

      // Localized display MM/dd/yyyy
      return '${_twoDigits(dateTime.month)}/${_twoDigits(dateTime.day)}/${dateTime.year}';
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
          // Maintenance Button
          ElevatedButton.icon(
            onPressed: () async {
              final equipmentName = _equipmentData['name'] ?? _equipmentData['equipmentName'] ?? 'Equipment';
              final maintenanceDynamic = _equipmentData['maintenanceHistory'] ?? _equipmentData['maintenance_history'] ?? _equipmentData['maintenance'] ?? [];
              final List<Map<String, dynamic>> maintenanceList = (maintenanceDynamic is List)
                  ? maintenanceDynamic.map((e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map)).toList()
                  : <Map<String, dynamic>>[];

              await MaintenanceHistoryDetailsDialog.show(
                context,
                title: 'Maintenance History: $equipmentName',
                subtitle: 'View all maintenance logs for $equipmentName.',
                maintenanceHistory: maintenanceList,
              );
            },
            label: const Text('View Maintenance History'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          // Reserve Inventory Button
          ElevatedButton.icon(
            onPressed: () async {
              await _showCreateReservationDialog(context);
            },
            icon: const Icon(Icons.inventory_2_rounded),
            label: const Text('Reserve Inventory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          // Edit Button
          ElevatedButton.icon(
            onPressed: () {
              final id = _equipmentData['id'] ?? _equipmentData['equipmentId'] ?? _equipmentData['_doc_id'];
              if (id != null) {
                Navigator.of(context).pop(_equipmentData);
                // go to edit route
                context.go('/adminweb/inventory_management/equipmentregisternew/$id?edit=1');
              }
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Equipment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateReservationDialog(BuildContext context) async {
    String? selectedInventoryId;
    int qty = 1;
    final TextEditingController qtyController = TextEditingController(text: '1');
    final TextEditingController taskIdController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Create Inventory Reservation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                // Dropdown to select inventory item
                DropdownButtonFormField<String>(
                  value: selectedInventoryId,
                  items: _buildingInventory.map((item) {
                    final id = (item['id'] ?? item['_doc_id'] ?? item['item_code'] ?? item['itemCode']).toString();
                    final name = (item['item_name'] ?? item['itemName'] ?? item['name'] ?? item['itemName'] ?? '').toString();
                    final stock = item['current_stock'] ?? item['quantity_in_stock'] ?? item['quantityInStock'] ?? 0;
                    return DropdownMenuItem(value: id, child: Text('$name — $stock'));
                  }).toList(),
                  onChanged: (v) => selectedInventoryId = v,
                  decoration: const InputDecoration(labelText: 'Inventory item'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: qtyController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) { qty = int.tryParse(v) ?? 1; },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: taskIdController,
                  decoration: const InputDecoration(labelText: 'Maintenance Task ID (optional)'),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final id = selectedInventoryId;
                        if (id == null || id.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an inventory item to reserve')));
                          return;
                        }
                        final q = int.tryParse(qtyController.text) ?? 1;
                        final maintenanceTaskId = taskIdController.text.trim();
                        try {
                          final resp = await _api.createInventoryReservation(
                            inventoryId: id,
                            quantity: q,
                            maintenanceTaskId: maintenanceTaskId.isEmpty ? '' : maintenanceTaskId,
                          );
                          if (resp['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation created')));
                            Navigator.of(ctx).pop();
                            // Optionally refresh local equipment details
                            await _loadEquipmentDetails();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create reservation: ${resp['detail'] ?? resp}')));
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating reservation: $e')));
                        }
                      },
                      child: const Text('Reserve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
