import 'package:flutter/material.dart';

class FacilityFixLayout extends StatelessWidget {
  final Widget body;
  final String title;

  const FacilityFixLayout({
    super.key,
    required this.body,
    this.title = 'FacilityFix',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 300,
            color: const Color(0xFFFFFFFF),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Image.asset('lib/adminweb/assets/images/logo.png', height: 40),
                      SizedBox(width: 8),
                      Text(
                        'FacilityFix',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'MAIN',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    children: [
                      _navItem(Icons.home_outlined, 'Dashboard', () {}),
                      _navItem(Icons.group, 'User and Role Management', () {}),
                      _navItem(Icons.build_outlined, 'Work Orders', () {}),
                      _navItem(Icons.calendar_today, 'Calendar', () {}),
                      _navItem(Icons.inventory_2_outlined, 'Inventory Management', () {}),
                      _navItem(Icons.analytics_outlined, 'Analytics', () {}),
                      _navItem(Icons.campaign_outlined , 'Notice', () {}),
                    ],
                  ),
                ),
                _navItem(Icons.settings, 'Settings', () {}),
                _navItem(Icons.logout, 'Logout', () {}),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Topbar
                Container(
                  height: 60,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Search
                      SizedBox(
                        width: 300,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                          ),
                        ),
                      ),
                      // Notification + Avatar
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.dashboard_outlined),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.person , color: Colors.grey),
                            onPressed: () {},
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: body,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
  Widget _navItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

