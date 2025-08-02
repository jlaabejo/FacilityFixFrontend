import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// Input Field 
class CustomInputField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isRequired;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap; // Optional onTap

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.readOnly = false, // default value
    this.onTap,            // optional
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label *' : label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap, 
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
            ),
            validator: isRequired
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '$label is required';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

// Attachment
class FileAttachmentPicker extends StatefulWidget {
  final String label;
  final bool isRequired;
  final void Function(List<PlatformFile>)? onChanged;

  const FileAttachmentPicker({
    super.key,
    required this.label,
    this.isRequired = false,
    this.onChanged,
  });

  @override
  State<FileAttachmentPicker> createState() => _FileAttachmentPickerState();
}

class _FileAttachmentPickerState extends State<FileAttachmentPicker> {
  List<PlatformFile> _selectedFiles = [];

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'pdf', 'doc'],
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(result.files);
      });

      widget.onChanged?.call(_selectedFiles);
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });

    widget.onChanged?.call(_selectedFiles);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isRequired ? '${widget.label} *' : widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickFiles,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.attach_file, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Select files',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedFiles.asMap().entries.map((entry) {
              final index = entry.key;
              final file = entry.value;
              return Chip(
                label: Text(file.name),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () => _removeFile(index),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Multiple Name
class MultiContractorInputField extends StatefulWidget {
  final String label;
  final bool isRequired;
  final void Function(List<Map<String, String>>) onChanged;

  const MultiContractorInputField({
    super.key,
    required this.label,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  State<MultiContractorInputField> createState() => _MultiContractorInputFieldState();
}

class _MultiContractorInputFieldState extends State<MultiContractorInputField> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final List<Map<String, String>> _contractors = [];

  void _addContractor() {
    final name = _nameController.text.trim();
    final contact = _contactController.text.trim();

    if (name.isEmpty || contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both name and contact number are required.')),
      );
      return;
    }

    setState(() {
      _contractors.add({'name': name, 'contact': contact});
      _nameController.clear();
      _contactController.clear();
    });

    widget.onChanged(_contractors);
  }

  void _removeContractor(int index) {
    setState(() {
      _contractors.removeAt(index);
    });

    widget.onChanged(_contractors);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            widget.isRequired ? '${widget.label} *' : widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Contractor Name Field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter contractor name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),

          // Contact Number Field
          TextFormField(
            controller: _contactController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter contact number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),

          // Add Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _addContractor,
              icon: const Icon(Icons.add),
              label: const Text("Add"),
            ),
          ),
          const SizedBox(height: 12),

          // Display added contractors
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _contractors.asMap().entries.map((entry) {
              final index = entry.key;
              final contractor = entry.value;
              return Chip(
                label: Text('${contractor['name']} - ${contractor['contact']}'),
                deleteIcon: const Icon(Icons.close),
                onDeleted: () => _removeContractor(index),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
