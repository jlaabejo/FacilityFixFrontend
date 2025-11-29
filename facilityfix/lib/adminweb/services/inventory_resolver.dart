import 'package:facilityfix/services/api_services.dart' as main_api;

/// Lightweight in-memory SKU -> inventory document ID resolver
/// Used by admin forms to resolve canonical SKUs (e.g. 'WIPES') to
/// inventory item document IDs for a specific building.
///
/// Implementation notes:
/// - Caches the building inventory mapping to avoid repeated API calls
/// - Tries exact item_code / code / itemCode match, then fuzzy name contains
/// - Will return null when not resolvable
class InventoryResolver {
  final main_api.APIService _api = main_api.APIService();

  // buildingId -> (normalized_key -> docId)
  final Map<String, Map<String, String>> _cache = {};

  /// Resolve a single SKU to an inventory document id for a given building.
  /// Returns null if not found.
  Future<String?> resolveSku(String? sku, String buildingId) async {
    if (sku == null) return null;
    final normalized = sku.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    // Ensure the building cache is loaded
    if (!_cache.containsKey(buildingId)) {
      await _ensureCacheForBuilding(buildingId);
    }

    // Exact match first
    final map = _cache[buildingId] ?? {};
    if (map.containsKey(normalized)) return map[normalized];

    // Fuzzy attempt: look for keys that contain this SKU as substring (name or code)
    final entry = map.entries.firstWhere(
      (e) => e.key.contains(normalized) || normalized.contains(e.key),
      orElse: () => const MapEntry('', ''),
    );
    if (entry.key.isNotEmpty) return entry.value;

    // Not found
    return null;
  }

  /// Preload mapping for a building. Useful to call if multiple resolves are expected.
  Future<void> preloadBuilding(String buildingId) async {
    await _ensureCacheForBuilding(buildingId);
  }

  Future<void> _ensureCacheForBuilding(String buildingId) async {
    if (_cache.containsKey(buildingId)) return;
    try {
      final resp = await _api.getBuildingInventory(buildingId);
      final Map<String, String> map = {};
      if (resp != null && resp['success'] == true && resp['data'] is List) {
        final items = List<Map<String, dynamic>>.from(resp['data']);
        for (final it in items) {
          final id = (it['id'] ?? it['_doc_id'])?.toString() ?? '';
          if (id.isEmpty) continue;

          // Add possible string keys for the item: item_code / code / itemCode, item_name
          final potentialKeys = <String?>[
            (it['item_code'] ?? it['itemCode'] ?? it['code'])?.toString(),
            (it['item_name'] ?? it['name'])?.toString(),
          ];

          for (final key in potentialKeys) {
            if (key == null) continue;
            final k = key.trim().toLowerCase();
            if (k.isEmpty) continue;
            if (!map.containsKey(k)) map[k] = id;
          }
        }
      }
      _cache[buildingId] = map;
    } catch (e) {
      // On failure, make sure there's an entry so we won't repeatedly try
      _cache[buildingId] = {};
      // ignore: avoid_print
      print('[InventoryResolver] Failed to load building inventory for $buildingId: $e');
    }
  }

  /// Clear cache for a building or full cache
  void clearCache({String? buildingId}) {
    if (buildingId != null && buildingId.isNotEmpty) {
      _cache.remove(buildingId);
    } else {
      _cache.clear();
    }
  }

  /// Convenience: return a Map of sku -> docId for a list of SKUs
  /// Preserves the input order for deterministic results.
  Future<Map<String, String?>> resolveSkus(List<String?> skus, String buildingId) async {
    await _ensureCacheForBuilding(buildingId);
    final out = <String, String?>{};
    for (final s in skus) {
      final v = await resolveSku(s, buildingId);
      out[s ?? ''] = v;
    }
    return out;
  }
}
