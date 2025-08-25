import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:facilityfix/widgets/forms.dart';
import 'package:facilityfix/widgets/pop_up.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

class RequestForm extends StatefulWidget {
  final String requestType; // "Concern Slip", "Job Service Request", "Work Order Permit"

  const RequestForm({
    super.key,
    required this.requestType,
  });

  @override
  State<RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends State<RequestForm> {
  int _selectedIndex = 1;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const ProfilePage(),
    ];

    if (index != 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (pickedDate != null) {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      final formattedTime = pickedTime.format(context);

      availabilityController.text = "$formattedDate at $formattedTime";
    }
  }
}

  // Controllers
  final TextEditingController dateRequestedController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController availabilityController = TextEditingController();
  final List<String> contractors = [];


  PlatformFile? selectedFile;

  void _showRequestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => CustomPopup(
        title: 'Success',
        message: 'Your ${widget.requestType.toLowerCase()} has been submitted successfully.',
        primaryText: 'Ok',
        onPrimaryPressed: () => Navigator.of(context).pop(), 
      ),
    );
  }

  List<Widget> getFormFields() {
    switch (widget.requestType) {

      case 'Concern Slip':
        return [
          const Text('Detail Information', style: TextStyle(fontSize: 20)),
          const Text('Enter Detail Information', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputField(
                label: 'Date Requested',
                controller: dateRequestedController,
                hintText: 'Auto-filled',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Building & Unit No.',
                controller: unitController,
                hintText: 'Auto-filled',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Name',
                controller: nameController,
                hintText: 'Auto-filled',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Description',
                controller: descriptionController,
                hintText: 'Enter task description',
                isRequired: true,
              ),
              const SizedBox(height: 8),
              FileAttachmentPicker(label: 'Upload Attachment'),
              const SizedBox(height: 8),
              InputField(
                label: 'Availability',
                controller: availabilityController,
                hintText: 'Select preferred date & time',
                isRequired: true,
                readOnly: true,
                onTap: () => _selectDateTime(context),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.access_time),
                ),
              ),
            ],
          ),
        ];

      case 'Job Service Request':
        return [
          const Text('Detail Information', style: TextStyle(fontSize: 20)),
          const Text('Enter Detail Information', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputField(
                label: 'Date Requested',
                controller: dateRequestedController,
                hintText: 'Select date',
                isRequired: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Building & Unit No.',
                controller: unitController,
                hintText: 'Enter Building & Unit No.',
                isRequired: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Name',
                controller: nameController,
                hintText: 'Enter your name',
                isRequired: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Task Title',
                controller: titleController,
                hintText: 'Enter Task Title',
                isRequired: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Description',
                controller: descriptionController,
                hintText: 'Enter task description',
                isRequired: true,
              ),
              const SizedBox(height: 8),
              FileAttachmentPicker(label: 'Upload Attachment'),
              const SizedBox(height: 8),
              InputField(
                label: 'Availability',
                controller: availabilityController,
                hintText: 'Select preferred date & time',
                isRequired: true,
                readOnly: true,
                onTap: () => _selectDateTime(context),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.access_time),
                ),
              ),
            ],
          ),
        ];

      case 'Work Order Permit':
        return [
          const Text('Permit Validation', style: TextStyle(fontSize: 20)),
          const Text('Enter Detail Information', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InputField(
                label: 'Date Requested',
                controller: dateRequestedController,
                hintText: 'Auto-filled',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.date_range),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Building & Unit No.',
                controller: unitController,
                hintText: 'Auto-filled',
                isRequired: true,
                readOnly: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.apartment),
                ),
              ),
              const SizedBox(height: 8),
              InputField(
                label: 'Availability',
                controller: availabilityController,
                hintText: 'Select preferred date & time',
                isRequired: true,
                readOnly: true,
                onTap: () => _selectDateTime(context),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 8),
              const Text('List of Contractors/Personnel', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              MultiContractorInputField(
                label: 'Contractors',
                isRequired: true,
                onChanged: (contractorList) {
                  // handle
                },
              ),
            ],
          ),
        ];

      default:
        return [const Text('Invalid request type.')];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'New ${widget.requestType}',
        leading: const BackButton(),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...getFormFields(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // Create Task Button
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Button stays fixed above the navbar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: SizedBox(
              width: double.infinity,
              child: fx.FilledButton(
                label: "Create Task",
                onPressed: () => _showRequestDialog(context),
              ),
            ),
          ),
          // NavBar stays at the very bottom
          NavBar(
            items: _navItems,
            currentIndex: _selectedIndex,
            onTap: _onTabTapped,
          ),
        ],
      ),
    );
  }
}
