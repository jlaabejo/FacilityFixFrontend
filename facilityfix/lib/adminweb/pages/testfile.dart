// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import '../layout/facilityfix_layout.dart';

// class InternalTaskViewPage extends StatefulWidget {
//   /// Added: taskId, initialTask, startInEditMode 
//   final String taskId;
//   final Map<String, dynamic>? initialTask;
//   final bool startInEditMode;

//   const InternalTaskViewPage({
//     super.key,
//     required this.taskId,
//     this.initialTask,
//     this.startInEditMode = false,
//   });

//   @override
//   State<InternalTaskViewPage> createState() => _InternalTaskViewPageState();
// }

// class _InternalTaskViewPageState extends State<InternalTaskViewPage> {
//   // -------- Navigation helpers --------
//   String? _getRoutePath(String routeKey) {
//     final Map<String, String> pathMap = {
//       'dashboard': '/dashboard',
//       'user_users': '/user/users',
//       'user_roles': '/user/roles',
//       'work_maintenance': '/work/maintenance',
//       'work_repair': '/work/repair',
//       'calendar': '/calendar',
//       'inventory_items': '/inventory/items',
//       'inventory_request': '/inventory/request',
//       'analytics': '/analytics',
//       'announcement': '/announcement',
//       'settings': '/settings',
//     };
//     return pathMap[routeKey];
//   }

//   // Handle logout functionality
//   void _handleLogout(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Logout'),
//           content: const Text('Are you sure you want to logout?'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 context.go('/'); // Go back to login page
//               },
//               child: const Text('Logout'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // -------- Edit mode + form state --------
//   final _formKey = GlobalKey<FormState>();                  // <-- form key
//   bool _isEditMode = false;                                 // <-- toggler

//   // Controllers for editable fields in "Basic Information"
//   final _departmentCtrl = TextEditingController();
//   final _createdByCtrl = TextEditingController();
//   final _estimatedDurationCtrl = TextEditingController();
//   final _locationCtrl = TextEditingController();
//   final _descriptionCtrl = TextEditingController();

//   // For "Schedule" section
//   final _recurrenceCtrl = TextEditingController();
//   final _startDateCtrl = TextEditingController();
//   final _nextDueCtrl = TextEditingController();

//   // For "Assignment" section
//   final _assigneeNameCtrl = TextEditingController();
//   final _assigneeDeptCtrl = TextEditingController();

//   // Snapshot of original values so Cancel can revert
//   late Map<String, String> _original;

//   // Sample checklist items
//   final List<Map<String, dynamic>> _checklistItems = [
//     {'text': 'Visually inspect light conditions', 'completed': false},
//     {'text': 'Test Switch Function', 'completed': false},
//     {'text': 'Check emergency Lights', 'completed': false},
//     {'text': 'Replace burn-out burns', 'completed': false},
//     {'text': 'Log condition and report anomalies', 'completed': false},
//   ];

//   @override
//   void initState() {
//     super.initState();

//     // ---- Seed initial values from given task or placeholder ----
//     final seed = widget.initialTask ?? {
//       'department': 'General maintenance',
//       'createdBy': 'Michelle Reyes',
//       'estimatedDuration': '3 hrs',
//       'location': 'Basement',
//       'description': 'Inspect ceilings lights and emergency lighting...',
//       'recurrence': 'Every 1 month',
//       'startDate': '2025-07-30',
//       'nextDueDate': '2025-07-08',
//       'assigneeName': 'Ronaldo Cruz',
//       'assigneeDept': 'General maintenance',
//       'taskTitle': 'Light Inspection',
//       'taskCode': widget.taskId, // use URL id
//     };

//     _departmentCtrl.text        = seed['department'];
//     _createdByCtrl.text         = seed['createdBy'];
//     _estimatedDurationCtrl.text = seed['estimatedDuration'];
//     _locationCtrl.text          = seed['location'];
//     _descriptionCtrl.text       = seed['description'];
//     _recurrenceCtrl.text        = seed['recurrence'];
//     _startDateCtrl.text         = seed['startDate'];
//     _nextDueCtrl.text           = seed['nextDueDate'];
//     _assigneeNameCtrl.text      = seed['assigneeName'];
//     _assigneeDeptCtrl.text      = seed['assigneeDept'];

//     _original = _takeSnapshot();                     // <-- remember original
//     _isEditMode = widget.startInEditMode;            // <-- auto enter edit
//   }

//   @override
//   void dispose() {
//     // Always dispose controllers
//     _departmentCtrl.dispose();
//     _createdByCtrl.dispose();
//     _estimatedDurationCtrl.dispose();
//     _locationCtrl.dispose();
//     _descriptionCtrl.dispose();
//     _recurrenceCtrl.dispose();
//     _startDateCtrl.dispose();
//     _nextDueCtrl.dispose();
//     _assigneeNameCtrl.dispose();
//     _assigneeDeptCtrl.dispose();
//     super.dispose();
//   }

//   // -------- Utility: snapshot current controller values --------
//   Map<String, String> _takeSnapshot() => {
//     'department': _departmentCtrl.text,
//     'createdBy': _createdByCtrl.text,
//     'estimatedDuration': _estimatedDurationCtrl.text,
//     'location': _locationCtrl.text,
//     'description': _descriptionCtrl.text,
//     'recurrence': _recurrenceCtrl.text,
//     'startDate': _startDateCtrl.text,
//     'nextDueDate': _nextDueCtrl.text,
//     'assigneeName': _assigneeNameCtrl.text,
//     'assigneeDept': _assigneeDeptCtrl.text,
//   };

//   // -------- Handlers for edit toolbar --------
//   void _enterEditMode() {
//     setState(() => _isEditMode = true);
//   }

//   void _cancelEdit() {
//     // revert to original values
//     _departmentCtrl.text        = _original['department']!;
//     _createdByCtrl.text         = _original['createdBy']!;
//     _estimatedDurationCtrl.text = _original['estimatedDuration']!;
//     _locationCtrl.text          = _original['location']!;
//     _descriptionCtrl.text       = _original['description']!;
//     _recurrenceCtrl.text        = _original['recurrence']!;
//     _startDateCtrl.text         = _original['startDate']!;
//     _nextDueCtrl.text           = _original['nextDueDate']!;
//     _assigneeNameCtrl.text      = _original['assigneeName']!;
//     _assigneeDeptCtrl.text      = _original['assigneeDept']!;

//     setState(() => _isEditMode = false);
//   }

//   Future<void> _saveEdit() async {
//     if (!_formKey.currentState!.validate()) {
//       // If any field invalid, show a subtle nudge
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fix validation errors.')),
//       );
//       return;
//     }

//     // TODO: call your backend to persist changes
//     // final payload = _takeSnapshot(); await api.updateInternalTask(widget.taskId, payload);

//     // Update snapshot so Cancel after save won’t revert
//     _original = _takeSnapshot();

//     setState(() => _isEditMode = false);
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Task saved.'), backgroundColor: Colors.green),
//     );
//   }

//   // -------- Validation helpers --------
//   String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

//   String? _durationValidator(String? v) {
//     if (v == null || v.trim().isEmpty) return 'Required';
//     // very simple: "3 hrs", "45 min" etc.
//     final ok = RegExp(r'^\d+\s*(hr|hrs|hour|hours|min|mins|minutes)$', caseSensitive: false).hasMatch(v.trim());
//     return ok ? null : 'Use formats like "3 hrs" or "45 mins"';
//   }

//   String? _dateValidator(String? v) {
//     if (v == null || v.trim().isEmpty) return 'Required';
//     // Expecting YYYY-MM-DD
//     final ok = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim());
//     return ok ? null : 'Use YYYY-MM-DD';
//   }

//   // ---------------------------- UI ----------------------------
//   @override
//   Widget build(BuildContext context) {
//     return FacilityFixLayout(
//       currentRoute: 'work_maintenance',
//       onNavigate: (routeKey) {
//         final routePath = _getRoutePath(routeKey);
//         if (routePath != null) {
//           context.go(routePath);
//         } else if (routeKey == 'logout') {
//           _handleLogout(context);
//         }
//       },
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Form( // <-- Wrap page in a Form for validation
//           key: _formKey,
//           autovalidateMode: AutovalidateMode.onUserInteraction, // realtime
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildHeaderSection(),          // (same as yours)
//               const SizedBox(height: 32),
//               Container(
//                 decoration: BoxDecoration(
//                   color: Colors.white, borderRadius: BorderRadius.circular(12),
//                   boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
//                 ),
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Task header + Edit toolbar
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         // Left: task title / code / assignee (read-only display)
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text("Light Inspection", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
//                             const SizedBox(height: 4),
//                             Text(widget.taskId, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//                             const SizedBox(height: 4),
//                             Text("Assigned To: ${_assigneeNameCtrl.text}", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
//                           ],
//                         ),
//                         _buildEditToolbar(), // Edit / Cancel / Save buttons
//                       ],
//                     ),
//                     const SizedBox(height: 32),

//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: Column(
//                             children: [
//                               _buildBasicInformationCard(), // <-- turns editable
//                               const SizedBox(height: 24),
//                               _buildChecklistCard(),        // (left as view-only)
//                               const SizedBox(height: 24),
//                               _buildAdminNotesCard(),       // (view-only)
//                             ],
//                           ),
//                         ),
//                         const SizedBox(width: 24),
//                         Expanded(
//                           flex: 1,
//                           child: Column(
//                             children: [
//                               _buildScheduleCard(),         // <-- turns editable
//                               const SizedBox(height: 24),
//                               _buildAssignmentCard(),       // <-- turns editable
//                               const SizedBox(height: 24),
//                               _buildAttachmentsCard(),      // (view-only)
//                               const SizedBox(height: 24),
//                               // Keep the single button for users who land in view
//                               if (!_isEditMode) _buildEditButton(), 
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Small toolbar that appears in the header area.
//   Widget _buildEditToolbar() {
//     if (!_isEditMode) {
//       return ElevatedButton.icon(
//         onPressed: _enterEditMode,
//         icon: const Icon(Icons.edit, size: 18),
//         label: const Text('Edit'),
//         style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
//       );
//     }
//     return Row(
//       children: [
//         OutlinedButton(
//           onPressed: _cancelEdit,
//           child: const Text('Cancel'),
//         ),
//         const SizedBox(width: 8),
//         ElevatedButton.icon(
//           onPressed: _saveEdit,
//           icon: const Icon(Icons.save_outlined, size: 18),
//           label: const Text('Save'),
//           style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
//         ),
//       ],
//     );
//   }

//   // ----- Basic Information card becomes editable in edit mode -----
//   Widget _buildBasicInformationCard() {
//     return _card(
//       icon: Icons.info,
//       iconBg: const Color(0xFF1976D2),
//       title: 'Basic Information',
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _editableRow('Department', _departmentCtrl, validator: _req),
//           _editableRow('Created By', _createdByCtrl, validator: _req),
//           _editableRow('Estimated Duration', _estimatedDurationCtrl, validator: _durationValidator, hint: 'e.g., 3 hrs, 45 mins'),
//           _editableRow('Location / Area', _locationCtrl, validator: _req),
//           const SizedBox(height: 16),
//           Text('Task Description', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
//           const SizedBox(height: 8),
//           _isEditMode
//               ? TextFormField(
//                   controller: _descriptionCtrl,
//                   minLines: 3,
//                   maxLines: 6,
//                   validator: _req,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(), isDense: true, hintText: 'Describe the work to be done...',
//                   ),
//                 )
//               : Text(_descriptionCtrl.text, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
//         ],
//       ),
//     );
//   }

//   // ----- Schedule card becomes editable in edit mode -----
//   Widget _buildScheduleCard() {
//     return _card(
//       icon: Icons.calendar_today,
//       iconBg: const Color(0xFFE8F5E8),
//       title: 'Schedule',
//       child: Column(
//         children: [
//           _editableRow('Recurrence', _recurrenceCtrl, validator: _req, hint: 'e.g., Every 1 month'),
//           _editableRow('Start Date', _startDateCtrl, validator: _dateValidator, hint: 'YYYY-MM-DD'),
//           _editableRow('Next Due Date', _nextDueCtrl, validator: _dateValidator, hint: 'YYYY-MM-DD', highlight: true),
//         ],
//       ),
//     );
//   }

//   // ----- Assignment card becomes editable in edit mode -----
//   Widget _buildAssignmentCard() {
//     return _card(
//       icon: Icons.person,
//       iconBg: Colors.grey[200]!,
//       title: 'Assignment',
//       child: Row(
//         children: [
//           // Avatar
//           Container(
//             width: 40, height: 40, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle),
//             child: Icon(Icons.person_outline, color: Colors.grey[600], size: 20),
//           ),
//           const SizedBox(width: 12),
//           // Assignee fields
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _editableRow('Assignee Name', _assigneeNameCtrl, validator: _req, compact: true),
//                 _editableRow('Department', _assigneeDeptCtrl, validator: _req, compact: true),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ----- View-only cards below (unchanged) -----
//    Widget _buildChecklistCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Card header with icon and title
//           Row(
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFF3E0),
//                   shape: BoxShape.circle,
//                   border: Border.all(color: const Color(0xFFFF9800)),
//                 ),
//                 child: const Icon(
//                   Icons.checklist,
//                   color: Color(0xFFFF9800),
//                   size: 16,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 "Checklist / Task Steps",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),

//           // Checklist items
//           ...(_checklistItems.asMap().entries.map((entry) {
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 16),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 20,
//                     height: 20,
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey[400]!, width: 2),
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                     child: entry.value['completed']
//                         ? const Icon(
//                             Icons.check,
//                             size: 14,
//                             color: Colors.green,
//                           )
//                         : null,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       entry.value['text'],
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: entry.value['completed']
//                             ? Colors.grey[500]
//                             : Colors.black87,
//                         decoration: entry.value['completed']
//                             ? TextDecoration.lineThrough
//                             : null,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           })),
//         ],
//       ),
//     );
//   }
//   Widget _buildAdminNotesCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Card header with icon and title
//           Row(
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFE8F5E8),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.comment,
//                   color: Color(0xFF2E7D2E),
//                   size: 16,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 "Admin Notes",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),

//           // Warning note
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: const Color(0xFFE3F2FD),
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: const Color(0xFF1976D2), width: 1),
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Icon(
//                   Icons.warning,
//                   color: Color(0xFF1976D2),
//                   size: 20,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     "Emergency lights in basement often have moisture issues - check battery backups.",
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.blue[800],
//                       height: 1.4,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _buildAttachmentsCard() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Card header with icon and title
//           Row(
//             children: [
//               Container(
//                 width: 32,
//                 height: 32,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFE3F2FD),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.attach_file,
//                   color: Color(0xFF1976D2),
//                   size: 16,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Text(
//                 "Attachments",
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),

//           // Attachment item
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.grey[200]!),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 32,
//                   height: 32,
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF4CAF50),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: const Icon(
//                     Icons.image,
//                     color: Colors.white,
//                     size: 16,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "basement-lights-before.jpg",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       Text(
//                         "Image File",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Icon(
//                   Icons.visibility,
//                   color: Colors.grey[600],
//                   size: 20,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   Widget _buildHeaderSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           "Work Orders",
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             Text(
//               "Main",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//             Icon(
//               Icons.arrow_forward_ios,
//               size: 12,
//               color: Colors.grey[600],
//             ),
//             const SizedBox(width: 4),
//             Text(
//               "Work Orders",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//             ),
//             Icon(
//               Icons.arrow_forward_ios,
//               size: 12,
//               color: Colors.grey[600],
//             ),
//             const SizedBox(width: 4),
//             const Text(
//               "Maintenance Tasks",
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.black87,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//   Widget _buildEditButton() => SizedBox(
//     width: double.infinity,
//     height: 48,
//     child: ElevatedButton.icon(
//       onPressed: _enterEditMode,
//       icon: const Icon(Icons.edit, size: 18),
//       label: const Text("Edit Task"),
//       style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
//     ),
//   );

//   // ----- Small card wrapper to keep your style consistent -----
//   Widget _card({required IconData icon, required Color iconBg, required String title, required Widget child}) {
//     return Container(
//       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
//       padding: const EdgeInsets.all(24),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Row(children: [
//           Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
//             child: Icon(icon, color: iconBg.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 16)),
//           const SizedBox(width: 12),
//           Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
//         ]),
//         const SizedBox(height: 20),
//         child,
//       ]),
//     );
//   }

//   // ----- Core: a row that is read-only in view mode, TextFormField in edit mode -----
//   Widget _editableRow(
//     String label,
//     TextEditingController controller, {
//     String? Function(String?)? validator,
//     String? hint,
//     bool highlight = false,
//     bool compact = false,
//   }) {
//     final labelStyle = TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500);
//     final valueStyle = TextStyle(
//       fontSize: 14,
//       color: highlight ? Colors.red[600] : Colors.black87,
//       fontWeight: FontWeight.w500,
//     );

//     return Padding(
//       padding: EdgeInsets.only(bottom: compact ? 8 : 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(width: 160, child: Text(label, style: labelStyle)),
//           Expanded(
//             child: _isEditMode
//                 ? TextFormField(
//                     controller: controller,
//                     validator: validator,
//                     onChanged: (_) => setState(() {}), // realtime rebuilds if needed
//                     decoration: InputDecoration(
//                       isDense: true,
//                       hintText: hint,
//                       border: const OutlineInputBorder(),
//                       // Visual cue when invalid
//                       errorMaxLines: 2,
//                     ),
//                   )
//                 : Text(controller.text, style: valueStyle),
//           ),
//         ],
//       ),
//     );
//   }
// }
