import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../widgets/logout_popup.dart';
import 'pop_up/equipment_viewdetails_popup.dart';

class EquipmentRegistryPage extends StatefulWidget {
  const EquipmentRegistryPage({super.key});

  @override
  State<EquipmentRegistryPage> createState() => _EquipmentRegistryPageState();
}

class _EquipmentRegistryPageState extends State<EquipmentRegistryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All Status';
  String _selectedStatusFilter = 'All Types';
  // Sorting state for acquisition date
  bool _sortByAcquisition = false;
  bool _sortAscending = true;

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Equipment list (initially empty; loaded from server by default)
  List<Map<String, dynamic>> _equipment = [];

  List<Map<String, dynamic>> _filteredEquipment = [];
  final ApiService _api = ApiService();
  bool _isLoading = false;
  String? _buildingId;

  // Filter options
  final List<String> _statusFilterOptions = [
    'All Status',
    'Operational',
    'Needs Maintenance',
    'Under Repair',
    'Out of Service',
  ];

  final List<String> _typeFilterOptions = [
    'All Types',
    'HVAC System',
    'Elevator',
    'Generator',
    'Water System',
    'Safety Equipment',
    'Lighting',
    'Electrical System',
    'Plumbing',
    'Fire Safety',
    'Security System',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Equipment is loaded from the server in `_initAndLoadEquipment`.
    _initAndLoadEquipment();
  }

  Future<void> _initAndLoadEquipment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await AuthStorage.getProfile();
      if (profile != null) {
        _buildingId = profile['building_id'] ?? profile['buildingId'] ?? profile['building'] ?? 'default_building_id';
      } else {
        _buildingId = 'default_building_id';
      }
      await _loadEquipmentFromServer();
    } catch (e) {
      print('[EquipmentRegistry] Error loading building profile or equipment: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadEquipmentFromServer() async {
    if (_buildingId == null) return;
    try {
      final items = await _api.listEquipmentByBuilding(_buildingId!);
      setState(() {
        _equipment = items.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
      });
      _updateFilteredEquipment();
    } catch (e) {
      print('[EquipmentRegistry] Failed to load equipment: $e');
      // If server call fails, leave the existing equipment list as-is (may be empty)
    }
  }

  void _updateFilteredEquipment() {
    setState(() {
      var items = List<Map<String, dynamic>>.from(_equipment);

      // Apply status filter
      if (_selectedRoleFilter != 'All Status') {
        items =
            items
                .where((item) => item['status'] == _selectedRoleFilter)
                .toList();
      }

      // Apply type filter
      if (_selectedStatusFilter != 'All Types') {
        items =
            items
                .where((item) => item['type'] == _selectedStatusFilter)
                .toList();
      }

      // Apply search filter - local filtering or remote search for >=3 chars
      final searchTerm = _searchController.text.trim();
      if (searchTerm.isNotEmpty) {
        if (searchTerm.length >= 3 && _buildingId != null) {
          // If a significant search term, try server-side search
          try {
            _api.searchEquipment(_buildingId!, searchTerm).then((serverItems) {
              setState(() {
                _filteredEquipment = serverItems.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
              });
            });
            // We early return to avoid overriding _filteredEquipment below
            return;
          } catch (e) {
            print('[EquipmentRegistry] Server search failed: $e');
            // fallback to local filter
          }
        }

        final searchLower = searchTerm.toLowerCase();
        items = items.where((item) {
          final id = (item['id'] ?? '').toString().toLowerCase();
          final name = (item['name'] ?? '').toString().toLowerCase();
          final location = (item['location'] ?? '').toString().toLowerCase();
          return id.contains(searchLower) || name.contains(searchLower) || location.contains(searchLower);
        }).toList();
      }

      _filteredEquipment = items;
      // Apply sorting by acquisition date after filters and search
      if (_sortByAcquisition) {
        _filteredEquipment.sort((a, b) {
          final aDate = _tryParseDate(a['acquisitionDate']);
          final bDate = _tryParseDate(b['acquisitionDate']);
          // treat nulls as earliest dates when ascending
          final defaultDate = DateTime.fromMillisecondsSinceEpoch(0);
          final ad = aDate ?? defaultDate;
          final bd = bDate ?? defaultDate;
          return _sortAscending ? ad.compareTo(bd) : bd.compareTo(ad);
        });
      }
      _currentPage = 1; // Reset to first page when filter changes
    });
  }

  DateTime? _tryParseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) {
      // Try ISO parse first
      final parsed = DateTime.tryParse(date);
      if (parsed != null) return parsed;
      // Try common formats like MM/dd/yyyy or M/d/yyyy
      final mdMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(date);
      if (mdMatch != null) {
        final month = int.tryParse(mdMatch.group(1) ?? '') ?? 1;
        final day = int.tryParse(mdMatch.group(2) ?? '') ?? 1;
        final year = int.tryParse(mdMatch.group(3) ?? '') ?? 1970;
        try {
          return DateTime(year, month, day);
        } catch (_) {
          return null;
        }
      }
      // Try yyyy-MM-dd or yyyy/MM/dd
      final ymdMatch = RegExp(
        r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})',
      ).firstMatch(date);
      if (ymdMatch != null) {
        final year = int.tryParse(ymdMatch.group(1) ?? '') ?? 1970;
        final month = int.tryParse(ymdMatch.group(2) ?? '') ?? 1;
        final day = int.tryParse(ymdMatch.group(3) ?? '') ?? 1;
        try {
          return DateTime(year, month, day);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  String _formatDateDisplay(dynamic date) {
    if (date == null) return '';
    try {
      DateTime dt;
      if (date is DateTime) dt = date;
      else if (date is String) dt = DateTime.parse(date);
      else return date.toString();
      final two = (int v) => v.toString().padLeft(2, '0');
      return '${two(dt.month)}/${two(dt.day)}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }

  // Route mapping helper
  static String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_scheduling': '/user/scheduling',
      'work_maintenance': '/work/maintenance',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_equipment': '/inventory/equipment',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
      'logout': '/logout',
    };
    return pathMap[routeKey];
  }

  // Logout handler
  void _handleLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return const LogoutPopup();
      },
    );

    if (result == true) {
      context.go('/');
    }
  }

  // Status badge builder
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Operational':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        break;
      case 'Needs Maintenance':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        break;
      case 'Under Repair':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[700]!;
        break;
      case 'Out of Service':
        bgColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        break;
      default:
        bgColor = Colors.grey[50]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
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

  // Action menu
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> equipment,
    Offset position,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

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
              Icon(
                Icons.visibility_outlined,
                color: Colors.green[600],
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                'View',
                style: TextStyle(color: Colors.green[600], fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, color: Colors.blue[600], size: 18),
              const SizedBox(width: 12),
              Text(
                'Edit',
                style: TextStyle(color: Colors.blue[600], fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.red[600], size: 18),
              const SizedBox(width: 12),
              Text(
                'Delete',
                style: TextStyle(color: Colors.red[600], fontSize: 14),
              ),
            ],
          ),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 8,
    ).then((value) {
      if (value != null) {
        _handleActionSelection(value, equipment);
      }
    });
  }

  void _handleActionSelection(String action, Map<String, dynamic> equipment) {
    switch (action) {
      case 'view':
        _viewEquipment(equipment);
        break;
      case 'edit':
        _editEquipment(equipment);
        break;
      case 'delete':
        _deleteEquipment(equipment);
        break;
    }
  }

  void _viewEquipment(Map<String, dynamic> equipment) {
    EquipmentViewDetailsDialog.show(context, equipment);
  }

  void _editEquipment(Map<String, dynamic> equipment) {
    final id = equipment['id'] ?? equipment['equipmentId'] ?? equipment['_doc_id'];
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to edit: no equipment id found'), backgroundColor: Colors.red),
      );
      return;
    }
    // Navigate to the equipment register page with the equipment ID and edit mode flag
    context.go('/adminweb/inventory_management/equipmentregisternew/$id?edit=1');
  }

  void _deleteEquipment(Map<String, dynamic> equipment) {
    // Confirm deletion
    final id = equipment['id'] ?? equipment['equipmentId'] ?? equipment['_doc_id'];
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Equipment'),
          content: Text('Are you sure you want to delete equipment $id? This will mark it inactive.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          // Call API to delete
          await _api.deleteEquipment(id.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment deleted (marked inactive)'), backgroundColor: Colors.green),
          );
          await _loadEquipmentFromServer();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
          );
        }
      }
    });
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // Pagination methods
  List<Map<String, dynamic>> _getPaginatedEquipment() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredEquipment.length) return [];

    return _filteredEquipment.sublist(
      startIndex,
      endIndex > _filteredEquipment.length
          ? _filteredEquipment.length
          : endIndex,
    );
  }

  int get _totalPages {
    return _filteredEquipment.isEmpty
        ? 1
        : (_filteredEquipment.length / _itemsPerPage).ceil();
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
              color:
                  i == _currentPage
                      ? const Color(0xFF1976D2)
                      : Colors.grey[100],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'inventory_equipment',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inventory Management',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Breadcrumb navigation
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.go('/dashboard'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('Dashboard'),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 16,
                        ),
                        TextButton(
                          onPressed: () => context.go('/inventory/equipment'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Inventory Management'),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 16,
                        ),
                        TextButton(
                          onPressed: null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Equipment Registry'),
                        ),
                      ],
                    ),
                  ],
                ),
                // Register New button
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/adminweb/inventory_management/equipmentregisternew',);
                      },
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text(
                        "Create New",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Search, Filter, and Refresh Row
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  // Search Field with white background
                  SizedBox(
                    width: 400,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _updateFilteredEquipment(),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          hintText: "Search",
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Status Dropdown
                  IntrinsicWidth(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRoleFilter,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items:
                              _statusFilterOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedRoleFilter = newValue;
                                _updateFilteredEquipment();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Classification Dropdown
                  IntrinsicWidth(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatusFilter,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          items:
                              _typeFilterOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedStatusFilter = newValue;
                                _updateFilteredEquipment();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Refresh Button
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: InkWell(
                      onTap: _updateFilteredEquipment,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: Colors.blue[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Content Container
            Container(
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
                  // Equipment Registry Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Equipment Registry",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Table Header
                  Container(
                    color: Colors.grey[50],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'EQUIPMENT ID',
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
                            'EQUIPMENT NAME',
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
                            'TYPE',
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
                            'LOCATION',
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
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                // Toggle sorting: if not sorting, enable ascending. If already sorting, toggle direction
                                if (!_sortByAcquisition) {
                                  _sortByAcquisition = true;
                                  _sortAscending = true;
                                } else {
                                  _sortAscending = !_sortAscending;
                                }
                                _updateFilteredEquipment();
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'ACQUISITION DATE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (_sortByAcquisition)
                                  Icon(
                                    _sortAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Space for menu icon
                      ],
                    ),
                  ),

                  // Table Body
                  if (_filteredEquipment.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No equipment found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _getPaginatedEquipment().length,
                      itemBuilder: (context, index) {
                        final equipment = _getPaginatedEquipment()[index];
                        return InkWell(
                          onTap: () => _viewEquipment(equipment),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Equipment ID
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    equipment['formatted_id'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // Equipment Name
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    equipment['name'] ?? equipment['equipmentName'] ?? equipment['equipment_name'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                // Type
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    equipment['type'] ?? equipment['equipmentType'] ?? equipment['equipment_type'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                // Location
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    equipment['location'] ?? equipment['area'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                // Status
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildStatusBadge(
                                      equipment['status'],
                                    ),
                                  ),
                                ),
                                // Acquisition Date
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _formatDateDisplay(equipment['acquisitionDate'] ?? equipment['acquisition_date'] ?? ''),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                // Menu Icon
                                Builder(
                                  builder: (BuildContext buttonContext) {
                                    return IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      iconSize: 20,
                                      color: Colors.grey[600],
                                      onPressed: () {
                                        final RenderBox button =
                                            buttonContext.findRenderObject()
                                                as RenderBox;
                                        final position = button.localToGlobal(
                                          Offset.zero,
                                        );
                                        _showActionMenu(
                                          context,
                                          equipment,
                                          position,
                                        );
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

                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Pagination Section
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _filteredEquipment.isEmpty
                              ? "No equipment found"
                              : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredEquipment.length ? _filteredEquipment.length : _currentPage * _itemsPerPage} of ${_filteredEquipment.length} entries",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed:
                                  _currentPage > 1 ? _previousPage : null,
                              icon: Icon(
                                Icons.chevron_left,
                                color:
                                    _currentPage > 1
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                              ),
                            ),
                            ..._buildPageNumbers(),
                            IconButton(
                              onPressed:
                                  _currentPage < _totalPages ? _nextPage : null,
                              icon: Icon(
                                Icons.chevron_right,
                                color:
                                    _currentPage < _totalPages
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
