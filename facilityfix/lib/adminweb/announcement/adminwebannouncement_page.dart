import 'package:facilityfix/adminweb/widgets/tags.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../layout/facilityfix_layout.dart';
import 'pop_up/announcement_viewdetails_popup.dart';
import '../services/api_service.dart';
import '../../services/auth_storage.dart';
import '../widgets/delete_popup.dart';

class AdminWebAnnouncementPage extends StatefulWidget {
  const AdminWebAnnouncementPage({super.key});

  @override
  State<AdminWebAnnouncementPage> createState() =>
      _AdminWebAnnouncementPageState();
}

class _AdminWebAnnouncementPageState extends State<AdminWebAnnouncementPage> {
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

  List<Map<String, dynamic>> _announcementItems = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  // Search and filter controllers for backend integration
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Utility Interruption',
    'Power Outage',
    'Pest Control',
    'Maintenance',
  ];
  
  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  
  // Sorting
  String _sortColumn = 'dateAdded';
  bool _sortAscending = false; // Default to descending (newest first)

  // Column widths for table
  final List<double> _colW = <double>[
    140, // ID
    270, // TITLE
    180, // TYPE
    200, // LOCATION
    110, // DATE ADDED
    48, // ACTION
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

  // Action dropdown menu methods
  void _showActionMenu(
    BuildContext context,
    Map<String, dynamic> announcement,
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
        _handleActionSelection(value, announcement);
      }
    });
  }

  // Handle action selection
  void _handleActionSelection(
    String action,
    Map<String, dynamic> announcement,
  ) {
    switch (action) {
      case 'view':
        _viewaAnnouncement(announcement);
        break;
      case 'edit':
        _editAnnouncement(announcement);
        break;
      case 'delete':
        _deleteAnnouncement(announcement);
        break;
    }
  }

  // View announcement method
  void _viewaAnnouncement(Map<String, dynamic> announcement) {
    AnnouncementDetailDialog.show(context, announcement);
  }

  void _editAnnouncement(Map<String, dynamic> announcement) {
    final announcementId = announcement['database_id'];
    if (announcementId != null) {
      context.go('/announcement/edit/$announcementId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Cannot edit: Announcement ID not found',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
          elevation: 6,
        ),
      );
    }
  }

  Future<void> _deleteAnnouncement(Map<String, dynamic> announcement) async {
    final databaseId = announcement['database_id'];
    final displayId = announcement['id'];

    print('[DELETE] Starting delete process');
    print('[DELETE] Database ID: $databaseId');
    print('[DELETE] Display ID: $displayId');

    if (databaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Cannot delete: Announcement ID not found'),
              ),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final confirmed = await showDeleteDialog(
      context,
      itemName: displayId ?? 'this announcement',
      description: 'Are you sure you want to delete announcement ${displayId ?? ""}? This action cannot be undone.',
    );

    if (!confirmed) {
      print('[DELETE] Delete cancelled by user');
      return;
    }

    try {
      print('[DELETE] Calling API to delete announcement with ID: $databaseId');
      
      await _apiService.deleteAnnouncement(
        databaseId,
        notifyDeactivation: false,
      );

      print('[DELETE] API call successful');

      // Remove from local list using database_id
      if (mounted) {
        setState(() {
          final initialCount = _announcementItems.length;
          _announcementItems.removeWhere((item) {
            final itemDatabaseId = item['database_id'];
            final shouldRemove = itemDatabaseId == databaseId;
            if (shouldRemove) {
              print('[DELETE] Removing item with database_id: $itemDatabaseId');
            }
            return shouldRemove;
          });
          final afterCount = _announcementItems.length;
          print('[DELETE] Items before: $initialCount, after: $afterCount');
          
          // Reset to first page if current page is now out of bounds
          if (_currentPage > _totalPages && _totalPages > 0) {
            _currentPage = _totalPages;
          } else if (_announcementItems.isEmpty) {
            _currentPage = 1;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('${displayId ?? "Announcement"} deleted successfully')),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );

        // Optional: Refresh from server to ensure sync
        // Comment this out if you don't want to refresh after delete
        // await Future.delayed(const Duration(milliseconds: 500));
        // await _fetchAnnouncements();
      }
    } catch (e) {
      print('[DELETE] Error occurred: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to delete: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatId(String? id) {
    if (id == null || id.isEmpty) return 'N/A';
    return id;
  }

  // Filtered announcements based on search and filter
  List<Map<String, dynamic>> get _filteredAnnouncements {
    var filtered = _announcementItems.where((announcement) {
      // Search filter - now searches all columns
      bool matchesSearch = _searchController.text.isEmpty ||
          announcement['id'].toString().toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
          announcement['Title'].toString().toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
          announcement['type'].toString().toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
          announcement['location'].toString().toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ) ||
          announcement['dateAdded'].toString().toLowerCase().contains(
                _searchController.text.toLowerCase(),
              );

      // Type filter
      bool matchesFilter = _selectedFilter == 'All' ||
          announcement['type'].toString().toLowerCase() ==
              _selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
    
    // Apply sorting
    filtered.sort((a, b) {
      int comparison;
      
      switch (_sortColumn) {
        case 'id':
          comparison = a['id'].toString().compareTo(b['id'].toString());
          break;
        case 'Title':
          comparison = a['Title'].toString().compareTo(b['Title'].toString());
          break;
        case 'type':
          comparison = a['type'].toString().compareTo(b['type'].toString());
          break;
        case 'location':
          comparison = a['location'].toString().compareTo(b['location'].toString());
          break;
        case 'dateAdded':
        default:
          // Parse dates for proper comparison
          DateTime dateA = DateTime.tryParse(a['dateAdded'].toString()) ?? DateTime(1970);
          DateTime dateB = DateTime.tryParse(b['dateAdded'].toString()) ?? DateTime(1970);
          comparison = dateA.compareTo(dateB);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return filtered;
  }

  // Paginated announcements
  List<Map<String, dynamic>> _getPaginatedAnnouncements() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    final filtered = _filteredAnnouncements;
    if (startIndex >= filtered.length) return [];

    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int get _totalPages {
    final filtered = _filteredAnnouncements;
    return filtered.isEmpty ? 1 : (filtered.length / _itemsPerPage).ceil();
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

    // Show max 5 page numbers at a time
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
              color: i == _currentPage
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

  // Search functionality
  void _onSearchChanged(String value) {
    setState(() {
      _currentPage = 1; // Reset to first page on search
    });
  }

  // Filter functionality
  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
      _currentPage = 1; // Reset to first page on filter change
    });
  }
  
  // Sorting functionality
  void _onSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _currentPage = 1; // Reset to first page on sort
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  // Auth initialization method
  Future<void> _initializeAuth() async {
    try {
      // Check if user has a valid token in AuthStorage
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        // Token exists, API service will use it automatically via _getAuthHeaders()
        print('[v0] Auth token found in storage');
        await _fetchAnnouncements();
      } else {
        print('[v0] ERROR: No authentication token found');
        setState(() {
          _errorMessage = 'Authentication token not available. Please log in.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[v0] Error initializing auth: $e');
      setState(() {
        _errorMessage = 'Authentication error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const buildingId = 'building_001';

      print('[v0] Fetching announcements for building: $buildingId');

      // Admin should see ALL announcements regardless of audience
      // We'll fetch all audiences and merge them
      final allAnnouncementsMap = <String, Map<String, dynamic>>{};

      // Fetch announcements for each audience type
      for (final audience in ['all', 'staff', 'tenants']) {
        try {
          final response = await _apiService.getAnnouncements(
            buildingId: buildingId,
            audience: audience,
            activeOnly: false,
            publishedOnly: false, // Admin should see drafts too
          );

          if (response.containsKey('announcements')) {
            final announcements = response['announcements'] as List?;
            if (announcements != null) {
              for (final ann in announcements) {
                // Use announcement ID as key to avoid duplicates
                final id = ann['id'] ?? ann['formatted_id'];
                if (id != null) {
                  allAnnouncementsMap[id] = ann as Map<String, dynamic>;
                }
              }
            }
          }
        } catch (e) {
          print('[v0] Warning: Failed to fetch $audience announcements: $e');
        }
      }

      // Convert map to list
      final announcementsList = allAnnouncementsMap.values.toList();

      print('[v0] Total announcements loaded: ${announcementsList.length}');

      if (announcementsList.isNotEmpty) {
          setState(() {
            _announcementItems = List<Map<String, dynamic>>.from(
              announcementsList.map((announcement) {
                return {
                  // Display fields for table
                  'id':
                      announcement['formatted_id'] ??
                      announcement['id'] ??
                      'N/A',
                  'database_id': announcement['id'], // This is critical for delete
                  'Title': announcement['title'] ?? 'Untitled',
                  'type': announcement['type'] ?? 'General',
                  'location':
                      announcement['location_affected'] ?? 'Not specified',
                  'dateAdded':
                      announcement['date_added'] != null
                          ? DateTime.parse(
                            announcement['date_added'],
                          ).toString().split(' ')[0]
                          : 'N/A',

                  // Additional fields for detail popup
                  'title': announcement['title'] ?? 'Untitled',
                  'messageBody':
                      announcement['content'] ??
                      'No message content available.',
                  'audiences': _parseAudience(announcement['audience']),
                  'scheduleVisibility': _parseSchedule(announcement),
                  'scheduled_publish_date': announcement['scheduled_publish_date'],
                  'expiry_date': announcement['expiry_date'],
                  'attachments': announcement['attachments'] ?? [],
                  'isPinned': announcement['is_pinned'] ?? false,
                  'content': announcement['content'] ?? '',
                  'audience': announcement['audience'] ?? 'all',
                  'is_active': announcement['is_active'] ?? true,
                  'building_id': announcement['building_id'] ?? buildingId,
                  'created_at': announcement['created_at'],
                  'updated_at': announcement['updated_at'],
                };
              }),
            );
            _isLoading = false;
            print(
              '[v0] Successfully loaded ${_announcementItems.length} announcements',
            );
          });
      } else {
        setState(() {
          _announcementItems = [];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('[v0] Error fetching announcements: $e');
      print('[v0] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Failed to load announcements: $e';
        _isLoading = false;
      });
    }
  }

  List<String> _parseAudience(String? audience) {
    if (audience == null || audience.isEmpty) return ['All'];

    switch (audience.toLowerCase()) {
      case 'tenant':
      case 'tenants':
        return ['Tenants'];
      case 'staff':
      case 'maintenance staff':
        return ['Maintenance Staff'];
      case 'all':
      default:
        return ['All'];
    }
  }

  Map<String, dynamic>? _parseSchedule(Map<String, dynamic> announcement) {
    final startDate = announcement['start_date'];
    final endDate = announcement['end_date'];
    final startTime = announcement['start_time'];
    final endTime = announcement['end_time'];

    if (startDate != null || endDate != null) {
      return {
        'startDate': startDate,
        'endDate': endDate,
        'startTime': startTime ?? '00:00',
        'endTime': endTime ?? '23:59',
      };
    }

    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FacilityFixLayout(
      currentRoute: 'announcement',
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
            // Header Section with breadcrumbs and Create New button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Breadcrumb and title section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Announcement",
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
                          onPressed: null,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Announcement'),
                        ),
                      ],
                    ),
                  ],
                ),
                // Create New button
                ElevatedButton.icon(
                  onPressed: () {
                    context.go('/adminweb/pages/createannouncement');
                  },
                  icon: const Icon(Icons.add, size: 22),
                  label: const Text(
                    "Create New",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAnnouncements,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              // Main Content Container
              Container(
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
                child: Column(
                  children: [
                    // Table header with search and filter
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Announcement",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          // Search and Filter section
                          Row(
                            children: [
                              // Search field
                              Container(
                                width: 240,
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    suffixIcon: Icon(
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
                                      vertical: 7,
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
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: InkWell(
                                    onTap: _fetchAnnouncements,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.refresh_rounded, size: 20, color: Colors.blue[600]),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Filter button
                                PopupMenuButton<String>(
                                initialValue: _selectedFilter,
                                onSelected: _onFilterChanged,
                                itemBuilder:
                                    (context) =>
                                        _filterOptions.map((filter) {
                                          return PopupMenuItem(
                                            value: filter,
                                            child: Text(filter),
                                          );
                                        }).toList(),
                                child: Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.tune,
                                        color: Colors.grey[600],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Filter",
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.grey[400]),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _fetchAnnouncements,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_announcementItems.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: Text(
                            'No announcement found',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else

                    // Data Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 30,
                        headingRowHeight: 56,
                        dataRowHeight: 64,
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey[50],
                        ),
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
                          DataColumn(
                            label: _fixedCell(
                              0,
                              GestureDetector(
                                onTap: () => _onSort('id'),
                                child: Row(
                                  children: [
                                    const Text("ID"),
                                    if (_sortColumn == 'id')
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
                          ),
                          DataColumn(
                            label: _fixedCell(
                              1,
                              GestureDetector(
                                onTap: () => _onSort('Title'),
                                child: Row(
                                  children: [
                                    const Text("ANNOUNCEMENT TITLE"),
                                    if (_sortColumn == 'Title')
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
                          ),
                          DataColumn(
                            label: _fixedCell(
                              2,
                              GestureDetector(
                                onTap: () => _onSort('type'),
                                child: Row(
                                  children: [
                                    const Text("TYPE"),
                                    if (_sortColumn == 'type')
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
                          ),
                          DataColumn(
                            label: _fixedCell(
                              3,
                              GestureDetector(
                                onTap: () => _onSort('location'),
                                child: Row(
                                  children: [
                                    const Text("LOCATION"),
                                    if (_sortColumn == 'location')
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
                          ),
                          DataColumn(
                            label: _fixedCell(
                              4,
                              GestureDetector(
                                onTap: () => _onSort('dateAdded'),
                                child: Row(
                                  children: [
                                    const Text("DATE CREATED"),
                                    if (_sortColumn == 'dateAdded')
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
                          ),
                          DataColumn(label: _fixedCell(5, const Text(""))),
                        ],
                        rows:
                            _getPaginatedAnnouncements().map((announcement) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    _fixedCell(
                                      0,
                                      _ellipsis(
                                        announcement['id'],
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _fixedCell(
                                      1,
                                      _ellipsis(announcement['Title']),
                                    ),
                                  ),
                                  DataCell(
                                    _fixedCell(
                                      2,
                                      AnnouncementType(announcement['type']),
                                    ),
                                  ),
                                  DataCell(
                                    _fixedCell(
                                      3,
                                      _ellipsis(announcement['location']),
                                    ),
                                  ),
                                  DataCell(
                                    _fixedCell(
                                      4,
                                      _ellipsis(announcement['dateAdded']),
                                    ),
                                  ),
                                  DataCell(
                                    _fixedCell(
                                      5,
                                      Builder(
                                        builder: (context) {
                                          return IconButton(
                                            onPressed: () {
                                              final rbx =
                                                  context.findRenderObject()
                                                      as RenderBox;
                                              final position = rbx
                                                  .localToGlobal(Offset.zero);
                                              _showActionMenu(
                                                context,
                                                announcement,
                                                position,
                                              );
                                            },
                                            icon: Icon(
                                              Icons.more_vert,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                          );
                                        },
                                      ),
                                      align: Alignment.center,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.grey[400]),

                    // Pagination section
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _filteredAnnouncements.isEmpty
                                ? "No entries found"
                                : "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage) > _filteredAnnouncements.length ? _filteredAnnouncements.length : _currentPage * _itemsPerPage} of ${_filteredAnnouncements.length} entries",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          // Pagination controls
                          Row(
                            children: [
                              IconButton(
                                onPressed:
                                    _currentPage > 1 ? _previousPage : null,
                                icon: Icon(
                                  Icons.chevron_left,
                                  color: _currentPage > 1
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              ),
                              ..._buildPageNumbers(),
                              IconButton(
                                onPressed: _currentPage < _totalPages
                                    ? _nextPage
                                    : null,
                                icon: Icon(
                                  Icons.chevron_right,
                                  color: _currentPage < _totalPages
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
    );
  }
}