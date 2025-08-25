import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/tag.dart'; // StatusTag, PriorityTag
import 'package:facilityfix/widgets/buttons.dart' as fx;
class RepairDetailsScreen extends StatelessWidget {
  // ----- Required -----
  final String title;
  final String requestId;
  final String date;
  final String requestType;      // "Repair" | "Concern Slip" | "Assessed Concern Slip" | "Job Service" | "Work Order Permit"
  final String unit;
  final String description;      // main description / note
  final String priority;
  final List<String> attachments;

  // ----- Optional: status / tags -----
  final String? statusTag;

  // ----- Optional: Tenant / Requester -----
  final String? requestedBy;
  final String? department;
  /// Example: tenant availability or target date; you can reuse for schedule
  final String? scheduleAvailability;

  // ----- Optional: assessed by (staff who assessed) -----
  final String? assigneeName;     // assessed by name
  final String? assigneeRole;     // assessed by role
  final String? assessment;
  final String? recommendation;
  final String? dateAssessed;
  final String? assigneeTitle;    // custom title for the assessed section

  // ----- Optional: assigned to (the actual assignment after conversion) -----
  final String? assignedTo;
  final String? assignedRole;
  final String? assignedSchedule; // if you want a separate schedule for the assignment; fallback to scheduleAvailability

  // ----- Optional: Job Service specialization -----
  final String? notes;

  // ----- Optional: Work Order Permit specialization -----
  final String? accountType;
  final String? permitId;
  final String? issueDate;
  final String? expirationDate;
  final String? instructions;

  final String? contractorName;
  final String? contractorCompany;
  final String? contractorPhone;

  // ----- Optional CTA -----
  final String? actionLabel;
  final VoidCallback? onAction;

  const RepairDetailsScreen({
    super.key,
    // required
    required this.title,
    required this.requestId,
    required this.date,
    required this.requestType,
    required this.unit,
    required this.description,
    required this.priority,
    required this.attachments,
    // optional status
    this.statusTag,
    // optional requester
    this.requestedBy,
    this.department,
    this.scheduleAvailability,
    // optional assessed by
    this.assigneeName,
    this.assigneeRole,
    this.assessment,
    this.recommendation,
    this.dateAssessed,
    this.assigneeTitle,
    // optional assigned to
    this.assignedTo,
    this.assignedRole,
    this.assignedSchedule,

    // optional job service
    this.notes,
    // optional permit
    this.accountType,
    this.permitId,
    this.issueDate,
    this.expirationDate,
    this.instructions,

    this.contractorName,
    this.contractorCompany,
    this.contractorPhone,

    // CTA
    this.actionLabel,
    this.onAction,
  });

  bool get _isJobService => _n(requestType) == 'job service';
  bool get _isPermit     => _n(requestType) == 'work order permit';

  static String _n(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'[_\-]+'), ' ').replaceAll(RegExp(r'\s+'), ' ');

  @override
  Widget build(BuildContext context) {
    final hasAssessmentBits = (assessment?.isNotEmpty ?? false) || (dateAssessed?.isNotEmpty ?? false);
    final assigneeSectionTitle = assigneeTitle ?? (hasAssessmentBits ? 'Assessed by' : 'Assessed by');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= Header (Title + Status) =================
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if ((statusTag ?? '').isNotEmpty) StatusTag(status: statusTag!),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            requestId,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF475467),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),

          // ===== Basic info rows =====
          _infoRow('Submitted On', date),
          const SizedBox(height: 8),
          _infoRow('Request Type', requestType),

          // ------------------ Divider ------------------
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 12),

          // ========== Tenant / Requester Details ==========
          _sectionTitle('Tenant / Requester Details'),
          const SizedBox(height: 8),
          if ((requestedBy ?? '').isNotEmpty) ...[
            _infoRow('Requested By', requestedBy!),
            const SizedBox(height: 8),
          ],
          _infoRow('Unit', unit),
          if ((department ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow('Department', department!),
          ],
          if ((scheduleAvailability ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow('Schedule Availability', scheduleAvailability!),
          ],
          if ((dateAssessed ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow('Date Assessed', dateAssessed!),
          ],

          // ------------------ Divider ------------------
          const SizedBox(height: 16),
          _divider(),
          const SizedBox(height: 12),

          // ================= Request Details =================
          _section(
            title: "Request Details",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Priority",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ),
                    PriorityTag(priority: priority),
                  ],
                ),
                const SizedBox(height: 8),
                if ((department ?? '').isNotEmpty)
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Department",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                      DepartmentTag(department!), // assumes you have this widget
                    ],
                  ),
              ],
            ),
          ),

          // Job Service prefers "Notes"; else show Description
          if (_isJobService && (notes ?? '').isNotEmpty)
            _sectionCard(title: "Notes", content: notes!)
          else
            _sectionCard(title: "Description", content: description),

          // ================= Assessed by =================
          if ((assigneeName ?? '').isNotEmpty)
            _personSection(
              title: assigneeSectionTitle,
              name: assigneeName!,
              role: assigneeRole,
              trailing: null,
            ),

          // ================= Assessment & Recommendation =================
          if (assessment != null || recommendation != null)
            _section(
              title: "Assessment & Recommendation",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (assessment != null) _sectionCard(title: "Assessment", content: assessment!.trim()),
                  if (recommendation != null)
                    _sectionCard(title: "Recommendation", content: recommendation!.trim()),
                ],
              ),
            ),

          // ================= Attachments =================
          if (attachments.isNotEmpty)
            _section(
              title: "Attachments",
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attachments.map((url) {
                  final isNetwork = url.startsWith('http');
                  final img = isNetwork
                      ? Image.network(
                          url,
                          height: 80,
                          width: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => _broken(),
                        )
                      : Image.asset(
                          url,
                          height: 80,
                          width: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => _broken(),
                        );
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: img,
                  );
                }).toList(),
              ),
            ),

            // ================= Assigned to =================
            if ((assignedTo ?? '').isNotEmpty)
              _personSection(
                title: 'Assigned To',
                name: assignedTo!,
              role: assignedRole,
              trailing: (assignedSchedule ?? scheduleAvailability)?.isNotEmpty == true
                  ? _infoRow('Schedule', (assignedSchedule ?? scheduleAvailability)!)
                  : null,
            ),
            if (dateAssessed != null) _infoRow('Date Assessed', dateAssessed!),
            
            // ================= Permit-specific bits =================
            if (_isPermit || _hasAnyPermitData)
              _section(
                title: "Permit Details",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((accountType ?? '').isNotEmpty) _infoRow('Account Type', accountType!),
                    if ((permitId ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow('Permit ID', permitId!),
                    ],
                    if ((issueDate ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow('Issue Date', issueDate!),
                    ],
                    if ((expirationDate ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow('Expiration Date', expirationDate!),
                    ],
                    if ((instructions ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _sectionCard(title: "Specific Instructions", content: instructions!),
                    ],
                  ],
                ),
              ),

            // ================= Contractor Profile (optional) =================
            if ((contractorName?.isNotEmpty ?? false) ||
                (contractorCompany?.isNotEmpty ?? false) ||
                (contractorPhone?.isNotEmpty ?? false))
              _section(
                title: "Contractor Profile",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((contractorName ?? '').isNotEmpty) _infoRow('Name', contractorName!),
                    if ((contractorCompany ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow('Company', contractorCompany!),
                    ],
                    if ((contractorPhone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow('Phone', contractorPhone!),
                    ],
                  ],
                ),
              ),

          // ================= Optional bottom CTA =================
          if (onAction != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction!,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(actionLabel ?? 'Next'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasAnyPermitData =>
      (accountType?.isNotEmpty ?? false) ||
      (permitId?.isNotEmpty ?? false) ||
      (issueDate?.isNotEmpty ?? false) ||
      (expirationDate?.isNotEmpty ?? false) ||
      (instructions?.isNotEmpty ?? false);

  // ---------- UI helpers ----------

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF667085),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF344054),
            ),
          ),
        ),
      ],
    );
  }

  Widget _personSection({
    required String title,
    required String name,
    String? role,
    Widget? trailing,
  }) {
    return _section(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFD9D9D9),
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if ((role ?? '').isNotEmpty)
                      Text(
                        role!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7A5AF8),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            const SizedBox(height: 12),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF344054),
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(title),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEAECF0), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.54,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFEAECF0),
      );

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _broken() => Container(
        height: 80,
        width: 140,
        color: const Color(0xFFEAECF0),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Color(0xFF98A2B3)),
      );
}

// Maintenance Task 
class MaintenanceDetailsScreen extends StatefulWidget {
  final String title;
  final String status;
  final String maintenanceId;
  final String dateCreated;
  final String location;
  final String description;
  final String priority;
  final String recurrence;
  final String startDate;
  final String nextDate;
  final List<String> checklist;
  final List<String> attachments;
  final String adminNote;
  final String? assessment;
  final String? recommendation;

  // Optional assignee
  final String? assigneeName;
  final String? assigneeRole;
  final String assigneeSectionTitle;

  const MaintenanceDetailsScreen({
    super.key,
    required this.title,
    required this.status,
    required this.maintenanceId,
    required this.dateCreated,
    required this.location,
    required this.description,
    required this.priority,
    required this.recurrence,
    required this.startDate,
    required this.nextDate,
    required this.checklist,
    required this.attachments,
    required this.adminNote,
    this.assessment,
    this.recommendation,
    this.assigneeName,
    this.assigneeRole,
    this.assigneeSectionTitle = 'Assignee',
  });

  @override
  State<MaintenanceDetailsScreen> createState() => _MaintenanceDetailsScreenState();
}

class _MaintenanceDetailsScreenState extends State<MaintenanceDetailsScreen> {
  late List<Map<String, dynamic>> checklistState;

  @override
  void initState() {
    super.initState();
    checklistState = widget.checklist.map((item) => {"text": item, "checked": false}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Status
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF101828)),
                ),
              ),
              const SizedBox(width: 8),
              StatusTag(status: widget.status), // ← use your StatusTag
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.maintenanceId,
            style: const TextStyle(color: Color(0xFF475467), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),

          // Details (vertically aligned like RepairDetailsScreen)
          _infoRow('Date Created', widget.dateCreated),
          const SizedBox(height: 8),
          _infoRow('Location', widget.location),

          // Description
          _sectionCard(title: "Task Description", content: widget.description),

          // Priority
          _section(
            title: "Priority",
            child: PriorityTag(priority: widget.priority), // ← use your PriorityTag
          ),

          // Schedule (also vertically aligned)
          _section(
            title: "Schedule",
            child: Column(
              children: [
                _infoRow('Recurrence', widget.recurrence),
                const SizedBox(height: 8),
                _infoRow('Start Date', widget.startDate),
                const SizedBox(height: 8),
                _infoRow('Next Date', widget.nextDate),
              ],
            ),
          ),

          // Checklist
          _section(
            title: "Checklist / Task Steps",
            child: Column(
              children: checklistState.map((step) {
                final checked = step["checked"] as bool;
                return InkWell(
                  onTap: () => setState(() => step["checked"] = !checked),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, size: 20, color: const Color(0xFF111827)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step["text"] as String,
                            style: TextStyle(
                              fontSize: 14,
                              decoration: checked ? TextDecoration.lineThrough : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Recommendation (optional)
          if ((widget.recommendation ?? '').isNotEmpty)
            _sectionCard(title: "Recommendation", content: widget.recommendation!),

          // Assessment (optional)
          if ((widget.assessment ?? '').isNotEmpty)
            _sectionCard(title: "Assessment", content: widget.assessment!),

          // Assignee / Assessed by (optional)
          if ((widget.assigneeName ?? '').isNotEmpty)
            _section(
              title: widget.assigneeSectionTitle,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFD9D9D9),
                    child: Text(
                      _initials(widget.assigneeName!),
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.assigneeName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        if ((widget.assigneeRole ?? '').isNotEmpty)
                          Text(widget.assigneeRole!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF7A5AF8), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Attachments
          _section(
            title: "Attachments",
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.attachments.map((url) {
                final isNet = url.startsWith('http');
                final img = isNet
                    ? Image.network(url, height: 84, width: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _broken())
                    : Image.asset(url, height: 84, width: 140, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _broken());
                return ClipRRect(borderRadius: BorderRadius.circular(6), child: img);
              }).toList(),
            ),
          ),

          // Admin Notes
          _section(
            title: "Admin Notes",
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEFF5FF), borderRadius: BorderRadius.circular(8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning, color: Color(0xFF005CE7), size: 22),
                  const SizedBox(width: 10),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.adminNote,
                      style: const TextStyle(color: Color(0xFF005CE7), fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helpers (same pattern as your RepairDetailsScreen) ----------

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF667085)),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF344054)),
          ),
        ),
      ],
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF344054))),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEAECF0), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFF101828), fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(color: Color(0xFF475467), fontSize: 13, fontWeight: FontWeight.w400, height: 1.54, letterSpacing: 0.25)),
      ]),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Widget _broken() => Container(
        height: 84,
        width: 140,
        color: const Color(0xFFEAECF0),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Color(0xFF98A2B3)),
      );
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});
}

// Announcement Viewimport 
class AnnouncementDetailScreen extends StatelessWidget {
  final String title;
  final String datePosted;
  final String classification;
  final String description;
  final String locationAffected;
  final String scheduleStart;
  final String scheduleEnd;
  final String contactNumber;
  final String contactEmail;

  const AnnouncementDetailScreen({
    super.key,
    required this.title,
    required this.datePosted,
    required this.classification,
    required this.description,
    required this.locationAffected,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.contactNumber,
    required this.contactEmail,
  });

  Color _getBackgroundColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'utility interruption':
        return const Color(0xFFEFF5FF); // blue background
      case 'power outage':
        return const Color(0xFFFDF6A3); // yellow background
      case 'pest control':
        return const Color(0xFF91E5B0); // green background
      case 'maintenance':
        return const Color(0xFFFFD4B1); // Orange-ish
      default:
        return const Color(0xFFF5F5F7); // gray background for others
    }
  }

  Color _getTextColor(String classification) {
    switch (classification.toLowerCase()) {
      case 'utility interruption':
        return const Color(0xFF005CE7); // blue text
      case 'power outage':
        return const Color(0xFFF3B40D); // yellow text
      case 'pest control':
        return const Color(0xFF00A651); // green text
      case 'maintenance':
        return const Color(0xFFF97316); // Orange-ish
      default:
        return const Color(0xFF7D7D7D); // gray text
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getBackgroundColor(classification);
    final txtColor = _getTextColor(classification);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (title + date)
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const ShapeDecoration(
                    color: Color(0xFFD9D9D9),
                    shape: OvalBorder(
                      side: BorderSide(width: 1.68, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF101828),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                          letterSpacing: 0.10,
                        ),
                      ),
                      Text(
                        datePosted,
                        style: const TextStyle(
                          color: Color(0xFF005CE7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.43,
                          letterSpacing: 0.10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Classification Tag 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: ShapeDecoration(
                color: bgColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(130),
                ),
              ),
              child: Text(
                classification,
                style: TextStyle(
                  color: txtColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Section
            _buildSectionCard(
              title: 'Description',
              content: description,
            ),

            // Location Section
            _buildSectionCard(
              title: 'Location Affected',
              content: locationAffected,
            ),

            // Schedule Section
            _buildSectionCard(
              title: 'Schedule',
              content: 'Start: $scheduleStart\nEnd: $scheduleEnd',
            ),

            // Contact Section
            _buildSectionCard(
              title: 'Need Help?',
              content: '📱 $contactNumber\n📧 $contactEmail',
              backgroundColor: const Color(0xFFEFF5FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    Color backgroundColor = Colors.transparent,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEAECF0), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.54,
              letterSpacing: 0.25,
            ),
          ),
        ],
      ),
    );
  }
}

// Inventory Detail Screen
class InventoryDetailsScreen extends StatelessWidget {
  // Header
  final String itemName;           // e.g., 'Galvanized Screw 3mm'
  final String sku;                // e.g., 'MAT-CIV-003'
  final Widget? headerBadge;       // e.g., Tag(label: 'High Turnover', ...)

  // Meta
  final String dateAdded;          // e.g., 'Automated'
  final String classification;     // e.g., 'Materials'
  final String brandName;          // e.g., '-'
  final String department;         // e.g., 'Civil/Carpentry'

  // Stock details
  final String stockStatus;        // 'In Stock' | 'Out of Stock' | 'Critical'
  final String quantityInStock;    // '150 pcs'
  final String reorderLevel;       // '50 pcs'
  final String unit;               // 'pcs'

  // Supplier
  final String supplier;           // supplier name/text
  final String warrantyUntil;      // 'DD / MM / YY'

  const InventoryDetailsScreen({
    super.key,
    required this.itemName,
    required this.sku,
    this.headerBadge,
    required this.dateAdded,
    required this.classification,
    required this.brandName,
    required this.department,
    required this.stockStatus,
    required this.quantityInStock,
    required this.reorderLevel,
    required this.unit,
    required this.supplier,
    required this.warrantyUntil,
  });

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.15,
    );

    const skuStyle = TextStyle(
      color: Color(0xFF475467),
      fontSize: 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.14,
      letterSpacing: -0.5,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 0),
              Expanded(child: Text(itemName, style: titleStyle)),
              if (headerBadge != null) headerBadge!,
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(width: 302, child: Text(sku, style: skuStyle)),
          const SizedBox(height: 16),

          // Meta details
          Column(
            children: [
              KeyValueRow(
                label: 'Date Added',
                value: const Text(
                  'Automated',
                  style: TextStyle(
                    color: Color(0xFF475467),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.85,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              KeyValueRow(
                label: 'Classification',
                value: SizedBox(
                  width: 120,
                  child: Text(
                    classification,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.85,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              KeyValueRow(
                label: 'Brand Name',
                value: SizedBox(
                  width: 120,
                  child: Text(
                    brandName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.85,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              KeyValueRow(
                label: 'Department',
                value: DepartmentTag(department),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stock details section
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Stock Details',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.71,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                    StockStatusTag(stockStatus),
                  ],
                ),
                const SizedBox(height: 8),
                KeyValueRow(
                  label: 'Quantity in Stock',
                  value: SizedBox(
                    width: 113,
                    child: Text(
                      quantityInStock,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: stockStatus.toLowerCase().contains('out')
                            ? const Color(0xFFE84545)
                            : const Color(0xFF24D063),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                KeyValueRow(
                  label: 'Reorder Level',
                  value: const SizedBox(
                    width: 113,
                    child: Text(
                      '50 pcs',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                KeyValueRow(
                  label: 'Unit',
                  value: SizedBox(
                    width: 105,
                    child: Text(
                      unit,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.85,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Supplier info section
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supplier Information',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.14,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                KeyValueRow(
                  label: 'Supplier',
                  value: SizedBox(
                    width: 113,
                    child: Text(
                      supplier,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                KeyValueRow(
                  label: 'Warranty Until',
                  value: SizedBox(
                    width: 113,
                    child: Text(
                      warrantyUntil,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.43,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Section card ----------
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: Color(0xFFEAECF0)),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: child,
    );
  }
}

// Inventory Request Details Screen
// Inventory Request Details Screen
class InventoryRequestDetailsScreen extends StatelessWidget {
  final String itemName;
  final String requestId;
  final Widget? headerBadge;

  // Meta
  final String requestedDate;
  final String requestedBy;
  final String department;
  final String neededBy;
  final String location;

  // Item details
  final String classification;
  final String quantity;
  final String unit;

  // Notes
  final String notes;

  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const InventoryRequestDetailsScreen({
    super.key,
    required this.itemName,
    required this.requestId,
    this.headerBadge,
    required this.requestedDate,
    required this.requestedBy,
    required this.department,
    required this.neededBy,
    required this.location,
    required this.classification,
    required this.quantity,
    required this.unit,
    required this.notes,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.5,
      letterSpacing: 0.15,
    );

    const idStyle = TextStyle(
      color: Color(0xFF475467),
      fontSize: 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.14,
      letterSpacing: -0.5,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 0),
              Expanded(child: Text(itemName, style: titleStyle)),
              if (headerBadge != null) headerBadge!,
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(width: 302, child: Text(requestId, style: idStyle)),
          const SizedBox(height: 16),

          // Meta details
          Column(
            children: [
              KeyValueRow(
                label: 'Requested Date',
                value: Text(
                  requestedDate,
                  style: const TextStyle(
                    color: Color(0xFF475467),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.85,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              KeyValueRow(
                label: 'Requested By',
                value: SizedBox(
                  width: 160,
                  child: Text(
                    requestedBy,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.85,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              KeyValueRow(
                label: 'Needed By',
                value: SizedBox(
                  width: 120,
                  child: Text(
                    neededBy,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.85,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              KeyValueRow(
                label: 'Location / Unit',
                value: SizedBox(
                  width: 160,
                  child: Text(
                    location,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF475467),
                      fontSize: 13,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.85,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              KeyValueRow(
                label: 'Department',
                value: DepartmentTag(department),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item details section
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Item Details',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.71,
                    letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 8),
                KeyValueRow(
                  label: 'Classification',
                  value: SizedBox(
                    width: 120,
                    child: Text(
                      classification,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.85,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                KeyValueRow(
                  label: 'Quantity',
                  value: SizedBox(
                    width: 113,
                    child: Text(
                      quantity,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 14,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        height: 1.43,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                KeyValueRow(
                  label: 'Unit',
                  value: SizedBox(
                    width: 105,
                    child: Text(
                      unit,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF475467),
                        fontSize: 13,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.85,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notes section
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notes / Purpose',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.14,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notes.isEmpty ? '-' : notes,
                  style: const TextStyle(
                    color: Color(0xFF475467),
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.54,
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons (approve/reject)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onReject,   // update status to "Rejected"
                child: const Text('Reject'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onApprove,  // update status to "Approved" and deduct stock
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Details Permit
class DetailsPermit extends StatelessWidget {
  const DetailsPermit({
    super.key,
    this.title = 'Job Service Request',
    this.sectionTitle = 'Notes and Instructions',
    required this.notes,
    this.instructions = const [],
    this.notesHeading = 'Notes:',
    this.subHeading = 'Instructions:',
    this.onNext,
    this.maxWidth,            // optional: cap overall width
    this.panelMaxWidth = 480, // optional: cap inner panel width
    this.primaryColor = const Color(0xFF005CE7),
    this.borderColor = const Color(0xFF818181),
  });

  final String title;
  final String sectionTitle;
  final String notes;
  final List<String> instructions;
  final String notesHeading;
  final String subHeading;

  final VoidCallback? onNext;

  final double? maxWidth;
  final double panelMaxWidth;

  final Color primaryColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? screenW),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.max, 
              children: [
                const SizedBox(height: 24),

                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF005CE7),
                    fontSize: 20,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 24),

                // Main card area, expands to fill the remaining height
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: panelMaxWidth),
                      child: Container(
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(width: 1, color: borderColor),
                          ),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x3F000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Blue header
                            Container(
                              width: double.infinity,
                              height: 42,
                              padding: const EdgeInsets.all(10),
                              color: primaryColor,
                              child: Center(
                                child: Text(
                                  sectionTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            

                            // Scrollable content area
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                                child: Scrollbar(
                                  thumbVisibility: true,
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: _Body(
                                      notes: notes,
                                      instructions: instructions,
                                      notesHeading: notesHeading,
                                      subHeading: subHeading,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Next Button
                            SafeArea(
                              top: false,
                                child: fx.FilledButton(
                                  label: "Next",
                                  onPressed: onNext ?? () {},
                                  width: double.infinity,
                                  height: 80,           
                                  backgroundColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.notes,
    required this.instructions,
    required this.notesHeading,
    required this.subHeading,
  });

  final String notes;
  final List<String> instructions;
  final String notesHeading;
  final String subHeading;

  @override
  Widget build(BuildContext context) {
    const headingStyle = TextStyle(
      color: Color(0xFF1D1D1F),
      fontSize: 12,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w700,
    );

    const textStyle = TextStyle(
      color: Color(0xFF1D1D1F),
      fontSize: 12,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.4,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(notesHeading, style: headingStyle),
        const SizedBox(height: 6),
        Text(notes, style: textStyle),

        if (instructions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(subHeading, style: headingStyle),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(instructions.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: RichText(
                  text: TextSpan(
                    style: textStyle,
                    children: [
                      TextSpan(
                        text: '${i + 1}. ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: instructions[i]),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
