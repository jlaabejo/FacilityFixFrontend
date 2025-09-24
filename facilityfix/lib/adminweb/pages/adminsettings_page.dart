import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';

class AdminWebSettingsPage extends StatefulWidget {
  const AdminWebSettingsPage({super.key});

  @override
  State<AdminWebSettingsPage> createState() => _AdminWebSettingsPageState();
}

class _AdminWebSettingsPageState extends State<AdminWebSettingsPage> {
  // Route mapping helper function 
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

  // Logout functionality 
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

  // Settings form controllers - for backend integration
  
  final TextEditingController _maintenanceIntervalController = TextEditingController();
  final TextEditingController _sessionTimeoutController = TextEditingController();

  // Settings state variables - for backend data binding
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _maintenanceReminders = true;
  bool _overdueAlerts = true;
  bool _inventoryAlerts = true;
  bool _autoAssignTasks = false;
  bool _allowGuestAccess = false;
  bool _requireTwoFactor = false;
  bool _enableAuditLog = true;
  String _selectedTheme = 'Light';
  String _selectedLanguage = 'English';
  String _defaultPriority = 'Medium';

  // Theme and language options
  final List<String> _themeOptions = ['Light', 'Dark', 'Auto'];
  final List<String> _languageOptions = ['English', 'Filipino', 'Spanish'];
  final List<String> _priorityOptions = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _loadSettingsData();
  }

  void _loadSettingsData() {
    
    _maintenanceIntervalController.text = '30';
    _sessionTimeoutController.text = '60';
  }

  void _saveSettings() {
    final settingsData = {
      
      'system': {
        'maintenanceInterval': int.tryParse(_maintenanceIntervalController.text) ?? 30,
        'sessionTimeout': int.tryParse(_sessionTimeoutController.text) ?? 60,
        'theme': _selectedTheme,
        'language': _selectedLanguage,
        'defaultPriority': _defaultPriority,
      },
      'notifications': {
        'email': _emailNotifications,
        'sms': _smsNotifications,
        'push': _pushNotifications,
        'maintenanceReminders': _maintenanceReminders,
        'overdueAlerts': _overdueAlerts,
        'inventoryAlerts': _inventoryAlerts,
      },
      'security': {
        'autoAssignTasks': _autoAssignTasks,
        'allowGuestAccess': _allowGuestAccess,
        'requireTwoFactor': _requireTwoFactor,
        'enableAuditLog': _enableAuditLog,
      },
    };

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text('Are you sure you want to reset all settings to default values?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _loadDefaultSettings();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to default values'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  void _loadDefaultSettings() {
    
    _maintenanceIntervalController.text = '30';
    _sessionTimeoutController.text = '60';
    _emailNotifications = true;
    _smsNotifications = false;
    _pushNotifications = true;
    _maintenanceReminders = true;
    _overdueAlerts = true;
    _inventoryAlerts = true;
    _autoAssignTasks = false;
    _allowGuestAccess = false;
    _requireTwoFactor = false;
    _enableAuditLog = true;
    _selectedTheme = 'Light';
    _selectedLanguage = 'English';
    _defaultPriority = 'Medium';
  }

  @override
  void dispose() {
    
    _maintenanceIntervalController.dispose();
    _sessionTimeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'settings',
      onNavigate: (routeKey) {
        final routePath = _getRoutePath(routeKey);
        if (routePath != null) {
          context.go(routePath);
        } else if (routeKey == 'logout') {
          _handleLogout(context);
        }
      },

      // ✅ Single scrollable page; no Expanded inside a Column with unbounded height
      body: SingleChildScrollView(
        primary: false, // plays nicer if parent provides the primary scroll
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // shrink-wrap vertically
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with breadcrumbs and action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Breadcrumb and title section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Settings",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Dashboard",
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        const Text(
                          "Settings",
                          style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                // Action buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _resetToDefaults,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Reset to Defaults"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[300]!),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save, size: 20),
                      label: const Text(
                        "Save Changes",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 32),

            

            // System Configuration Section
            _buildSettingsSection(
              title: "System Configuration",
              icon: Icons.settings,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _maintenanceIntervalController,
                        label: "Default Maintenance Interval (days)",
                        hint: "30",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _sessionTimeoutController,
                        label: "Session Timeout (minutes)",
                        hint: "60",
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedTheme,
                        label: "Theme",
                        items: _themeOptions,
                        onChanged: (value) => setState(() => _selectedTheme = value!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        value: _selectedLanguage,
                        label: "Language",
                        items: _languageOptions,
                        onChanged: (value) => setState(() => _selectedLanguage = value!),
                      ),
                    ),
                  ],
                ),
                _buildDropdown(
                  value: _defaultPriority,
                  label: "Default Task Priority",
                  items: _priorityOptions,
                  onChanged: (value) => setState(() => _defaultPriority = value!),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Notifications Section
            _buildSettingsSection(
              title: "Notifications",
              icon: Icons.notifications,
              children: [
                _buildSwitchTile(
                  title: "Email Notifications",
                  subtitle: "Receive notifications via email",
                  value: _emailNotifications,
                  onChanged: (value) => setState(() => _emailNotifications = value),
                ),
                _buildSwitchTile(
                  title: "SMS Notifications",
                  subtitle: "Receive notifications via SMS",
                  value: _smsNotifications,
                  onChanged: (value) => setState(() => _smsNotifications = value),
                ),
                _buildSwitchTile(
                  title: "Push Notifications",
                  subtitle: "Receive push notifications",
                  value: _pushNotifications,
                  onChanged: (value) => setState(() => _pushNotifications = value),
                ),
                _buildSwitchTile(
                  title: "Maintenance Reminders",
                  subtitle: "Get reminders for scheduled maintenance",
                  value: _maintenanceReminders,
                  onChanged: (value) => setState(() => _maintenanceReminders = value),
                ),
                _buildSwitchTile(
                  title: "Overdue Task Alerts",
                  subtitle: "Get alerts for overdue tasks",
                  value: _overdueAlerts,
                  onChanged: (value) => setState(() => _overdueAlerts = value),
                ),
                _buildSwitchTile(
                  title: "Inventory Alerts",
                  subtitle: "Get alerts for low inventory",
                  value: _inventoryAlerts,
                  onChanged: (value) => setState(() => _inventoryAlerts = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Security & Access Section
            _buildSettingsSection(
              title: "Security & Access",
              icon: Icons.security,
              children: [
                _buildSwitchTile(
                  title: "Auto-assign Tasks",
                  subtitle: "Automatically assign tasks to available technicians",
                  value: _autoAssignTasks,
                  onChanged: (value) => setState(() => _autoAssignTasks = value),
                ),
                _buildSwitchTile(
                  title: "Allow Guest Access",
                  subtitle: "Allow limited access to guests",
                  value: _allowGuestAccess,
                  onChanged: (value) => setState(() => _allowGuestAccess = value),
                ),
                _buildSwitchTile(
                  title: "Require Two-Factor Authentication",
                  subtitle: "Require 2FA for all users",
                  value: _requireTwoFactor,
                  onChanged: (value) => setState(() => _requireTwoFactor = value),
                ),
                _buildSwitchTile(
                  title: "Enable Audit Log",
                  subtitle: "Keep detailed logs of all system activities",
                  value: _enableAuditLog,
                  onChanged: (value) => setState(() => _enableAuditLog = value),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // System Maintenance Section
            _buildSettingsSection(
              title: "System Maintenance",
              icon: Icons.build,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Database backup initiated'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        icon: const Icon(Icons.backup),
                        label: const Text("Backup Database"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache cleared successfully'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text("Clear Cache"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('System Diagnostics'),
                        content: const Text('System diagnostics completed successfully.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text("Run System Diagnostics"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,  // add more left/right spacing
                      vertical: 16,    // keep good top/bottom spacing
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  // Settings section container widget
  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // shrink-wrap inside section
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.circle, size: 0), // placeholder to keep sizes aligned if needed
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children.map((child) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: child,
                )),
          ],
        ),
      ),
    );
  }

  // Text field widget
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF1976D2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Dropdown widget
  Widget _buildDropdown({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF1976D2)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // Switch tile widget for toggleable settings
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF1976D2),
          ),
        ],
      ),
    );
  }
}
