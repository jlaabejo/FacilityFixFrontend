import 'package:facilityfix/adminweb/services/api_service.dart' as admin_api;
import '../../../utils/inventory_notifier.dart';
import 'package:facilityfix/adminweb/services/inventory_resolver.dart';
import 'package:facilityfix/services/api_services.dart' as user_api;

// Simple prototype mapping of maintenance templates to inventory items.
// This is intentionally lightweight; switch to Firestore templates later.
class TemplateItem {
  final String sku;
  final String name;
  final int qty;
  final String unit;
  final bool autoReserve; // whether items from this template entry should auto-reserve on task creation
  final String? inventoryId; // optional doc id override for a specific inventory item

  const TemplateItem({required this.sku, required this.name, required this.qty, required this.unit, this.autoReserve = true, this.inventoryId});
  Map<String, dynamic> toJson() => {
    'sku': sku,
    'name': name,
    'qty': qty,
    'unit': unit,
    'autoReserve': autoReserve,
    if (inventoryId != null) 'inventory_id': inventoryId,
  };
}

class MaintenanceTemplates {
  // Hard-coded templates:
  static const Map<String, List<TemplateItem>> _templates = {
    'aircon_cleaning': [
      TemplateItem(sku: 'MULTI_DISINFECT', name: 'Multi-Purpose Disinfectant', qty: 2, unit: 'bottle'),
      TemplateItem(sku: 'WIPES', name: 'Wipes', qty: 5, unit: 'pack'),
      TemplateItem(sku: 'VACUUM_CLEANER', name: 'Vacuum Cleaner', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'MICROFIBER_CLOTHS', name: 'Microfiber Cloths', qty: 10, unit: 'pack'),
      TemplateItem(sku: 'AIR_FILTER', name: 'Air Filter', qty: 2, unit: 'piece'),
      TemplateItem(sku: 'GLOVES', name: 'Protective Gloves', qty: 2, unit: 'pair'),
    ],
    'basic_cleaning': [
      TemplateItem(sku: 'MULTI_DISINFECT', name: 'Multi-Purpose Disinfectant', qty: 1, unit: 'bottle'),
      TemplateItem(sku: 'CLEANER', name: 'All-purpose cleaner', qty: 1, unit: 'bottle'),
      TemplateItem(sku: 'BROOM', name: 'Broom', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'MOP', name: 'Mop', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'BUCKET', name: 'Bucket', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'DUSTPAN', name: 'Dustpan', qty: 1, unit: 'piece'),

      TemplateItem(sku: 'WIRE_CUTTERS', name: 'Wire Cutters', qty: 1, unit: 'pair'),
      TemplateItem(sku: 'ELECTRICAL_TAPE', name: 'Electrical Tape', qty: 3, unit: 'roll'),
      TemplateItem(sku: 'MULTIMETER', name: 'Multimeter', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'SCREWDRIVER_SET', name: 'Screwdriver Set', qty: 1, unit: 'set'),
      TemplateItem(sku: 'PLIERS', name: 'Pliers', qty: 1, unit: 'pair'),
      TemplateItem(sku: 'VOLTAGE_TESTER', name: 'Voltage Tester', qty: 1, unit: 'piece'),
    ],
    'painting': [
      TemplateItem(sku: 'PAINT_BRUSH', name: 'Paint Brush', qty: 2, unit: 'piece'),
      TemplateItem(sku: 'PAINT_ROLLER', name: 'Paint Roller', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'PAINT', name: 'Interior Paint', qty: 5, unit: 'gallon'),
      TemplateItem(sku: 'DROP_CLOTHS', name: 'Drop Cloths', qty: 5, unit: 'sheet'),
      TemplateItem(sku: 'PAINTER_TAPE', name: 'Painter\'s Tape', qty: 2, unit: 'roll'),
      TemplateItem(sku: 'LADDER', name: 'Ladder', qty: 1, unit: 'piece'),
    ],
    'carpentry': [
      TemplateItem(sku: 'HAMMER', name: 'Hammer', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'NAILS', name: 'Nails', qty: 100, unit: 'box'),
      TemplateItem(sku: 'SAW', name: 'Hand Saw', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'SCREWDRIVER', name: 'Screwdriver', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'MEASURING_TAPE', name: 'Measuring Tape', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'LEVEL', name: 'Level', qty: 1, unit: 'piece'),
    ],
    'pest_control': [
      TemplateItem(sku: 'PEST_TRAPS', name: 'Pest Traps', qty: 10, unit: 'pack'),
      TemplateItem(sku: 'INSECT_SPRAY', name: 'Insect Spray', qty: 2, unit: 'can'),
      TemplateItem(sku: 'GLOVES', name: 'Protective Gloves', qty: 2, unit: 'pair'),
      TemplateItem(sku: 'MASK', name: 'Protective Mask', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'BAIT_STATIONS', name: 'Bait Stations', qty: 5, unit: 'pack'),
    ],
    'window_cleaning': [
      TemplateItem(sku: 'SQUEEGEE', name: 'Squeegee', qty: 2, unit: 'piece'),
      TemplateItem(sku: 'GLASS_CLEANER', name: 'Glass Cleaner', qty: 3, unit: 'bottle'),
      TemplateItem(sku: 'LADDER', name: 'Ladder', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'BUCKET', name: 'Bucket', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'MICROFIBER_CLOTHS', name: 'Microfiber Cloths', qty: 10, unit: 'pack'),
    ],
    'hvac_maintenance': [
      TemplateItem(sku: 'THERMOMETER', name: 'Digital Thermometer', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'FILTERS', name: 'HVAC Filters', qty: 4, unit: 'pack'),
      TemplateItem(sku: 'DUCT_TAPE', name: 'Duct Tape', qty: 1, unit: 'roll'),
      TemplateItem(sku: 'MULTIMETER', name: 'Multimeter', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'LADDER', name: 'Ladder', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'GLOVES', name: 'Protective Gloves', qty: 2, unit: 'pair'),
      TemplateItem(sku: 'VACUUM_PUMP', name: 'Vacuum Pump', qty: 1, unit: 'piece'),
    ],
    'masonry_repair': [
      TemplateItem(sku: 'MORTAR_MIX', name: 'Mortar Mix', qty: 20, unit: 'bag'),
      TemplateItem(sku: 'TROWEL', name: 'Masonry Trowel', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'BRICKS', name: 'Bricks', qty: 50, unit: 'piece'),
      TemplateItem(sku: 'LEVEL', name: 'Level', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'HAMMER', name: 'Hammer', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'SAFETY_GLASSES', name: 'Safety Glasses', qty: 2, unit: 'pair'),
      TemplateItem(sku: 'BUCKET', name: 'Bucket', qty: 2, unit: 'piece'),
      TemplateItem(sku: 'WHEELBARROW', name: 'Wheelbarrow', qty: 1, unit: 'piece'),
    ],
    'plumbing_repair': [
      TemplateItem(sku: 'PIPE_WRENCH', name: 'Pipe Wrench', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'PLUNGER', name: 'Plunger', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'PIPE_CUTTER', name: 'Pipe Cutter', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'PLUMBING_TAPE', name: 'Plumbing Tape', qty: 2, unit: 'roll'),
      TemplateItem(sku: 'PVC_PIPE', name: 'PVC Pipe', qty: 10, unit: 'meter'),
      TemplateItem(sku: 'PVC_FITTINGS', name: 'PVC Fittings', qty: 20, unit: 'piece'),
      TemplateItem(sku: 'GLOVES', name: 'Protective Gloves', qty: 2, unit: 'pair'),
      TemplateItem(sku: 'BUCKET', name: 'Bucket', qty: 1, unit: 'piece'),
    ],
    'electrical_fix': [
      TemplateItem(sku: 'WIRE_CUTTERS', name: 'Wire Cutters', qty: 1, unit: 'pair'),
      TemplateItem(sku: 'ELECTRICAL_TAPE', name: 'Electrical Tape', qty: 3, unit: 'roll'),
      TemplateItem(sku: 'MULTIMETER', name: 'Multimeter', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'SCREWDRIVER_SET', name: 'Screwdriver Set', qty: 1, unit: 'set'),
      TemplateItem(sku: 'PLIERS', name: 'Pliers', qty: 1, unit: 'pair'),
      TemplateItem(sku: 'VOLTAGE_TESTER', name: 'Voltage Tester', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'CIRCUIT_BREAKER', name: 'Circuit Breaker', qty: 5, unit: 'piece'),
      TemplateItem(sku: 'GLOVES', name: 'Protective Gloves', qty: 2, unit: 'pair'),
    ],
    'landscaping': [
      TemplateItem(sku: 'SHOVEL', name: 'Shovel', qty: 2, unit: 'piece'),
      TemplateItem(sku: 'RAKE', name: 'Rake', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'PRUNING_SHEARS', name: 'Pruning Shears', qty: 1, unit: 'pair'),
      TemplateItem(sku: 'GARDEN_HOSE', name: 'Garden Hose', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'FERTILIZER', name: 'Fertilizer', qty: 5, unit: 'bag'),
      TemplateItem(sku: 'SEEDS', name: 'Grass Seeds', qty: 10, unit: 'pack'),
      TemplateItem(sku: 'GLOVES', name: 'Protective Gloves', qty: 2, unit: 'pair'),
      TemplateItem(sku: 'WHEELBARROW', name: 'Wheelbarrow', qty: 1, unit: 'piece'),
    ],
    'roof_repair': [
      TemplateItem(sku: 'ROOFING_NAILS', name: 'Roofing Nails', qty: 200, unit: 'box'),
      TemplateItem(sku: 'ROOFING_TILES', name: 'Roofing Tiles', qty: 50, unit: 'piece'),
      TemplateItem(sku: 'HAMMER', name: 'Hammer', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'LADDER', name: 'Ladder', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'SAFETY_HARNESS', name: 'Safety Harness', qty: 1, unit: 'piece'),
      TemplateItem(sku: 'DUCT_TAPE', name: 'Duct Tape', qty: 1, unit: 'roll'),
      TemplateItem(sku: 'GLOVES', name: 'Protective Gloves', qty: 2, unit: 'pair'),
      TemplateItem(sku: 'SAFETY_GLASSES', name: 'Safety Glasses', qty: 2, unit: 'pair'),
    ],
  };

  static List<String> keys() => _templates.keys.toList();

  static String displayName(String key) {
    switch (key) {
      case 'aircon_cleaning':
        return 'Aircon Cleaning';
      case 'basic_cleaning':
        return 'Basic Cleaning';
      case 'plumbing_repair':
        return 'Plumbing Repair';
      case 'electrical_fix':
        return 'Electrical Fix';
      case 'painting':
        return 'Painting';
      case 'carpentry':
        return 'Carpentry';
      case 'pest_control':
        return 'Pest Control';
      case 'window_cleaning':
        return 'Window Cleaning';
      case 'landscaping':
        return 'Landscaping';
      case 'hvac_maintenance':
        return 'HVAC Maintenance';
      case 'masonry_repair':
        return 'Masonry Repair';
      case 'roof_repair':
        return 'Roof Repair';
      default:
        return key;
    }
  }

  static List<TemplateItem> getItems(String key) => _templates[key] ?? [];
}

// Helper to convert TemplateItem to a Map usable by the forms
Map<String, dynamic> templateItemToSelectedItem(TemplateItem t) => {
  // prefer an explicit `inventoryId` override if provided; otherwise fallback to SKU
  'inventory_id': t.inventoryId ?? t.sku,
  'item_name': t.name,
  'item_code': t.sku,
  'quantity': t.qty,
  'unit': t.unit,
  'available_stock': 0,
  'autoReserve': t.autoReserve,
  'resolved': t.inventoryId != null, // flag to indicate resolved from template
};

class MaintenanceInventoryService {
  final admin_api.ApiService _adminApi = admin_api.ApiService();
  final user_api.APIService _userApi = user_api.APIService();
  final InventoryResolver _inventoryResolver = InventoryResolver();

  /// Create a maintenance task and reserve items based on a template.
  /// Performs sequential operations and returns a map with task_id and reservation ids.
  Future<Map<String, dynamic>> createTaskAndReserve({
    required Map<String, dynamic> taskData,
    required List<TemplateItem> items,
  }) async {
    final Map<String, dynamic> result = {};
    try {
      // Create task using admin API
      final created = await admin_api.ApiService().createMaintenanceTask(taskData);
      final String taskId = created['id']?.toString() ?? created['task']?['id']?.toString() ?? '';
      if (taskId.isEmpty) throw Exception('Failed to create task - missing id in response');

      final List<String> reservationIds = [];
      final List<Map<String, dynamic>> reservedItems = [];
      for (final it in items) {
        // Only reserve items marked for auto-reservation
        if (it.autoReserve != true) {
          print('[MaintenanceInventoryService] skipping template item ${it.sku} (autoReserve=false)');
          continue;
        }
        // Try to resolve SKU to inventory doc ID for the building
        String inventoryId = it.sku;
        try {
          final resolved = await _inventoryResolver.resolveSku(it.sku, taskData['building_id']?.toString() ?? 'default_building_id');
          if (resolved != null && resolved.isNotEmpty) inventoryId = resolved;
        } catch (e) {
          print('[MaintenanceInventoryService] failed to resolve SKU ${it.sku}: $e');
        }

        final reserveResp = await admin_api.ApiService().createInventoryReservation(
          inventoryId: inventoryId,
          quantity: it.qty,
          maintenanceTaskId: taskId,
        );
        if (reserveResp['success'] == true) {
          final resId = reserveResp['reservation_id']?.toString() ?? reserveResp['id']?.toString() ?? '';
          reservationIds.add(resId);
          reservedItems.add({
            'sku': it.sku,
            'inventory_id': inventoryId,
            'reservation_id': resId,
          });
          try {
            InventoryUpdateNotifier().notifyItemUpdated(inventoryId.toString());
          } catch (_) {}
        } else {
          throw Exception('Failed to reserve ${it.sku}');
        }
      }

      result['success'] = true;
      result['task_id'] = taskId;
      result['reservation_ids'] = reservationIds;
      result['reserved_items'] = reservedItems;
      return result;
    } catch (e) {
      result['success'] = false;
      result['error'] = e.toString();
      return result;
    }
  }
}
