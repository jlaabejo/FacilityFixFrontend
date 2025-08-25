import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/forms.dart'; // InputField
import 'package:flutter/material.dart' hide FilledButton;
import 'package:facilityfix/widgets/app&nav_bar.dart';

class InventoryForm extends StatefulWidget {
  final String requestType; // 'Inventory From' | 'Stock & Supplier Details'
  const InventoryForm({super.key, required this.requestType});

  @override
  State<InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<InventoryForm> {
  // highlight the Inventory tab (index 4) in the bottom nav
  int _selectedIndex = 4;

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

  // Controllers for inventory fields
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController dateAddedController = TextEditingController();
  final TextEditingController brandNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController reorderLevelController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController warrantyController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();

  // Dropdown values
  String? classificationValue;
  String? tagValue;
  String? unitValue; 

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    dateAddedController.text =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    itemCodeController.text =
        "INV-${now.year}-${now.millisecondsSinceEpoch.toString().substring(7)}";
  }

  /// Builds fields based on which step we're on.
  List<Widget> getFormFields() {
    switch (widget.requestType) {
      // Step 1 – Basic Information
      case 'Inventory From':
        return [
          const Text('Basic Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          InputField(
            label: 'Item Name',
            controller: itemNameController,
            hintText: 'Enter item name',
            isRequired: true,
          ),
          InputField(
            label: 'Item Code',
            controller: itemCodeController,
            hintText: 'Auto-filled',
            readOnly: true,
            isRequired: true,
          ),
          InputField(
            label: 'Date Added',
            controller: dateAddedController,
            hintText: 'Auto-filled',
            readOnly: true,
            isRequired: true,
          ),
          const Text('Classification *', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: classificationValue,
            decoration: const InputDecoration(
              hintText: 'Select classification',
              border: OutlineInputBorder(),
            ),
            items: const [
              'Lighting',
              'Fasteners',
              'Tools',
              'Materials',
              'Consumables',
              'PPE',
              'HVAC',
              'Electrical Fixtures',
              'Plumbing Parts',
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) => setState(() => classificationValue = newValue),
          ),
          const SizedBox(height: 12),
          InputField(
            label: 'Brand Name',
            controller: brandNameController,
            hintText: 'Enter brand name',
            isRequired: false,
          ),
        ];

      // Step 2 – Stock and Supplier Details
      case 'Stock & Supplier Details':
        return [
          const Text('Stock & Supplier Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Stock Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InputField(
            label: 'Quantity In Stock',
            controller: quantityController,
            hintText: 'Enter quantity',
            isRequired: true,
          ),
          InputField(
            label: 'Reorder Level',
            controller: reorderLevelController,
            hintText: 'Enter reorder level',
            isRequired: true,
          ),
          const Text('Unit *', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: unitController.text.isEmpty ? null : unitController.text,
            decoration: const InputDecoration(
              hintText: 'Select unit (e.g., pcs, box)',
              border: OutlineInputBorder(),
            ),
            items: const [
              'pcs', 'box', 'set', 'pack', 'roll', 'litre', 'kg', 'gal'
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() => unitController.text = newValue ?? '');
            },
          ),
          const SizedBox(height: 12),
          const Text('Tag *', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: tagValue,
            decoration: const InputDecoration(
              hintText: 'Select tag',
              border: OutlineInputBorder(),
            ),
            items: const [
              'High-Turnover', 'Critical-Use', 'Repair-Prone'
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) => setState(() => tagValue = newValue),
          ),
          const SizedBox(height: 12),
          const Text('Supplier Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          InputField(
            label: 'Supplier',
            controller: supplierController,
            hintText: 'Enter supplier name',
            isRequired: false,
          ),
          InputField(
            label: 'Contact Number',
            controller: contactNumberController,
            hintText: 'Enter contact number',
            isRequired: false,
          ),
          GestureDetector(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() {
                  warrantyController.text =
                      "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                });
              }
            },
            child: AbsorbPointer(
              child: InputField(
                label: 'Warranty Until',
                controller: warrantyController,
                hintText: 'Select date',
                suffixIcon: const Icon(Icons.calendar_today),
                isRequired: false,
              ),
            ),
          ),
        ];
      // Fallback
      default:
        return [const Text('Invalid request type')];
    }
  }

  @override
  Widget build(BuildContext context) {
    // final step if the type is 'Stock & Supplier Details'
    final bool isFinalStep =
        widget.requestType == 'Stock & Supplier Details';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: Row(
          children: [
            const BackButton(),
            const SizedBox(width: 8),
            Text(isFinalStep ? 'Stock & Supplier Details' : 'Add Inventory Item'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...getFormFields(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            FilledButton(
              label: isFinalStep ? "Submit" : "Next",
              onPressed: () {
                if (isFinalStep) {
                  // Here you would persist to backend if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Inventory item added successfully!')),
                  );
                  Navigator.pop(context);
                } else {
                  // Navigate to the stock/supplier step
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryForm(
                          requestType: 'Stock & Supplier Details'),
                    ),
                  );
                }
              },
            ),
          ],
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
