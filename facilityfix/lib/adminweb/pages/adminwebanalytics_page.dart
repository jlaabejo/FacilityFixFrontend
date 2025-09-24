import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';

class AdminWebAnalyticsPage extends StatefulWidget {
  const AdminWebAnalyticsPage({super.key});

  @override
  State<AdminWebAnalyticsPage> createState() => _AdminWebAnalyticsPageState();
}

class _AdminWebAnalyticsPageState extends State<AdminWebAnalyticsPage> {
  // ============================================
  // STATE VARIABLES FOR FILTERS AND DATA
  // ============================================
  String selectedDateRange = 'This Week';
  String selectedStatus = 'All';
  String selectedDowntimeUnit = 'This Month';

  // Mock data for heat map - represents repair requests per unit/floor
  final Map<String, List<HeatMapData>> heatMapData = {
    'Floor 1': [
      HeatMapData('101', 2, Colors.yellow),
      HeatMapData('102', 0, Colors.green),
      HeatMapData('103', 3, Colors.red),
      HeatMapData('104', 2, Colors.orange),
      HeatMapData('105', 2, Colors.orange),
      HeatMapData('106', 3, Colors.red),
    ],
    'Floor 2': [
      HeatMapData('201', 2, Colors.orange),
      HeatMapData('202', 0, Colors.green),
      HeatMapData('203', 1, Colors.yellow),
      HeatMapData('204', 1, Colors.yellow),
      HeatMapData('205', 3, Colors.red),
      HeatMapData('206', 0, Colors.green),
    ],
    'Floor 3': [
      HeatMapData('301', 3, Colors.red),
      HeatMapData('302', 0, Colors.green),
      HeatMapData('303', 3, Colors.red),
      HeatMapData('304', 3, Colors.red),
      HeatMapData('305', 2, Colors.orange),
      HeatMapData('306', 3, Colors.red),
    ],
    'Floor 4': [
      HeatMapData('401', 3, Colors.red),
      HeatMapData('402', 1, Colors.yellow),
      HeatMapData('403', 0, Colors.green),
      HeatMapData('404', 0, Colors.green),
      HeatMapData('405', 0, Colors.green),
      HeatMapData('406', 0, Colors.green),
    ],
    'Floor 5': [
      HeatMapData('501', 1, Colors.yellow),
      HeatMapData('502', 3, Colors.red),
      HeatMapData('503', 3, Colors.red),
      HeatMapData('504', 3, Colors.red),
      HeatMapData('505', 0, Colors.green),
      HeatMapData('506', 1, Colors.yellow),
    ],
    'Floor 6': [
      HeatMapData('601', 3, Colors.red),
      HeatMapData('602', 1, Colors.yellow),
      HeatMapData('603', 2, Colors.orange),
      HeatMapData('604', 3, Colors.red),
      HeatMapData('605', 3, Colors.red),
      HeatMapData('606', 2, Colors.orange),
    ],
    'Floor 7': [
      HeatMapData('701', 0, Colors.green),
      HeatMapData('702', 3, Colors.red),
      HeatMapData('703', 0, Colors.green),
      HeatMapData('704', 1, Colors.yellow),
      HeatMapData('705', 3, Colors.red),
      HeatMapData('706', 3, Colors.red),
    ],
    'Floor 8': [
      HeatMapData('801', 2, Colors.orange),
      HeatMapData('802', 3, Colors.red),
      HeatMapData('803', 3, Colors.red),
      HeatMapData('804', 3, Colors.red),
      HeatMapData('805', 0, Colors.green),
      HeatMapData('806', 3, Colors.red),
    ],
    'Floor 9': [
      HeatMapData('901', 3, Colors.red),
      HeatMapData('902', 1, Colors.yellow),
      HeatMapData('903', 0, Colors.green),
      HeatMapData('904', 3, Colors.red),
      HeatMapData('905', 3, Colors.red),
      HeatMapData('906', 1, Colors.yellow),
    ],
    'Floor 10': [
      HeatMapData('1001', 3, Colors.red),
      HeatMapData('1002', 1, Colors.yellow),
      HeatMapData('1003', 3, Colors.red),
      HeatMapData('1004', 2, Colors.orange),
      HeatMapData('1005', 0, Colors.green),
      HeatMapData('1006', 3, Colors.red),
    ],
  };

  // Helper function to convert routeKey to actual route path
  String? _getRoutePath(String routeKey) {
    final Map<String, String> pathMap = {
      'dashboard': '/dashboard',
      'user_users': '/user/users',
      'user_roles': '/user/roles',
      'work_maintenance': '/work/maintenance',
      'work_repair': '/work/repair',
      'calendar': '/calendar',
      'inventory_items': '/inventory/items',
      'inventory_request': '/inventory/request',
      'analytics': '/analytics',
      'announcement': '/announcement',
      'settings': '/settings',
    };
    return pathMap[routeKey];
  }

  // Handle logout functionality
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return FacilityFixLayout(
      currentRoute: 'analytics',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // TOP ROW: ANALYTICS STATISTICS CARDS
            // ============================================
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) {
                  // Stack cards vertically on smaller screens
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'TOTAL REQUEST',
                              '187',
                              '6.7% from last month',
                              true,
                              Colors.blue,
                              Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'OPEN ISSUE',
                              '42',
                              '8% from last week',
                              false,
                              Colors.yellow[700]!,
                              Icons.layers_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'RESOLVED TODAY',
                              '16',
                              '24% from yesterday',
                              true,
                              Colors.green,
                              Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'RESOLUTION TIME',
                              '2.4 days',
                              '18% improvement',
                              true,
                              Colors.red,
                              Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Show all cards in a row on larger screens
                  return Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsCard(
                          'TOTAL REQUEST',
                          '187',
                          '6.7% from last month',
                          true,
                          Colors.blue,
                          Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'OPEN ISSUE',
                          '42',
                          '8% from last week',
                          false,
                          Colors.yellow[700]!,
                          Icons.layers_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'RESOLVED TODAY',
                          '16',
                          '24% from yesterday',
                          true,
                          Colors.green,
                          Icons.check_circle_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsCard(
                          'RESOLUTION TIME',
                          '2.4 days',
                          '18% improvement',
                          true,
                          Colors.red,
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // ============================================
            // FILTER CONTROLS ROW
            // ============================================
            _buildFilterControls(),
            const SizedBox(height: 24),

            // ============================================
            // MIDDLE ROW: HEAT MAP + PIE CHART
            // ============================================
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1000) {
                  // Stack vertically on smaller screens
                  return Column(
                    children: [
                      _buildBuildingHeatMap(),
                      const SizedBox(height: 20),
                      _buildTopIssueChart(),
                    ],
                  );
                } else {
                  // Side by side on larger screens
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildBuildingHeatMap(),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: _buildTopIssueChart(),
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 24),

            // ============================================
            // BOTTOM ROW: DOWNTIME TRACKING CHART
            // ============================================
            _buildDowntimeTrackingChart(),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ANALYTICS STATISTICS CARD WIDGET
  // ============================================
  Widget _buildAnalyticsCard(
    String title,
    String value,
    String subtitle,
    bool isIncrease,
    Color color,
    IconData icon,
  ) {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title and Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          
          // Main Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          
          // Bottom Row: Percentage and Subtitle
          Row(
            children: [
              Icon(
                isIncrease ? Icons.trending_up : Icons.trending_down,
                color: isIncrease ? Colors.green : Colors.red,
                size: 14,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isIncrease ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // FILTER CONTROLS WIDGET
  // ============================================
  Widget _buildFilterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side filters
        Row(
          children: [
            // Date Range Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedDateRange,
                  items: ['This Week', 'This Month', 'Last Month', 'Last 3 Months']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('Date Range: $value'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDateRange = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Status Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatus,
                  items: ['All', 'Open', 'In Progress', 'Resolved', 'Closed']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('Status: $value'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStatus = newValue!;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
        
        // Right side buttons
        Row(
          children: [
            // Refresh Button
            TextButton.icon(
              onPressed: () {
                // TODO: Implement refresh functionality
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            
            // Export Button
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement export functionality
              },
              icon: const Icon(Icons.file_download, size: 18),
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================
  // BUILDING HEAT MAP WIDGET
  // ============================================
  Widget _buildBuildingHeatMap() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Building Heat Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Heat Map Grid
            Column(
              children: heatMapData.entries.map((floorEntry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Floor Label
                      SizedBox(
                        width: 60,
                        child: Text(
                          floorEntry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Room Units
                      Expanded(
                        child: Row(
                          children: floorEntry.value.map((unit) {
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(right: 4),
                                height: 40,
                                decoration: BoxDecoration(
                                  color: unit.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    unit.unitNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            
            // Heat Map Legend
            const Text(
              'Showing repair request per unit',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildLegendItem(Colors.green, '0 requests'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.yellow, '1-2 requests'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.orange, '2-3 requests'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, '3+ requests'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // LEGEND ITEM HELPER WIDGET
  // ============================================
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  // ============================================
  // TOP ISSUE BY CATEGORY PIE CHART WIDGET
  // ============================================
  Widget _buildTopIssueChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Issue by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Pie Chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      color: Colors.blue,
                      value: 28,
                      title: '',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: 15,
                      title: '',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: 10,
                      title: '',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: Colors.yellow,
                      value: 10,
                      title: '',
                      radius: 50,
                    ),
                    PieChartSectionData(
                      color: Colors.green,
                      value: 10,
                      title: '',
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Chart Legend with Statistics
            const Text(
              'MOST PROBLEMATIC AREAS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildCategoryItem('HVAC', '28 requests', Colors.blue),
            _buildCategoryItem('Electrical', '15 requests', Colors.orange),
            _buildCategoryItem('Civil/Carpentry', '10 requests', Colors.red),
            _buildCategoryItem('Plumbing', '10 requests', Colors.yellow),
            _buildCategoryItem('Others', '10 requests', Colors.green),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CATEGORY ITEM HELPER WIDGET
  // ============================================
  Widget _buildCategoryItem(String category, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DOWNTIME TRACKING CHART WIDGET
  // ============================================
  Widget _buildDowntimeTrackingChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Downtime Tracking',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDowntimeUnit,
                      items: ['This Month', 'Last Month', 'Last 3 Months']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDowntimeUnit = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Area Chart
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[200]!,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          );
                          Widget text;
                          switch (value.toInt()) {
                            case 0:
                              text = const Text('Week 1', style: style);
                              break;
                            case 1:
                              text = const Text('Week 2', style: style);
                              break;
                            case 2:
                              text = const Text('Week 3', style: style);
                              break;
                            case 3:
                              text = const Text('Week 4', style: style);
                              break;
                            default:
                              text = const Text('', style: style);
                              break;
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: text,
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 3,
                  minY: 0,
                  maxY: 5,
                  lineBarsData: [
                    // Unit A - Green line
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 2.8),
                        FlSpot(1, 2.2),
                        FlSpot(2, 2.5),
                        FlSpot(3, 2.1),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                    
                    // Unit B - Blue line
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 4.2),
                        FlSpot(1, 2.8),
                        FlSpot(2, 3.5),
                        FlSpot(3, 3.2),
                      ],
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    
                    // Unit C - Red line
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 4.8),
                        FlSpot(1, 4.2),
                        FlSpot(2, 4.5),
                        FlSpot(3, 4.1),
                      ],
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Chart Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChartLegendItem('Unit A', Colors.green),
                const SizedBox(width: 24),
                _buildChartLegendItem('Unit B', Colors.blue),
                const SizedBox(width: 24),
                _buildChartLegendItem('Unit C', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CHART LEGEND ITEM HELPER WIDGET
  // ============================================
  Widget _buildChartLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================
// HEAT MAP DATA MODEL
// Helper class to structure heat map data
// ============================================
class HeatMapData {
  final String unitNumber;
  final int requestCount;
  final Color color;

  HeatMapData(this.unitNumber, this.requestCount, this.color);
}