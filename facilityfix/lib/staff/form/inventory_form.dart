import 'package:flutter/material.dart' hide FilledButton;
import 'package:flutter/services.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/buttons.dart'; // FilledButton
import 'package:facilityfix/widgets/forms.dart' hide DropdownField;   // InputField + DropdownField
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/modals.dart'; // CustomPopup
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/config/env.dart';

class InventoryFormSteps {
  static const basic = 'Basic Information';
  static const item  = 'Item Details';

  static bool isValid(String s) => s == basic || s == item;
}

class InventoryForm extends StatefulWidget {
  final String requestType;
  const InventoryForm({super.key, required this.requestType});

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  final int _selectedIndex = 4;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];
    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // API Service
  late final APIService _apiService;
  
  // Inventory items from API
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _isLoadingItems = true;
  bool _isSubmitting = false;
  String? _selectedInventoryId;
  String? _buildingId;
  String? _userId;

  // Basic Info controllers
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController dateRequestedController = TextEditingController();
  final TextEditingController neededByController = TextEditingController();

  // Item Details controllers
  final TextEditingController requestQuantityController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final TextEditingController _classificationOtherCtrl = TextEditingController();

  bool _submitted = false;

  // ---- Error helpers
  String? _errBasic(String key) {
    switch (key) {
      case 'name':
        return itemNameController.text.trim().isEmpty ? 'Item name is required' : null;
      case 'code':
        return itemCodeController.text.trim().isEmpty ? 'Item code is required' : null;
      case 'dateRequested':
        return dateRequestedController.text.trim().isEmpty ? 'Date requested is required' : null;
      case 'neededBy':
        return neededByController.text.trim().isEmpty ? 'Needed by is required' : null;
      default:
        return null;
    }
  }

  String? _errItem(String key) {
    switch (key) {
      case 'quantity': {
        final raw = requestQuantityController.text.trim();
        if (raw.isEmpty) return 'Request quantity is required';
        final n = int.tryParse(raw);
        if (n == null) return 'Numbers only';
        if (n <= 0) return 'Must be greater than 0';
        return null;
      }
      case 'unit':
        return unitController.text.trim().isEmpty ? 'Unit is required' : null;
      default:
        return null;
    }
  }

  // ---- Actions
  void _onPrimaryPressed() {
    setState(() => _submitted = true);

    final formOk = _formKey.currentState?.validate() ?? false;

    final hasErrors =
        _selectedInventoryId == null ||
        _errBasic('name')          != null ||
        _errBasic('code')          != null ||
        _errBasic('dateRequested') != null ||
        _errBasic('neededBy')      != null ||
        _errItem('quantity')       != null ||
        _errItem('unit')           != null;

    if (!formOk || hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedInventoryId == null
              ? 'Please select an inventory item'
              : 'Please complete all required fields before submitting.'
          ),
        ),
      );
      return;
    }

    // Submit the request to API
    _submitInventoryRequest();
  }

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Success',
        message: 'Your request has been submitted successfully and is now listed under Inventory Requests.',
        primaryText: 'Go to Inventory',
        onPrimaryPressed: () {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const InventoryPage()),
          );
        },
      ),
    );
  }

  // ---- Bottom bar
  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: _isSubmitting
              ? ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005CE7),
                    disabledBackgroundColor: const Color(0xFF005CE7).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Submitting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : FilledButton(
                  label: 'Submit Request',
                  backgroundColor: const Color(0xFF005CE7),
                  textColor: Colors.white,
                  withOuterBorder: false,
                  onPressed: _onPrimaryPressed,
                ),
        ),
      ),
    );
  }

  // ---- Lifecycle
  void _attachFieldListeners() {
    for (final c in [
      itemNameController,
      itemCodeController,
      dateRequestedController,
      neededByController,
      requestQuantityController,
      unitController,
      notesController,
      _classificationOtherCtrl,
    ]) {
      c.addListener(_onAnyFieldChanged);
    }
  }

  void _detachFieldListeners() {
    for (final c in [
      itemNameController,
      itemCodeController,
      dateRequestedController,
      neededByController,
      requestQuantityController,
      unitController,
      notesController,
      _classificationOtherCtrl,
    ]) {
      c.removeListener(_onAnyFieldChanged);
    }
  }

  void _onAnyFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickNeededByDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      neededByController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _apiService = APIService(roleOverride: AppRole.staff);

    final now = DateTime.now();

    dateRequestedController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    itemCodeController.text =
        "INV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}";

    _attachFieldListeners();
    _loadUserDataAndInventory();
  }

  Future<void> _loadUserDataAndInventory() async {
    try {
      final profile = await AuthStorage.getProfile();
      _buildingId = profile?['building_id']?.toString() ?? 'default_building';
      // Try both uid and user_id fields
      _userId = profile?['uid']?.toString() ?? profile?['user_id']?.toString() ?? '';

      print('DEBUG: Loaded user data - buildingId: $_buildingId, userId: $_userId');

      // Fetch inventory items
      final response = await _apiService.getInventoryItems(

      );

      if (mounted) {
        setState(() {
          if (response['success'] == true && response['data'] is List) {
            _inventoryItems = List<Map<String, dynamic>>.from(response['data']);
          }
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      print('Error loading inventory items: $e');
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading inventory items: $e')),
        );
      }
    }
  }

  Future<void> _submitInventoryRequest() async {
    if (_isSubmitting) return; // Prevent double submission

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_selectedInventoryId == null) {
        throw Exception('Please select an inventory item');
      }

      if (_buildingId == null || _buildingId!.isEmpty) {
        throw Exception('Building ID not available. Please try logging out and logging back in.');
      }

      if (_userId == null || _userId!.isEmpty) {
        throw Exception('User ID not available. Please try logging out and logging back in.');
      }

      final quantityText = requestQuantityController.text.trim();
      if (quantityText.isEmpty) {
        throw Exception('Please enter a quantity');
      }

      final quantity = int.tryParse(quantityText);
      if (quantity == null || quantity <= 0) {
        throw Exception('Please enter a valid quantity');
      }

      print('DEBUG: Creating inventory request with:');
      print('  - Inventory ID: $_selectedInventoryId');
      print('  - Building ID: $_buildingId');
      print('  - Quantity: $quantity');
      print('  - Requested By: $_userId');

      final response = await _apiService.createInventoryRequest(
        inventoryId: _selectedInventoryId!,
        buildingId: _buildingId!,
        quantityRequested: quantity,
        purpose: notesController.text.trim().isEmpty
            ? 'Staff inventory request'
            : notesController.text.trim(),
        requestedBy: _userId!,
      );

      print('DEBUG: Response from createInventoryRequest: $response');

      if (response['success'] == true) {
        if (mounted) {
          _showRequestDialog(context);
        }
      } else {
        throw Exception(response['message'] ?? response['detail'] ?? 'Failed to create request');
      }
    } catch (e) {
      print('ERROR: Error submitting inventory request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _detachFieldListeners();
    itemNameController.dispose();
    itemCodeController.dispose();
    dateRequestedController.dispose();
    neededByController.dispose();
    requestQuantityController.dispose();
    unitController.dispose();
    notesController.dispose();
    _classificationOtherCtrl.dispose();
    super.dispose();
  }

  // ---- Form fields - single page
  List<Widget> _getFormFields() {
    return [
      const Text('Request Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 16),

      // Inventory Item Selector
      if (_isLoadingItems)
        const Center(child: CircularProgressIndicator())
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Inventory Item *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF344054),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedInventoryId,
              decoration: InputDecoration(
                hintText: 'Choose an item from inventory',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _inventoryItems.map((item) {
                final id = item['id']?.toString() ?? item['_doc_id']?.toString() ?? '';
                final name = item['item_name']?.toString() ?? 'Unknown';
                final code = item['item_code']?.toString() ?? '';
                final stock = item['current_stock']?.toString() ?? '0';
                final unit = item['unit_of_measure']?.toString() ?? 'pcs';
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text('$name ($code) - Stock: $stock $unit'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInventoryId = value;
                  // Auto-fill item name, code, and unit
                  final selectedItem = _inventoryItems.firstWhere(
                    (item) => (item['id']?.toString() ?? item['_doc_id']?.toString()) == value,
                    orElse: () => {},
                  );
                  if (selectedItem.isNotEmpty) {
                    itemNameController.text = selectedItem['item_name']?.toString() ?? '';
                    itemCodeController.text = selectedItem['item_code']?.toString() ?? '';
                    unitController.text = selectedItem['unit_of_measure']?.toString() ?? 'pcs';
                  }
                });
              },
              validator: (value) {
                if (_submitted && (value == null || value.isEmpty)) {
                  return 'Please select an inventory item';
                }
                return null;
              },
            ),
          ],
        ),
      const SizedBox(height: 12),

      InputField(
        label: 'Item Name',
        controller: itemNameController,
        readOnly: true,
        isRequired: true,
        errorText: _submitted ? _errBasic('name') : null,
      ),
      const SizedBox(height: 12),
      InputField(
        label: 'Item Code',
        controller: itemCodeController,
        readOnly: true,
        isRequired: true,
        errorText: _submitted ? _errBasic('code') : null,
      ),
      const SizedBox(height: 12),
      InputField(
        label: 'Date Requested',
        controller: dateRequestedController,
        readOnly: true,
        isRequired: true,
        errorText: _submitted ? _errBasic('dateRequested') : null,
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _pickNeededByDate,
        child: AbsorbPointer(
          child: InputField(
            label: 'Needed By',
            controller: neededByController,
            hintText: 'Pick date',
            isRequired: true,
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
            errorText: _submitted ? _errBasic('neededBy') : null,
          ),
        ),
      ),

      const SizedBox(height: 24),
      const Text('Request Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 12),

      // Request Quantity
      InputField(
        label: 'Request Quantity',
        controller: requestQuantityController,
        keyboardType: TextInputType.number,
        hintText: 'Enter quantity (e.g. 10)',
        isRequired: true,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(9),
        ],
        errorText: _submitted ? _errItem('quantity') : null,
      ),
      const SizedBox(height: 12),

      // Unit
      DropdownField<String>(
        label: 'Unit',
        value: unitController.text.isEmpty ? null : unitController.text,
        items: const ['pcs', 'box', 'set', 'pack', 'roll', 'litre', 'kg', 'gal'],
        onChanged: (v) {
          setState(() => unitController.text = v ?? '');
          _formKey.currentState?.validate();
        },
        isRequired: true,
        requiredMessage: 'Unit is required.',
        hintText: 'Select unit of measurement',
      ),
      const SizedBox(height: 12),

      // Notes
      InputField(
        label: 'Notes (optional)',
        controller: notesController,
        hintText: 'Add remarks, special instructions, or purpose',
        maxLines: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final autovalidate = _submitted
        ? AutovalidateMode.always
        : AutovalidateMode.disabled;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Request Inventory Item',
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: autovalidate,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _getFormFields(),
                  ),
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
