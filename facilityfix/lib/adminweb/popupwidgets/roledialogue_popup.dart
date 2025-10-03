import 'package:flutter/material.dart';

enum RoleDialogMode { create, edit }

class RoleDialog extends StatefulWidget {
  /// If mode == create: [onRoleCreated] is used.
  /// If mode == edit:   [onRoleUpdated] is used and [initialRole] is read.
  final RoleDialogMode mode;
  final Map<String, dynamic>? initialRole;
  final Function(Map<String, dynamic>)? onRoleCreated;
  final Function(Map<String, dynamic>)? onRoleUpdated;

  const RoleDialog({
    super.key,
    required this.mode,
    this.initialRole,
    this.onRoleCreated,
    this.onRoleUpdated,
  });

  /// Helper to show create dialog
  static void showCreate(
    BuildContext context, {
    Function(Map<String, dynamic>)? onRoleCreated,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoleDialog(
        mode: RoleDialogMode.create,
        onRoleCreated: onRoleCreated,
      ),
    );
  }

  /// Helper to show edit dialog
  static void showEdit(
    BuildContext context, {
    required Map<String, dynamic> initialRole,
    Function(Map<String, dynamic>)? onRoleUpdated,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoleDialog(
        mode: RoleDialogMode.edit,
        initialRole: initialRole,
        onRoleUpdated: onRoleUpdated,
      ),
    );
  }

  /// Backward-compatible single entry if you prefer your original call style
  static void show(
    BuildContext context, {
    bool isEdit = false,
    Map<String, dynamic>? initialRole,
    Function(Map<String, dynamic>)? onRoleCreated,
    Function(Map<String, dynamic>)? onRoleUpdated,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RoleDialog(
        mode: isEdit ? RoleDialogMode.edit : RoleDialogMode.create,
        initialRole: initialRole,
        onRoleCreated: onRoleCreated,
        onRoleUpdated: onRoleUpdated,
      ),
    );
  }

  @override
  State<RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<RoleDialog> {
  // Controllers
  final TextEditingController _roleNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Permissions model
  late Map<String, Map<String, bool>> _permissions;

  bool _isRoleNameValid = true;

  // ----- Permissions Catalog -----
  static final _catalog = <_PermissionSection>[
    _PermissionSection(
      title: 'Users',
      icon: Icons.people,
      iconColor: Colors.green,
      categoryKey: 'users',
      items: [
        PermissionItem('viewUsers', 'View Users', 'See all users in the system'),
        PermissionItem('createUsers', 'Create Users', 'Add new users to the system'),
        PermissionItem('editUsers', 'Edit Users', 'Update user details, roles, and access'),
        PermissionItem('deleteUsers', 'Delete Users', 'Remove users from the system'),
        PermissionItem('roleAccessControl', 'Role & Access Control', 'Assign roles and manage user permissions'),
      ],
    ),
    _PermissionSection(
      title: 'System',
      icon: Icons.settings,
      iconColor: Colors.purple,
      categoryKey: 'system',
      items: [
        PermissionItem('viewSystemSettings', 'View System Settings', 'Access system configuration settings'),
        PermissionItem('editSystemSettings', 'Edit System Settings', 'Modify system-level configurations'),
        PermissionItem('backupSystem', 'Backup System', 'Create and manage system backups'),
        PermissionItem('restoreSystem', 'Restore System', 'Restore the system from backups'),
        PermissionItem('manageIntegrations', 'Manage Integrations', 'Connect FacilityFix with third-party tools or apps'),
      ],
    ),
    _PermissionSection(
      title: 'Analytics',
      icon: Icons.analytics,
      iconColor: Colors.orange,
      categoryKey: 'analytics',
      items: [
        PermissionItem('viewAnalytics', 'View Analytics', 'Access dashboards and performance metrics'),
        PermissionItem('generateReports', 'Generate Reports', 'Create and export analytics reports'),
        PermissionItem('scheduleReports', 'Schedule Reports', 'Automate recurring reports'),
        PermissionItem('manageAnalyticsSettings', 'Manage Analytics Settings', 'Configure KPIs, dashboards, and reporting tools'),
      ],
    ),
    _PermissionSection(
      title: 'Announcements',
      icon: Icons.campaign,
      iconColor: Colors.pink,
      categoryKey: 'announcements',
      items: [
        PermissionItem('viewAnnouncements', 'View Announcements', 'Access published announcements'),
        PermissionItem('createAnnouncements', 'Create Announcements', 'Add new announcements for teams or departments'),
        PermissionItem('editAnnouncements', 'Edit Announcements', 'Update or modify announcement details'),
        PermissionItem('deleteAnnouncements', 'Delete Announcements', 'Remove announcements from the system'),
        PermissionItem('publishAnnouncements', 'Publish Announcements', 'Publish or unpublish announcements'),
      ],
    ),
    _PermissionSection(
      title: 'Inventory',
      icon: Icons.inventory_2,
      iconColor: Color(0xFFF8BBD0), // Colors.pink.shade100 without requiring context
      categoryKey: 'inventory',
      items: [
        PermissionItem('viewInventory', 'View Inventory', 'Access inventory items and stock levels'),
        PermissionItem('addInventory', 'Add Inventory', 'Add new items to the inventory'),
        PermissionItem('editInventory', 'Edit Inventory', 'Update item details or adjust quantities'),
        PermissionItem('deleteInventory', 'Delete Inventory', 'Remove items from the inventory'),
        PermissionItem('trackInventory', 'Track Inventory', 'Monitor item usage and movements'),
        PermissionItem('manageSuppliers', 'Manage Suppliers', 'Add or edit supplier information'),
      ],
    ),
    _PermissionSection(
      title: 'Work Order Management',
      icon: Icons.work,
      iconColor: Color(0xFF1565C0), // Colors.blue.shade700
      categoryKey: 'workOrder',
      items: [
        PermissionItem('viewWorkOrders', 'View Work Orders', 'Access all work orders in the system'),
        PermissionItem('createWorkOrders', 'Create Work Orders', 'Submit new tasks (repairs, maintenance, inspections, etc.)'),
        PermissionItem('editWorkOrders', 'Edit Work Orders', 'Update details, priority, or assigned staff'),
        PermissionItem('deleteWorkOrders', 'Delete Work Orders', 'Remove a work order from the system'),
        PermissionItem('assignWorkOrders', 'Assign Work Orders', 'Assign work orders to staff, teams, or vendors'),
        PermissionItem('updateWorkOrderStatus', 'Update Work Order Status', 'Change status to Pending, In Progress, On Hold, or Completed'),
        PermissionItem('scheduleWorkOrders', 'Schedule Work Orders', 'Plan recurring or future tasks'),
        PermissionItem('viewWorkOrderHistory', 'View Work Order History', 'Access logs of completed work orders'),
      ],
    ),
    _PermissionSection(
      title: 'Calendar',
      icon: Icons.calendar_today,
      iconColor: Colors.blue,
      categoryKey: 'calendar',
      items: [
        PermissionItem('viewCalendar', 'View Calendar', 'Access the facility calendar (maintenance, inspections, repairs)'),
        PermissionItem('createTasks', 'Create Tasks', 'Add new calendar events (tasks, repairs, inspections, etc.)'),
        PermissionItem('editEvents', 'Edit Events', 'Update event details, reschedule, or change assignments'),
        PermissionItem('deleteEvents', 'Delete Events', 'Remove events from the calendar'),
        PermissionItem('syncCalendar', 'Sync Calendar', 'Integrate with external calendars (Google, Outlook, etc.)'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Initialize default permission map (all false)
    _permissions = _emptyPermissionsFromCatalog();

    if (widget.mode == RoleDialogMode.edit && widget.initialRole != null) {
      // Pre-fill fields
      _roleNameController.text = (widget.initialRole!['name'] ?? '').toString();
      _descriptionController.text = (widget.initialRole!['description'] ?? '').toString();

      // Accept either nested map or flat list for permissions
      final rawPerms = widget.initialRole!['permissions'];
      if (rawPerms is Map) {
        // Nested map
        final existingPerms = rawPerms.map(
          (k, v) => MapEntry(k.toString(), Map<String, bool>.from((v as Map).map(
            (ik, iv) => MapEntry(ik.toString(), iv == true),
          ))),
        );
        _mergePermissions(existingPerms);
      } else if (rawPerms is List) {
        // Flat list
        final asList = rawPerms.map((e) => e.toString()).toSet();
        final mapped = _emptyPermissionsFromCatalog();
        for (final section in _catalog) {
          for (final item in section.items) {
            if (asList.contains(item.key)) {
              mapped[section.categoryKey]![item.key] = true;
            }
          }
        }
        _mergePermissions(mapped);
      }
    }
  }

  @override
  void dispose() {
    _roleNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 850),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoleNameField(),
                    const SizedBox(height: 24),
                    _buildDescriptionField(),
                    const SizedBox(height: 32),
                    ..._catalog.expand((section) => [
                          _buildPermissionSection(
                            section.title,
                            section.icon,
                            section.iconColor,
                            section.items,
                            section.categoryKey,
                          ),
                          const SizedBox(height: 24),
                        ]),
                  ],
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 32, right: 24, top: 24, bottom: 16),
      child: Row(
        children: [
          Text(
            widget.mode == RoleDialogMode.create ? 'Create a New Role' : 'Edit Role',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.grey, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role Name',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _roleNameController,
          decoration: InputDecoration(
            hintText: 'Enter role name',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isRoleNameValid ? Colors.grey[300]! : Colors.red,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isRoleNameValid ? Colors.blue : Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorText: _isRoleNameValid ? null : 'Role name is required',
          ),
          onChanged: (value) {
            setState(() {
              _isRoleNameValid = value.trim().isNotEmpty;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter role description....',
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionSection(
    String title,
    IconData icon,
    Color iconColor,
    List<PermissionItem> permissions,
    String categoryKey,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const Spacer(),
            // Optional "Select all" / "Clear" for each section
            TextButton(
              onPressed: () => _toggleSection(categoryKey, true),
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: () => _toggleSection(categoryKey, false),
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...permissions.map(
          (p) => _buildPermissionItem(p.key, p.title, p.description, categoryKey),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(
    String key,
    String title,
    String description,
    String categoryKey,
  ) {
    final value = _permissions[categoryKey]![key] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: (v) {
              setState(() {
                _permissions[categoryKey]![key] = v ?? false;
              });
            },
            activeColor: Colors.blue[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final isCreate = widget.mode == RoleDialogMode.create;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: isCreate ? Colors.green : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              isCreate ? 'Create Role' : 'Save Changes',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Actions ----------

  void _submit() {
    setState(() {
      _isRoleNameValid = _roleNameController.text.trim().isNotEmpty;
    });
    if (!_isRoleNameValid) return;

    final isCreate = widget.mode == RoleDialogMode.create;

    if (isCreate) {
      final roleData = {
        'id': DateTime.now().toIso8601String(),
        'name': _roleNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'permissions': _deepCopyPermissions(_permissions),
        'createdAt': DateTime.now().toIso8601String(),
        'users': 0,
      };
      try {
        widget.onRoleCreated?.call(roleData);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role "${roleData['name']}" created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) _showErrorSnackBar('Error creating role: $e');
      }
    } else {
      final updatedRole = {
        ...?widget.initialRole,
        'name': _roleNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'permissions': _deepCopyPermissions(_permissions),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      try {
        widget.onRoleUpdated?.call(updatedRole);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Role "${updatedRole['name']}" updated successfully'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) _showErrorSnackBar('Error updating role: $e');
      }
    }
  }

  // ---------- Helpers ----------

  Map<String, Map<String, bool>> _emptyPermissionsFromCatalog() {
    final result = <String, Map<String, bool>>{};
    for (final section in _catalog) {
      result[section.categoryKey] = {
        for (final item in section.items) item.key: false,
      };
    }
    return result;
  }

  void _mergePermissions(Map<String, Map<String, bool>> other) {
    for (final entry in other.entries) {
      final cat = entry.key;
      if (_permissions.containsKey(cat)) {
        for (final kv in entry.value.entries) {
          if (_permissions[cat]!.containsKey(kv.key)) {
            _permissions[cat]![kv.key] = kv.value;
          }
        }
      }
    }
  }

  Map<String, Map<String, bool>> _deepCopyPermissions(Map<String, Map<String, bool>> src) {
    return {
      for (final cat in src.keys) cat: {...src[cat]!},
    };
  }

  void _toggleSection(String categoryKey, bool value) {
    setState(() {
      final cat = _permissions[categoryKey];
      if (cat != null) {
        for (final k in cat.keys) {
          cat[k] = value;
        }
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

// ----- Models / Structs -----

class PermissionItem {
  final String key;
  final String title;
  final String description;

  const PermissionItem(this.key, this.title, this.description);
}

class _PermissionSection {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String categoryKey;
  final List<PermissionItem> items;

  const _PermissionSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.categoryKey,
    required this.items,
  });
}
