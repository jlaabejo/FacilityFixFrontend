import 'package:facilityfix/admin/announcement.dart';
import 'package:facilityfix/admin/calendar.dart';
import 'package:facilityfix/admin/home.dart';
import 'package:facilityfix/admin/inventory.dart';
import 'package:facilityfix/admin/workorder.dart';
import 'package:facilityfix/widgets/buttons.dart';
import 'package:facilityfix/widgets/forms.dart' hide DropdownField;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart' hide FilledButton;
import 'package:facilityfix/widgets/app&nav_bar.dart';

class AnnouncementForm extends StatefulWidget {
  final String requestType;

  const AnnouncementForm({
    super.key,
    required this.requestType,
  });

  @override
  State<AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<AnnouncementForm> {
  int _selectedIndex = 2;

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

  Future<void> _pickDateTime(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final formattedDate =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
        final formattedTime = pickedTime.format(context);
        controller.text = "$formattedDate $formattedTime";
      }
    }
  }

  // Controllers
  final TextEditingController audienceController = TextEditingController();
  final TextEditingController noticeTypeController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController scheduleVisibilityController = TextEditingController();
  final TextEditingController schedulePostingController = TextEditingController();

  // Holds multiple selected files
  List<PlatformFile> selectedFiles = [];
  bool pinToDashboard = false;

  /// File picker with multi-selection and delete capability
  Widget _filePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: () async {
          final result = await FilePicker.platform.pickFiles(allowMultiple: true);
          if (result != null) {
            setState(() {
              selectedFiles = result.files;
            });
          }
        },
        icon: const Icon(Icons.attach_file),
        label: const Text('Choose Files'),
      ),

      // List each selected file with a delete button
      if (selectedFiles.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < selectedFiles.length; i++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedFiles[i].name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () {
                        setState(() => selectedFiles.removeAt(i));
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
    ]);
  }

  List<Widget> getFormFields() {
    return [
      const Text('New Announcement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),

      DropdownField<String>(
        label: 'Audience',
        value: audienceController.text.isEmpty ? null : audienceController.text,
        items: ['Tenant', 'Staff', 'All'],
        onChanged: (value) {
          setState(() => audienceController.text = value ?? '');
        },
        isRequired: true,
      ),

      DropdownField<String>(
        label: 'Notice Type',
        value: noticeTypeController.text.isEmpty ? null : noticeTypeController.text,
        items: [
          'Scheduled Maintenance',
          'Utility Interruption',
          'Safety Inspection',
          'Facility Works',
          'General Announcement',
          'Pest Control',
          'Power Outage'
        ],
        onChanged: (value) {
          setState(() => noticeTypeController.text = value ?? '');
        },
        isRequired: true,
      ),

      InputField(
        label: 'Description / Message Body',
        controller: descriptionController,
        hintText: 'Enter announcement details',
        isRequired: true,
        maxLines: 4,
      ),

      InputField(
        label: 'Location (Affected Area)',
        controller: locationController,
        hintText: 'Enter location',
        isRequired: true,
      ),

      GestureDetector(
        onTap: () => _pickDateTime(scheduleVisibilityController),
        child: AbsorbPointer(
          child: InputField(
            label: 'Schedule Visibility',
            controller: scheduleVisibilityController,
            hintText: 'Select date & time',
            isRequired: true,
          ),
        ),
      ),

      GestureDetector(
        onTap: () => _pickDateTime(schedulePostingController),
        child: AbsorbPointer(
          child: InputField(
            label: 'Schedule Posting',
            controller: schedulePostingController,
            hintText: 'Select date & time',
            isRequired: true,
          ),
        ),
      ),

      _filePicker(),

      SwitchListTile(
        title: const Text('Pin to Dashboard'),
        value: pinToDashboard,
        onChanged: (val) {
          setState(() => pinToDashboard = val);
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: Row(
          children: const [
            BackButton(),
            SizedBox(width: 8),
            Text('New Announcement'),
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
              label: "Submit",
              onPressed: () {
                // Auto-notification logic happens here after submit/post
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement created & audience notified!')),
                );
                Navigator.pop(context);
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
