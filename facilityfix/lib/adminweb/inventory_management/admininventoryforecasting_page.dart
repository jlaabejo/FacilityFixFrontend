import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import '../widgets/logout_popup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventoryForecastingPage extends StatefulWidget {
  const InventoryForecastingPage({super.key});

  @override
  State<InventoryForecastingPage> createState() =>
      _InventoryForecastingPageState();
}

class _InventoryForecastingPageState extends State<InventoryForecastingPage> {
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _selectedUrgency = 'All Urgencies';

  // Pagination state
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  // Loading and data state
  bool _isLoading = true;
  List<Map<String, dynamic>> _forecastingData = [];

  // Navigation helper
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

  // Logout functionality
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

  // Column widths for table
  final List<double> _colW = <double>[
    80, // ID
    120, // NAME
    100, // CATEGORY
    80, // STATUS
    130, // STOCK(AVAIL/TOTAL)
    70, // USAGE/MO
    60, // TREND
    100, // DAYS TO MIN
    110, // REORDER BY
  ];

  // Fixed width cell helper
  Widget _fixedCell(
    int i,
    Widget child, {
    Alignment align = Alignment.centerLeft,
  }) {
    return SizedBox(
      width: _colW[i],
      child: Align(alignment: align, child: child),
    );
  }

  // Text with ellipsis helper
  Text _ellipsis(String s, {TextStyle? style}) => Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    softWrap: false,
    style: style,
  );

  // Trend widget helper
  Widget _trendWidget(String iconName, String colorName) {
    final icon = _getTrendIcon(iconName);
    final color = _getTrendColor(colorName);
    return Container(
      width: 93.07,
      height: 35.99,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 12,
            child: Container(
              width: 77.07,
              height: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(),
                    child: Icon(icon, size: 12, color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Trend icon mapping
  IconData _getTrendIcon(String iconName) {
    switch (iconName) {
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  // Trend color mapping
  Color _getTrendColor(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Status tag helper
  Widget _statusTag(String status) {
    Color bgColor;
    switch (status.toLowerCase()) {
      case 'active':
        bgColor = Colors.green[100]!;
        break;
      case 'inactive':
        bgColor = Colors.grey[100]!;
        break;
      default:
        bgColor = Colors.blue[100]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  // Category tag helper
  Widget _categoryTag(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  // Days to min helper
  Widget _daysToMinWidget(String days) {
    return SizedBox(
      width: 50, // Increased width to prevent text wrapping
      child: Text(
        days,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: const Color(0xFF2E7D32),
          fontSize: 12,
          fontFamily: 'Arial',
          fontWeight: FontWeight.w400,
          height: 1.0, // Reduced line height to prevent wrapping
        ),
      ),
    );
  }

  // Fetch forecasting data from API
  Future<void> _fetchForecastingData() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Replace with actual building ID from context or route
      final buildingId = 'your_building_id_here'; // e.g., from GoRouterState or provider

      // TODO: Replace with actual JWT token from auth context
      final jwtToken = 'YOUR_JWT_TOKEN'; // e.g., from secure storage or provider

      final response = await http.get(
        Uri.parse('YOUR_API_BASE_URL/inventory/forecasting/$buildingId'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _forecastingData = data.map((item) => item as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        // Handle error, e.g., show snackbar
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error, e.g., show snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchForecastingData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get paginated data
  List<Map<String, dynamic>> get _paginatedData {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _forecastingData.sublist(
      startIndex,
      endIndex > _forecastingData.length ? _forecastingData.length : endIndex,
    );
  }

  // Get total pages
  int get _totalPages => (_forecastingData.length / _itemsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: '/admin/inventory/forecasting',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with breadcrumbs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Inventory Forecasting",
                      style: TextStyle(
                        fontSize: 28,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Dashboard'),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 16,
                        ),
                        TextButton(
                          onPressed: () => context.go('/inventory/items'),
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
                          child: const Text('Forecasting'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Statistics Card
            Row(
              children: [
                // Critical Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 24),
                    height: 100,
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.26,
                          color: Colors.black.withOpacity(0.10),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Critical',
                                style: TextStyle(
                                  color: const Color(0xFF626C70),
                                  fontSize: 11,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                              Text(
                                '1', // TODO: Compute from _forecastingData if needed
                                style: TextStyle(
                                  color: const Color(0xFF0A0A0A),
                                  fontSize: 24,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Red Badge
                        Container(
                          width: 44,
                          height: 21,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE84545),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '≤7d',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // High Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 24),
                    height: 100,
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.26,
                          color: Colors.black.withOpacity(0.10),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'High',
                                style: TextStyle(
                                  color: const Color(0xFF626C70),
                                  fontSize: 11,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                              Text(
                                '1', // TODO: Compute from _forecastingData if needed
                                style: TextStyle(
                                  color: const Color(0xFF0A0A0A),
                                  fontSize: 24,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 21,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFE65100),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '8-14d',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Medium Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 24),
                    height: 100,
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.26,
                          color: Colors.black.withOpacity(0.10),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Medium',
                                style: TextStyle(
                                  color: const Color(0xFF626C70),
                                  fontSize: 11,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                              Text(
                                '1', // TODO: Compute from _forecastingData if needed
                                style: TextStyle(
                                  color: const Color(0xFF0A0A0A),
                                  fontSize: 24,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 49,
                          height: 21,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFF57C00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '15-30d',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Healthy Card
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 24),
                    height: 100,
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 16,
                      right: 16,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1.26,
                          color: Colors.black.withOpacity(0.10),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Healthy',
                                style: TextStyle(
                                  color: const Color(0xFF626C70),
                                  fontSize: 11,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                              Text(
                                '3', // TODO: Compute from _forecastingData if needed
                                style: TextStyle(
                                  color: const Color(0xFF0A0A0A),
                                  fontSize: 24,
                                  fontFamily: 'Arial',
                                  fontWeight: FontWeight.w400,
                                  height: 1.50,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 43,
                          height: 21,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '30d+',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Arial',
                                fontWeight: FontWeight.w400,
                                height: 1.50,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search, Filter, and Refresh Row
            Row(
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
                      onChanged: (value) => setState(() {}),
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
                // Category Dropdown
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
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items:
                            [
                              'All Categories',
                              'General',
                              'Electrical',
                              'Plumbing',
                              'Carpentry',
                              'Masonry',
                              'HVAC',
                              'Security',
                              'Fire Safety',
                              'Pest Control',
                            ].map((String value) {
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
                              _selectedCategory = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Urgency Dropdown
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
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedUrgency,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        items:
                            [
                              'All Urgencies',
                              'Critical',
                              'High',
                              'Medium',
                              'Low',
                            ].map((String value) {
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
                              _selectedUrgency = newValue;
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
                    onTap: _fetchForecastingData,
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
            const SizedBox(height: 24),

            // Main Content Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Forecast Analysis",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        // Export button
                        Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              // TODO: Implement export functionality
                              if (value == 'pdf') {
                                // Export to PDF
                              } else if (value == 'word') {
                                // Export to Word
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    value: 'pdf',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('PDF'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'word',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.description,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text('Word'),
                                      ],
                                    ),
                                  ),
                                ],
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.download,
                                  size: 20,
                                  color: Colors.blue[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Export',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Data Table
                  _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 30,
                            headingRowHeight: 56,
                            dataRowHeight: 64,
                            headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
                            headingTextStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                            dataTextStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            columns: [
                              DataColumn(label: _fixedCell(0, const Text("ID"))),
                              DataColumn(label: _fixedCell(1, const Text("NAME"))),
                              DataColumn(
                                label: _fixedCell(2, const Text("CATEGORY")),
                              ),
                              DataColumn(label: _fixedCell(3, const Text("STATUS"))),
                              DataColumn(
                                label: _fixedCell(
                                  4,
                                  const Text("STOCK(AVAIL/TOTAL)"),
                                ),
                              ),
                              DataColumn(
                                label: _fixedCell(5, const Text("USAGE/MO")),
                              ),
                              DataColumn(label: _fixedCell(6, const Text("TREND"))),
                              DataColumn(
                                label: _fixedCell(7, const Text("DAYS TO MIN")),
                              ),
                              DataColumn(
                                label: _fixedCell(8, const Text("REORDER BY")),
                              ),
                            ],
                            rows:
                                _paginatedData
                                    .map(
                                      (item) => DataRow(
                                        cells: [
                                          DataCell(_fixedCell(0, Text(item['id']))),
                                          DataCell(
                                            _fixedCell(1, _ellipsis(item['name'])),
                                          ),
                                          DataCell(
                                            _fixedCell(
                                              2,
                                              _categoryTag(item['category']),
                                            ),
                                          ),
                                          DataCell(
                                            _fixedCell(3, _statusTag(item['status'])),
                                          ),
                                          DataCell(
                                            _fixedCell(4, Text(item['stock'])),
                                          ),
                                          DataCell(
                                            _fixedCell(5, Text(item['usage'])),
                                          ),
                                          DataCell(
                                            _fixedCell(
                                              6,
                                              _trendWidget(item['trend']['icon'], item['trend']['color']),
                                            ),
                                          ),
                                          DataCell(
                                            _fixedCell(
                                              7,
                                              _daysToMinWidget(item['daysToMin']),
                                            ),
                                          ),
                                          DataCell(
                                            _fixedCell(8, Text(item['reorderBy'])),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                  // Pagination controls
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Page info
                        Text(
                          'Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage > _forecastingData.length) ? _forecastingData.length : _currentPage * _itemsPerPage} of ${_forecastingData.length} entries',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),

                        // Pagination buttons
                        Row(
                          children: [
                            // Previous button
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: _currentPage > 1 ? Colors.white : Colors.grey[100],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.chevron_left,
                                  size: 18,
                                  color: _currentPage > 1 ? Colors.grey[700] : Colors.grey[400],
                                ),
                                onPressed: _currentPage > 1
                                    ? () {
                                        setState(() {
                                          _currentPage--;
                                        });
                                      }
                                    : null,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Page numbers
                            ...List.generate(
                              _totalPages > 5 ? 5 : _totalPages,
                              (index) {
                                int pageNumber;
                                if (_totalPages <= 5) {
                                  pageNumber = index + 1;
                                } else if (_currentPage <= 3) {
                                  pageNumber = index + 1;
                                } else if (_currentPage >= _totalPages - 2) {
                                  pageNumber = _totalPages - 4 + index;
                                } else {
                                  pageNumber = _currentPage - 2 + index;
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _currentPage = pageNumber;
                                      });
                                    },
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      decoration: BoxDecoration(
                                        color: _currentPage == pageNumber
                                            ? Colors.blue[600]
                                            : Colors.white,
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          pageNumber.toString(),
                                          style: TextStyle(
                                            color: _currentPage == pageNumber
                                                ? Colors.white
                                                : Colors.grey[700],
                                            fontSize: 14,
                                            fontWeight: _currentPage == pageNumber
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 8),

                            // Next button
                            Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: _currentPage < _totalPages ? Colors.white : Colors.grey[100],
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: _currentPage < _totalPages ? Colors.grey[700] : Colors.grey[400],
                                ),
                                onPressed: _currentPage < _totalPages
                                    ? () {
                                        setState(() {
                                          _currentPage++;
                                        });
                                      }
                                    : null,
                                padding: EdgeInsets.zero,
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
    );
  }
}
