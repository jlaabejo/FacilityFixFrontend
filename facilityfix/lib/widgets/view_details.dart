import 'package:facilityfix/utils/ui_format.dart';
import 'package:facilityfix/widgets/buttons.dart' as fx;
import 'package:flutter/material.dart';
import 'package:facilityfix/widgets/tag.dart'; // StatusTag, PriorityTag, requestTypeTagTag, DepartmentTag

// CONCERN SLIP DETAILS
class ConcernSlipDetails extends StatelessWidget {
  //  Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String?
  departmentTag; // electrical, plumbing, hvac, carpentry, masonry, maintenance
  final String requestTypeTag; // Concern Slip
  final String? priority; // High | Medium | Low
  final String
  statusTag; // Pending | Scheduled | Assigned | In Progress | On Hold | Done
  final String? resolutionType; // job_service, work_permit, rejected

  //  Tenant / Requester
  final String requestedBy;
  final String unitId;
  final String? scheduleAvailability; // e.g. "Aug 12, 1:30 PM"

  // Request Details
  final String title;
  final String description;
  final List<String>? attachments; // request attachments (list)

  // Staff
  final String? assignedStaff; // staff user_id / name
  final String? staffPhotoUrl;
  final String? staffDepartment;
  final DateTime? assessedAt; // assessment timestamp
  final String? assessment; // staff assessment text
  final String? staffRecommendation; // staff recommendation text
  final List<String>? staffAttachments; // staff-side attachments (list)

  const ConcernSlipDetails({
    super.key,
    //  Basic Information
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.departmentTag,
    required this.requestTypeTag,
    this.priority,
    required this.statusTag,
    this.resolutionType,

    //  Tenant / Requester
    required this.requestedBy,
    required this.unitId,
    this.scheduleAvailability,

    // Request Details
    required this.title,
    required this.description,
    this.attachments,

    // Staff
    this.assignedStaff,
    this.staffDepartment,
    this.staffPhotoUrl,
    this.assessedAt,
    this.assessment,
    this.staffRecommendation,
    this.staffAttachments,
  });

  // Map resolution -> what we show as "Request Type"
  String _effectiverequestTypeTag() {
    final res = resolutionType?.trim().toLowerCase();


    if (this.title.contains("Job Service")){
      return "Job Service";
    }


    if (this.title.contains("Work Order")){
      return "Work Order";
    }

     if (this.title.contains("Rejected")){
      return "Concern Slip";
    }

     if (this.title.contains("Rejected")){
      return "Concern Slip";
    }




    switch (res) {
      case 'job_service':
        return 'Job Service';
      case 'work_permit':
        return 'Work Order';
      case 'rejected':
        // keep it as Concern Slip; reflect rejection via statusTag
        return 'Concern Slip';
      default:
        return requestTypeTag;
    }
  }

  // Local helpers for formatting via UiDateUtils
  String _fmtDate(DateTime d) => UiDateUtils.fullDate(d);
  String? _fmtScheduleAvail(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final dt = DateTime.tryParse(raw) ?? UiDateUtils.parse(raw);
    return UiDateUtils.humanDateTime(dt);
  }

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context); // 0.85..1.0 on phones

    final String detailsBody = description.trim();
    final bool showDetailsCard = detailsBody.isNotEmpty;

    final bool hasStaffBits =
        (assignedStaff?.trim().isNotEmpty ?? false) ||
        (staffDepartment?.trim().isNotEmpty ?? false) ||
        (assessedAt != null) ||
        (assessment?.trim().isNotEmpty ?? false) ||
        (staffRecommendation?.trim().isNotEmpty ?? false) ||
        ((staffAttachments ?? const []).isNotEmpty);

    final String displayType = _effectiverequestTypeTag();
    final String headerTitle =
        title.trim().isNotEmpty ? title.trim() : displayType;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 20 * s),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10 * s),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Row(
            children: [
              Expanded(
                child: Text(
                  headerTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                    letterSpacing: -0.2 * s,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              if (statusTag.isNotEmpty) StatusTag(status: statusTag),
            ],
          ),
          SizedBox(height: 4 * s),
          Text(
            UiIdFormatter.formatConcernSlipId(id),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12 * s,
              color: const Color(0xFF475467),
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),

          SizedBox(height: 12 * s),

          // ===== Basic Information (grouped) =====
          _Section(
            title: 'Basic Information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyValueRow.text(
                  label: 'Date Requested',
                  valueText: _fmtDate(createdAt),
                ),
                if (updatedAt != null) ...[
                  SizedBox(height: 6 * s),
                  KeyValueRow.text(
                    label: 'Last Updated',
                    valueText: _fmtDate(updatedAt!),
                  ),
                ],
                SizedBox(height: 6 * s),
                KeyValueRow(
                  label: 'Request Type',
                  value: RequestTypeTag(
                    displayType, // <- uses _effectiverequestTypeTag()
                    width: 140 * s, // optional: keep layout tidy
                    displayCasing: DisplayCasing.title,
                  ),
                  labelWidth: 120 * s,
                ),
                if ((priority ?? '').isNotEmpty) ...[
                  SizedBox(height: 6 * s),
                  KeyValueRow(
                    label: 'Priority',
                    value: PriorityTag(priority: priority!, width: 100 * s),
                    labelWidth: 120 * s,
                  ),
                ],
                if ((departmentTag ?? '').isNotEmpty) ...[
                  SizedBox(height: 6 * s),
                  KeyValueRow(
                    label: 'Department',
                    value: DepartmentTag(departmentTag!.trim()),
                    labelWidth: 120 * s,
                  ),
                ],
              ],
            ),
          ),

          // ----- Divider -----
          SizedBox(height: 14 * s),
          ffDivider(),
          SizedBox(height: 12 * s),

          // ===== Requester Details =====
          const _SectionTitle('Requester Details'),
          SizedBox(height: 8 * s),
          KeyValueRow.text(label: 'Requested By', valueText: requestedBy),
          if ((unitId ?? '').isNotEmpty) ...[
            SizedBox(height: 4 * s),
            KeyValueRow.text(label: 'Unit ID', valueText: unitId!),
          ],

          // ----- Divider -----
          SizedBox(height: 14 * s),
          ffDivider(),
          SizedBox(height: 12 * s),

          // ===== Request Details =====
          _Section(
            title: "Request Details",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showDetailsCard)
                  _SectionCard(
                    title: 'Description',
                    content: detailsBody,
                    padding: EdgeInsets.all(14 * s),
                    hideIfEmpty: false,
                  ),

                if ((attachments?.isNotEmpty ?? false)) ...[
                  SizedBox(height: 12 * s),
                  const _SectionTitle('Attachments'),
                  SizedBox(height: 8 * s),
                  Wrap(
                    spacing: 8 * s,
                    runSpacing: 8 * s,
                    children:
                        attachments!
                            .map((u) => _thumb(u, h: 80 * s, w: 140 * s))
                            .toList(),
                  ),
                ],
              ],
            ),
          ),

          // ===== Staff & Assessment =====
          if (hasStaffBits) ...[
            SizedBox(height: 14 * s),
            ffDivider(),
            SizedBox(height: 12 * s),

            _Section(
              title: 'Staff Assessment',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Assigned Staff subsection (only if we have any staff info)
                  if ((assignedStaff?.trim().isNotEmpty ?? false) ||
                      (staffDepartment?.trim().isNotEmpty ?? false) ||
                      (staffPhotoUrl?.trim().isNotEmpty ?? false)) ...[
                    _Section(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((assignedStaff?.trim().isNotEmpty ?? false)) ...[
                            _AvatarNameBlock(
                              name: assignedStaff!.trim(),
                              departmentTag:
                                  (staffDepartment?.trim().isNotEmpty ?? false)
                                      ? staffDepartment!.trim()
                                      : null,
                              photoUrl:
                                  (staffPhotoUrl?.trim().isNotEmpty ?? false)
                                      ? staffPhotoUrl!.trim()
                                      : null,
                            ),
                            SizedBox(height: 10 * s),
                          ] else if ((staffDepartment?.trim().isNotEmpty ??
                              false)) ...[
                            DepartmentTag(staffDepartment!.trim()),
                            SizedBox(height: 10 * s),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // Date Assessed (shown once)
                  if (assessedAt != null) ...[
                    KeyValueRow.text(
                      label: 'Date Assessed',
                      valueText: _fmtDate(assessedAt!),
                    ),
                    SizedBox(height: 8 * s),
                  ],

                  // Assessment text
                  if ((assessment?.trim().isNotEmpty ?? false)) ...[
                    _SectionCard(
                      title: 'Assessment',
                      content: assessment!.trim(),
                      padding: EdgeInsets.all(14 * s),
                      hideIfEmpty: false,
                    ),
                    SizedBox(height: 8 * s),
                  ],

                  // Staff recommendation
                  if ((staffRecommendation?.trim().isNotEmpty ?? false)) ...[
                    _SectionCard(
                      title: 'Recommendation',
                      content: staffRecommendation!.trim(),
                      padding: EdgeInsets.all(14 * s),
                      hideIfEmpty: false,
                    ),
                    SizedBox(height: 8 * s),
                  ],

                  // Staff attachments
                  if ((staffAttachments?.isNotEmpty ?? false)) ...[
                    const _SectionTitle('Attachments'),
                    SizedBox(height: 8 * s),
                    Wrap(
                      spacing: 8 * s,
                      runSpacing: 8 * s,
                      children:
                          staffAttachments!
                              .map((u) => _thumb(u, h: 80 * s, w: 140 * s))
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// JOB SERVICE DETAILS -----------------------------------
class JobServiceDetails extends StatelessWidget {
  //  Basic Information
  final String id;
  final String concernSlipId; // link to concern slip
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String requestTypeTag; // e.g. "Job Service"
  final String? resolutionType; // job_service, work_permit, rejected
  final String? priority; // High | Medium | Low
  final String
  statusTag; // Pending | Scheduled | Assigned | In Progress | On Hold | Done

  //  Tenant / Requester
  final String requestedBy;
  final String? requestedByName; // Full name of requester
  final String? requestedByEmail; // Email of requester
  final String unitId;
  final String? scheduleAvailability; // e.g. "Aug 12, 1:30 PM"
  final String? additionalNotes;

  // Staff
  final String? assignedStaff; // staff user_id / display name
  final String? staffDepartment;
  final String? staffPhotoUrl;

  // Documentation
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? completionAt;

  final DateTime? assessedAt;
  final String? assessment;
  final List<String>? staffAttachments;

  // Tracking
  final List<String>? materialsUsed;

  const JobServiceDetails({
    super.key,

    // Basic Information
    required this.id,
    required this.concernSlipId,
    required this.createdAt,
    this.updatedAt,
    required this.requestTypeTag,
    this.priority,
    required this.statusTag,
    this.resolutionType,

    // Tenant / Requester
    required this.requestedBy,
    this.requestedByName,
    this.requestedByEmail,
    required this.unitId,
    this.scheduleAvailability,
    this.additionalNotes,

    // Staff
    this.assignedStaff,
    this.staffDepartment,
    this.staffPhotoUrl,

    // Documentation
    this.startedAt,
    this.completedAt,
    this.completionAt,
    this.assessedAt,
    this.assessment,
    this.staffAttachments,

    // Tracking
    this.materialsUsed,
  });

  // Map resolution type to what we DISPLAY as "Request Type".
  String _effectiverequestTypeTag() {
    final r = resolutionType?.trim().toLowerCase().replaceAll(
      RegExp(r'[\s\-]+'),
      '_',
    );
    switch (r) {
      case 'job_service':
        return 'Job Service';
      case 'work_permit':
        return 'Work Order';
      case 'rejected':
        return requestTypeTag; // keep original
      default:
        return requestTypeTag; // fallback
    }
  }

  // Force the status chip to show "Rejected" when resolutionType == rejected.
  String get _displayStatus =>
      (resolutionType?.trim().toLowerCase() == 'rejected')
          ? 'Rejected'
          : statusTag;

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context); // 0.85..1.0 on phones

    final bool hasStaffBits =
        (assignedStaff?.trim().isNotEmpty ?? false) ||
        (staffDepartment?.trim().isNotEmpty ?? false) ||
        (assessedAt != null);

    final bool hasAnyDocs =
        (startedAt != null) ||
        (completedAt != null) ||
        (completionAt != null) ||
        (assessment?.trim().isNotEmpty ?? false) ||
        ((staffAttachments ?? const []).isNotEmpty);

    final bool hasTracking = (materialsUsed?.isNotEmpty ?? false);

    final displayType = _effectiverequestTypeTag();
    final headerTitle = displayType.isNotEmpty ? displayType : 'Job Service';

    // Format helpers using UiDateUtils
    String _fmtDate(DateTime d) => UiDateUtils.fullDate(d);
    String _fmtDateTime(DateTime d) => UiDateUtils.humanDateTime(d);
    String? _fmtSchedAvail(String? raw) {
      if (raw == null || raw.trim().isEmpty) return null;
      final dt = DateTime.tryParse(raw) ?? UiDateUtils.parse(raw);
      return UiDateUtils.humanDateTime(dt);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 20 * s),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10 * s),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Row(
            children: [
              Expanded(
                child: Text(
                  headerTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                    letterSpacing: -0.2 * s,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              if (_displayStatus.isNotEmpty) StatusTag(status: _displayStatus),
            ],
          ),
          SizedBox(height: 4 * s),

          // IDs row (Job Service ID + linked Concern Slip ID)
          Row(
            children: [
              Expanded(
                child: Text(
                  UiIdFormatter.formatJobServiceId(id),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12 * s,
                  color: const Color(0xFF475467),
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  ),
                ),
                 
              ),
              SizedBox(width: 8 * s),
              Text(
                'From Slip: $concernSlipId',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5 * s,
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 12 * s),

          // ===== Basic Information (grouped) =====
          _Section(
            title: 'Basic Information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyValueRow.text(
                  label: 'Date Created',
                  valueText: _fmtDate(createdAt),
                ),
                if (updatedAt != null) ...[
                  SizedBox(height: 6 * s),
                  KeyValueRow.text(
                    label: 'Last Updated',
                    valueText: _fmtDate(updatedAt!),
                  ),
                ],
                SizedBox(height: 6 * s),
                KeyValueRow(
                  label: 'Request Type',
                  value: RequestTypeTag(
                    displayType, // <- uses _effectiverequestTypeTag()
                    width: 140 * s, // optional: keep layout tidy
                    displayCasing: DisplayCasing.title,
                  ),
                  labelWidth: 120 * s,
                ),
                if ((priority ?? '').isNotEmpty) ...[
                  SizedBox(height: 6 * s),
                  KeyValueRow(
                    label: 'Priority',
                    value: PriorityTag(priority: priority!, width: 100 * s),
                    labelWidth: 120 * s,
                  ),
                ],
              ],
            ),
          ),

          // ----- Divider -----
          SizedBox(height: 14 * s),
          ffDivider(),
          SizedBox(height: 12 * s),

          // ===== Requester Details =====
          const _SectionTitle('Requester Details'),
          SizedBox(height: 8 * s),
          KeyValueRow.text(label: 'Requested By', valueText: requestedBy),
          if ((unitId ?? '').isNotEmpty) ...[
            SizedBox(height: 4 * s),
            KeyValueRow.text(label: 'Unit ID', valueText: unitId!),
          ],

          // ----- Divider -----
          SizedBox(height: 14 * s),
          ffDivider(),
          SizedBox(height: 12 * s),

          // ===== Additional Notes Section =====
          if ((additionalNotes?.trim().isNotEmpty ?? false) ||
              (scheduleAvailability?.trim().isNotEmpty ?? false) ||
              (assessment?.trim().isNotEmpty ?? false)) ...[
            _Section(
              title: 'Additional Notes',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Additional Notes Text
                  if ((additionalNotes?.trim().isNotEmpty ?? false)) ...[
                    Text(
                      additionalNotes!.trim(),
                      style: TextStyle(fontSize: 14 * s),
                    ),
                    SizedBox(height: 8 * s),
                  ],

                  // Optional Schedule Availability
                  if ((scheduleAvailability?.trim().isNotEmpty ?? false)) ...[
                    KeyValueRow.text(
                      label: 'Schedule Availability',
                      valueText: _fmtSchedAvail(scheduleAvailability!.trim())!,
                      labelWidth: 160 * s,
                    ),
                    SizedBox(height: 8 * s),
                  ],

                  // Optional Assessment
                  if ((assessment?.trim().isNotEmpty ?? false)) ...[
                    KeyValueRow.text(
                      label: 'Assessment',
                      valueText: assessment!.trim(),
                      labelWidth: 160 * s,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14 * s),
          ],


          // ----- Divider -----
          SizedBox(height: 14 * s),
          ffDivider(),
          SizedBox(height: 12 * s),

          // ===== Staff =====
          if (hasStaffBits) ...[
            _Section(
              title: 'Assigned Staff',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((assignedStaff?.trim().isNotEmpty ?? false)) ...[
                    _AvatarNameBlock(
                      name: assignedStaff!.trim(),
                      departmentTag:
                          (staffDepartment?.trim().isNotEmpty ?? false)
                              ? staffDepartment!.trim()
                              : null,
                      photoUrl:
                          (staffPhotoUrl?.trim().isNotEmpty ?? false)
                              ? staffPhotoUrl!.trim()
                              : null,
                    ),
                    SizedBox(height: 10 * s),
                  ] else if ((staffDepartment?.trim().isNotEmpty ?? false)) ...[
                    DepartmentTag(staffDepartment!.trim()),
                    SizedBox(height: 10 * s),
                  ],

                  if (assessedAt != null)
                    KeyValueRow.text(
                      label: 'Date Assessed',
                      valueText: _fmtDate(assessedAt!),
                    ),
                ],
              ),
            ),
            SizedBox(height: 14 * s),
          ],

          // ===== Documentation =====
          if (hasAnyDocs) ...[
            _Section(
              title: 'Task Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (startedAt != null)
                    KeyValueRow.text(
                      label: 'Started',
                      valueText: _fmtDateTime(startedAt!),
                    ),
                  if (completedAt != null) ...[
                    SizedBox(height: 6 * s),
                    KeyValueRow.text(
                      label: 'Completed',
                      valueText: _fmtDateTime(completedAt!),
                    ),
                  ],
                  if (completionAt != null) ...[
                    SizedBox(height: 6 * s),
                    KeyValueRow.text(
                      label: 'Completion Date',
                      valueText: _fmtDateTime(completionAt!),
                    ),
                  ],
                  if ((assessment?.trim().isNotEmpty ?? false)) ...[
                    SizedBox(height: 10 * s),
                    _SectionCard(
                      title: 'Assessment',
                      content: assessment!.trim(),
                      padding: EdgeInsets.all(14 * s),
                      hideIfEmpty: false,
                    ),
                  ],
                  if ((staffAttachments?.isNotEmpty ?? false)) ...[
                    SizedBox(height: 12 * s),
                    const _SectionTitle('Attachments'),
                    SizedBox(height: 8 * s),
                    Wrap(
                      spacing: 8 * s,
                      runSpacing: 8 * s,
                      children:
                          staffAttachments!
                              .map((u) => _thumb(u, h: 80 * s, w: 140 * s))
                              .toList(),
                    ),
                  ],
                ],
              ),
            ),

            // ----- Divider -----
            SizedBox(height: 14 * s),
          ],

          // ===== Tracking =====
          if (hasTracking) ...[
            _Section(
              title: 'Materials Used',
              child: Wrap(
                spacing: 8 * s,
                runSpacing: 8 * s,
                children:
                    materialsUsed!
                        .where((m) => m.trim().isNotEmpty)
                        .map((m) => _materialChip(m.trim(), s))
                        .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Small chip for a material item
  Widget _materialChip(String text, double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 11.5 * s,
          color: const Color(0xFF344054),
          height: 1.0,
        ),
      ),
    );
  }
}

// WORK ORDER PERMIT ---------------------------

class WorkOrderPermitDetails extends StatelessWidget {
  //  Basic Information
  final String? id;
  final String concernSlipId; // required (links to concern slip)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String requestTypeTag; // e.g. "Work Order Permit"
  final String? priority; // High | Medium | Low
  final String
  statusTag; // Pending | Scheduled | Assigned | In Progress | On Hold | Done
  final String? resolutionType; // job_service, work_permit, rejected

  //  Tenant / Requester
  final String requestedBy; // tenant user_id/display
  final String? unitId;

  // Permit Specific Details
  final String contractorName; // required
  final String contractorNumber; // required
  final String? contractorCompany;

  // Work Specifics Details
  final DateTime workScheduleFrom; // required (date + time)
  final DateTime workScheduleTo; // required (date + time)
  final String? entryEquipments; // tools/equipment needed at entry

  // Approval Tracking
  final String? approvedBy; // admin user_id/display
  final DateTime? approvalDate;
  final String? denialReason;
  final String? adminNotes; // (moved from additionalNotes)
  
  // Completion Notes
  final String? completionNotes;

  // Callbacks
  final Future<void> Function(String permitId, String? completionNotes)? onComplete;

  const WorkOrderPermitDetails({
    super.key,

    // Basic Information
    this.id,
    required this.concernSlipId,
    this.createdAt,
    this.updatedAt,
    required this.requestTypeTag,
    this.priority,
    required this.statusTag,
    this.resolutionType,

    // Tenant / Requester
    required this.requestedBy,
    this.unitId,

    // Permit Specific Details
    required this.contractorName,
    required this.contractorNumber,
    this.contractorCompany,

    // Work Specifics Details
    required this.workScheduleFrom,
    required this.workScheduleTo,
    this.entryEquipments,

    // Approval Tracking
    this.approvedBy,
    this.approvalDate,
    this.denialReason,
    this.adminNotes,
    this.completionNotes,
    
    // Callbacks
    this.onComplete,
  });

  // ---- Behavior derived from resolutionType ---------------------------------

  // What to display as "Request Type"
  // - job_service  -> "Job Service"
  // - work_permit  -> "Work Order"
  // - rejected/other -> keep original requestTypeTag
  String _effectiverequestTypeTag() {
    final r = resolutionType?.trim().toLowerCase().replaceAll(
      RegExp(r'[\s\-]+'),
      '_',
    );
    switch (r) {
      case 'job_service':
        return 'Job Service';
      case 'work_permit':
        return 'Work Order';
      case 'rejected':
        return requestTypeTag; // keep original label
      default:
        return requestTypeTag; // fallback
    }
  }

  // Force status chip to "Rejected" when resolutionType == rejected
  String get _displayStatus =>
      (resolutionType?.trim().toLowerCase() == 'rejected')
          ? 'Rejected'
          : statusTag;

  // ---- Formatting helpers ----------------------------------------------------

  /// "Aug 23, 2025 · 8:30 PM"
  static String _formatWorkSchedule(DateTime dt) =>
      UiDateUtils.humanDateTime(dt);

  // Human-friendly window duration like "2h", "2h 30m", or "1d 3h"
  static String _formatWindowDuration(DateTime from, DateTime to) {
    final diff = to.difference(from);
    if (diff.isNegative) return '—';

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (mins > 0 || parts.isEmpty)
      parts.add('${mins}m'); // show at least minutes

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context); // 0.85..1.0 on phones
    final displayType = _effectiverequestTypeTag();
    final headerTitle =
        displayType.isNotEmpty ? displayType : 'Work Order Permit';

    final hasApprovalBits =
        (approvedBy?.trim().isNotEmpty ?? false) ||
        (approvalDate != null) ||
        (denialReason?.trim().isNotEmpty ?? false) ||
        (adminNotes?.trim().isNotEmpty ?? false);

    // Format helpers using UiDateUtils
    String _fmtDate(DateTime? d) {
      if (d == null) return '—';
      return UiDateUtils.fullDate(d);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 20 * s),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10 * s),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header =====
          Row(
            children: [
              Expanded(
                child: Text(
                  headerTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                    letterSpacing: -0.2 * s,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              if (_displayStatus.isNotEmpty) StatusTag(status: _displayStatus),
            ],
          ),
          SizedBox(height: 4 * s),

          // IDs row (permit ID + linked Concern Slip ID)
          Row(
            children: [
              if ((id ?? '').isNotEmpty)
                Expanded(
                  child: Text(
                    UiIdFormatter.formatWorkOrderPermitId(id!),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12 * s,
                      color: const Color(0xFF475467),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                )
              else
                const Spacer(),
              SizedBox(width: 8 * s),
              Text(
                'From Slip: $concernSlipId',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5 * s,
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 12 * s),

          // ===== Basic Information (grouped) =====
          _Section(
            title: 'Basic Information',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyValueRow.text(
                  label: 'Date Created',
                  valueText: _fmtDate(createdAt),
                ),
                if (updatedAt != null) ...[
                  SizedBox(height: 6 * s),
                  KeyValueRow.text(
                    label: 'Last Updated',
                    valueText: _fmtDate(updatedAt!),
                  ),
                ],
                SizedBox(height: 6 * s),
                KeyValueRow(
                  label: 'Request Type',
                  value: RequestTypeTag(
                    displayType, // <- uses _effectiverequestTypeTag()
                    width: 140 * s, // optional: keep layout tidy
                    displayCasing: DisplayCasing.title,
                  ),
                  labelWidth: 120 * s,
                ),
                if ((priority ?? '').isNotEmpty) ...[
                  SizedBox(height: 6 * s),
                  KeyValueRow(
                    label: 'Priority',
                    value: PriorityTag(priority: priority!, width: 100 * s),
                    labelWidth: 120 * s,
                  ),
                ],
              ],
            ),
          ),

          // ----- Divider -----
          SizedBox(height: 14 * s),
          ffDivider(),
          SizedBox(height: 12 * s),

          // ===== Requester Details =====
          const _SectionTitle('Requester Details'),
          SizedBox(height: 8 * s),
          KeyValueRow.text(label: 'Requested By', valueText: requestedBy),
          if ((unitId ?? '').isNotEmpty) ...[
            SizedBox(height: 4 * s),
            KeyValueRow.text(label: 'Unit ID', valueText: unitId!),
          ],

          // ----- Divider -----
          SizedBox(height: 14 * s),
          ffDivider(),
          SizedBox(height: 12 * s),

          // ===== Permit Details =====
          _Section(
            title: 'Permit Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyValueRow.text(
                  label: 'Contractor',
                  valueText: contractorName,
                ),
                SizedBox(height: 6 * s),
                KeyValueRow.text(label: 'Contact', valueText: contractorNumber),
                if ((contractorCompany ?? '').isNotEmpty) ...[
                  SizedBox(height: 6 * s),
                  KeyValueRow.text(
                    label: 'Company',
                    valueText: contractorCompany!,
                  ),
                ],
              ],
            ),
          ),

          // ----- Divider -----
          SizedBox(height: 14 * s),
          ffDivider(),
          SizedBox(height: 12 * s),

          // ===== Work Schedule =====
          _Section(
            title: 'Work Schedule',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KeyValueRow.text(
                  label: 'From',
                  valueText: _formatWorkSchedule(workScheduleFrom),
                ),
                SizedBox(height: 6 * s),
                KeyValueRow.text(
                  label: 'To',
                  valueText: _formatWorkSchedule(workScheduleTo),
                ),
                SizedBox(height: 6 * s),
                KeyValueRow.text(
                  label: 'Duration',
                  valueText: _formatWindowDuration(
                    workScheduleFrom,
                    workScheduleTo,
                  ),
                ),
                if ((entryEquipments?.trim().isNotEmpty ?? false)) ...[
                  SizedBox(height: 10 * s),
                  _SectionCard(
                    title: 'Entry Equipment',
                    content: entryEquipments!.trim(),
                    padding: EdgeInsets.all(14 * s),
                    hideIfEmpty: false,
                  ),
                  if ((adminNotes?.trim().isNotEmpty ?? false))
                    _SectionCard(
                      title: 'Admin Notes',
                      content: adminNotes!.trim(),
                      padding: EdgeInsets.all(14 * s),
                      hideIfEmpty: false,
                    ),
                ],
              ],
            ),
          ),

          // ----- Divider -----
          if (hasApprovalBits) ...[
            SizedBox(height: 14 * s),
            ffDivider(),
            SizedBox(height: 12 * s),

            // ===== Approval Tracking =====
            _Section(
              title: 'Approval Tracking',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((approvedBy?.trim().isNotEmpty ?? false)) ...[
                    _AvatarNameBlock(
                      name: approvedBy!.trim(),
                      departmentTag: 'Admin',
                    ),
                    SizedBox(height: 10 * s),
                  ],
                  if (approvalDate != null) ...[
                    KeyValueRow.text(
                      label: 'Approval Date',
                      valueText: UiDateUtils.fullDate(approvalDate!),
                    ),
                    SizedBox(height: 6 * s),
                  ],
                  if ((denialReason?.trim().isNotEmpty ?? false)) ...[
                    _SectionCard(
                      title: 'Denial Reason',
                      content: denialReason!.trim(),
                      padding: EdgeInsets.all(14 * s),
                      hideIfEmpty: false,
                    ),
                    SizedBox(height: 8 * s),
                  ],
                  if ((completionNotes?.trim().isNotEmpty ?? false)) ...[
                    _SectionCard(
                      title: 'Completion Notes',
                      content: completionNotes!.trim(),
                      padding: EdgeInsets.all(14 * s),
                      hideIfEmpty: false,
                    ),
                    SizedBox(height: 8 * s),
                  ],
                ],
              ),
            ),
          ],
          
          // ===== Complete Button (only show if approved/in-progress and onComplete callback exists) =====
          if (_canBeCompleted() && onComplete != null && id != null) ...[
           
          ],
        ],
      ),
    );
  }
  
  // Check if work order can be completed
  bool _canBeCompleted() {
    final status = statusTag.toLowerCase().trim();
    final displayStatus = _displayStatus.toLowerCase().trim();
    
    // Debug output
    print('[WorkOrderPermit] Checking completion eligibility:');
    print('  statusTag: "$statusTag" (normalized: "$status")');
    print('  _displayStatus: "$_displayStatus" (normalized: "$displayStatus")');
    print('  onComplete: ${onComplete != null}');
    print('  id: $id');
    
    // Can complete if:
    // 1. Status is approved or in progress
    // 2. Not already completed
    // 3. Not rejected
    final canComplete = (status == 'approved' || 
            status == 'in progress' || 
            displayStatus == 'approved' ||
            displayStatus == 'in progress') &&
           status != 'completed' &&
           status != 'rejected' &&
           displayStatus != 'completed' &&
           displayStatus != 'rejected';
    
    print('  canComplete: $canComplete');
    return canComplete;
  }
  
  // Show completion dialog
  void _showCompleteDialog(BuildContext context) {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Complete Work Order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Mark this work order permit as completed?'),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Completion Notes (Optional)',
                  hintText: 'Enter any notes about the completion...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                if (id != null && onComplete != null) {
                  try {
                    await onComplete!(
                      id!,
                      notesController.text.isNotEmpty 
                          ? notesController.text 
                          : null,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error completing work order: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // FORMAT SCHEDULE AVAILABILITY (moved from ConcernSlipDetails)
  // ------------------------------------------------------------

  /// Format schedule availability string to human-readable form.
  ///
  /// - Input: "2025-08-12 13:30:00" or "Aug 12, 1:30 PM"
  /// - Output: "Aug 12, 1:30 PM" (or similar, based on current date/time)
  String? _fmtScheduleAvail(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final dt = DateTime.tryParse(raw) ?? UiDateUtils.parse(raw);
    return UiDateUtils.humanDateTime(dt);
  }
}

// MAINTENANCE DETAILS --------------------
class MaintenanceDetails extends StatefulWidget {
  //  Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String?
  departmentTag; // electrical, plumbing, hvac, carpentry, masonry, maintenance
  final String requestTypeTag; // Concern Slip / Maintenance
  final String? priority; // High | Medium | Low
  final String
  statusTag; // Pending | Scheduled | Assigned | In Progress | On Hold | Done

  //  Tenant / Requester
  final String requestedBy;
  final String? scheduleDate; // string (ISO or raw)

  // Request Details
  final String title;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? location;
  final String? description;
  final List<String>? checklist;
  final List<String>? attachments;
  final String? adminNote;

  // Staff
  final String? assignedStaff; // staff user_id / name aasigned to or assed by
  final String? staffDepartment;
  final String? staffPhotoUrl;
  final DateTime? assessedAt; // assessment timestamp
  final String? assessment; // staff assessment text
  final List<String>? staffAttachments; // staff-side attachments (list)

  // Tracking
  final List<String>? materialsUsed;

  // Interactive checklist and inventory
  final List<Map<String, dynamic>>? checklistItems;
  final List<Map<String, dynamic>>? inventoryRequests;
  final int? completedCount;
  final int? totalCount;
  final bool? isUpdating;
  final Function(int)? onToggleChecklistItem;
  final Function(Map<String, dynamic>)? onInventoryItemTap;
  final String? currentStaffId;
  final String? taskCategory;
  
  // Action callbacks
  final VoidCallback? onHold;
  final VoidCallback? onCreateAssessment;

  const MaintenanceDetails({
    super.key,
    // Basic
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.departmentTag,
    required this.requestTypeTag,
    this.priority,
    required this.statusTag,
    // Tenant / Requester
    required this.requestedBy,
    required this.scheduleDate,
    // Request Details
    required this.title,
    this.startedAt,
    this.completedAt,
    this.location,
    this.description,
    this.checklist,
    this.attachments,
    this.adminNote,
    // Staff
    this.assignedStaff,
    this.staffDepartment,
    this.staffPhotoUrl,
    this.assessedAt,
    this.assessment,
    this.staffAttachments,
    // Tracking
    this.materialsUsed,
    // Interactive
    this.checklistItems,
    this.inventoryRequests,
    this.completedCount,
    this.totalCount,
    this.isUpdating,
    this.onToggleChecklistItem,
    this.onInventoryItemTap,
    this.currentStaffId,
    this.taskCategory,
    // Actions
    this.onHold,
    this.onCreateAssessment,
  });

  @override
  State<MaintenanceDetails> createState() => _MaintenanceState();
}

class _MaintenanceState extends State<MaintenanceDetails> {
  late final List<Map<String, dynamic>> _checklistState;

  @override
  void initState() {
    super.initState();
    _checklistState =
        (widget.checklist ?? const <String>[])
            .map((item) => {"text": item, "checked": false})
            .toList();
  }

  // 48h rule for DateTime? fields
  String _relativeOrFullDT(DateTime? dt) {
    if (dt == null) return '—';
    final hours = DateTime.now().difference(dt).inHours;
    return hours < 48 ? UiDateUtils.timeAgo(dt) : UiDateUtils.fullDate(dt);
  }

  // Human formatting for scheduleDate (String?)
  String _humanSchedule(String? raw) {
    if (raw == null) return '—';
    final s = raw.trim();
    if (s.isEmpty) return '—';
    final dt = DateTime.tryParse(s) ?? UiDateUtils.parse(s);
    return UiDateUtils.humanDateTime(dt);
  }

  // Shared section card builder (matches your Contact Section style)
  Widget _buildSectionCard({
    required Widget child,
    Color backgroundColor = const Color(0xFFF9FAFB),
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAssigned =
        (widget.assignedStaff ?? '').trim().isNotEmpty ||
        (widget.staffDepartment ?? '').trim().isNotEmpty ||
        (widget.scheduleDate ?? '').trim().isNotEmpty;

    final assessedBy = (widget.assignedStaff ?? '').trim();
    final assessedDept = (widget.staffDepartment ?? '').trim();
    final assessedAt = widget.assessedAt;
    final assessedText = (widget.assessment ?? '').trim();
    final assessedAttachments = widget.staffAttachments ?? const <String>[];
    final hasAssessmentBlock =
        assessedBy.isNotEmpty ||
        assessedDept.isNotEmpty ||
        assessedAt != null ||
        assessedText.isNotEmpty ||
        assessedAttachments.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title.trim().isEmpty
                      ? 'Maintenance Task'
                      : widget.title.trim(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusTag(status: widget.statusTag),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.id,
            style: const TextStyle(
              color: Color(0xFF475467),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Basic info
          _Section(
            child: Column(
              children: [
                KeyValueRow.text(
                  label: 'Date Created',
                  valueText: _relativeOrFullDT(widget.createdAt),
                ),
                const SizedBox(height: 8),
                KeyValueRow.text(
                  label: 'Request Type',
                  valueText: widget.requestTypeTag,
                ),
                if ((widget.location ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  KeyValueRow.text(
                    label: 'Location',
                    valueText: widget.location!.trim(),
                  ),
                ],
                if ((widget.departmentTag ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  KeyValueRow(
                    label: 'Department',
                    value: DepartmentTag(widget.departmentTag!.trim()),
                  ),
                ],
                if ((widget.priority ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  KeyValueRow(
                    label: 'Priority',
                    value: PriorityTag(priority: widget.priority!.trim()),
                  ),
                ],
                if (widget.startedAt != null) ...[
                  const SizedBox(height: 8),
                  KeyValueRow.text(
                    label: 'Started',
                    valueText: _relativeOrFullDT(widget.startedAt),
                  ),
                ],
                if (widget.completedAt != null) ...[
                  const SizedBox(height: 8),
                  KeyValueRow.text(
                    label: 'Completed',
                    valueText: _relativeOrFullDT(widget.completedAt),
                  ),
                ],
                if ((widget.scheduleDate ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  KeyValueRow.text(
                    label: 'Schedule',
                    valueText: _humanSchedule(widget.scheduleDate),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          ffDivider(),
          const SizedBox(height: 8),
          // Description
          _SectionCard(
            title: 'Description',
            content: (widget.description ?? '').trim(),
            padding: const EdgeInsets.all(14),
            hideIfEmpty: false,
          ),

          const SizedBox(height: 10),

          // Interactive Checklist Section
          if (widget.checklistItems != null &&
              widget.checklistItems!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.checklist,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Task Checklist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.completedCount ?? 0} of ${widget.totalCount ?? 0} completed',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Checklist Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.checklistItems!.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE5E7EB),
                        ),
                    itemBuilder: (context, index) {
                      final item = widget.checklistItems![index];
                      final isCompleted = item['completed'] == true;
                      final assignedTo = item['assigned_to']?.toString() ?? '';

                      // If there's an assigned_to field, check if it matches current user
                      if (widget.currentStaffId != null &&
                          assignedTo.isNotEmpty &&
                          assignedTo != widget.currentStaffId &&
                          widget.taskCategory == 'safety') {
                        return const SizedBox.shrink();
                      }

                      return InkWell(
                        onTap:
                            widget.isUpdating == true ||
                                    widget.onToggleChecklistItem == null
                                ? null
                                : () => widget.onToggleChecklistItem!(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 24,
                                color:
                                    isCompleted
                                        ? Colors.green
                                        : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['task'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isCompleted
                                            ? const Color(0xFF6B7280)
                                            : const Color(0xFF1F2937),
                                    decoration:
                                        isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                    fontWeight:
                                        isCompleted
                                            ? FontWeight.w400
                                            : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (widget.isUpdating == true)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          // Inventory Requests Section
          if (widget.inventoryRequests != null &&
              widget.inventoryRequests!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: Color(0xFF6B7280),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Required Materials & Tools',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Inventory Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.inventoryRequests!.length,
                    separatorBuilder:
                        (_, __) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFE5E7EB),
                        ),
                    itemBuilder: (context, index) {
                      final request = widget.inventoryRequests![index];
                      final itemName = request['item_name'] ?? 'Unknown Item';
                      final quantity =
                          request['quantity_requested'] ??
                          request['stock_quantity'] ??
                          0;
                      final status = request['status'] ?? 'pending';
                      final unit = request['unit'] ?? '';
                      final category = request['category'] ?? '';

                      // Determine if item is received
                      bool isReceived =
                          status.toLowerCase() == 'fulfilled' ||
                          status.toLowerCase() == 'received';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'RESERVE $quantity',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'STOCK $quantity',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (category.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        category.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isReceived
                                            ? const Color(0xFFECFDF5)
                                            : Colors.white,
                                    border: Border.all(
                                      color:
                                          isReceived
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF005CE7),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isReceived ? 'Received' : 'Request',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isReceived
                                              ? const Color(0xFF059669)
                                              : const Color(0xFF005CE7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Checklist (interactive)
          if ((widget.checklist ?? const <String>[]).isNotEmpty)
            _Section(
              title: "Checklist / Task Steps",
              child: Column(
                children:
                    _checklistState.map((step) {
                      final checked = step["checked"] as bool;
                      return InkWell(
                        onTap: () => setState(() => step["checked"] = !checked),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(
                                checked
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: const Color(0xFF111827),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step["text"] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    decoration:
                                        checked
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
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

          const SizedBox(height: 10),

          // Attachments
          if ((widget.attachments ?? const <String>[]).isNotEmpty)
            _Section(
              title: "Attachments",
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (widget.attachments ?? const <String>[])
                        .map((u) => _thumb(u, h: 80, w: 140))
                        .toList(),
              ),
            ),

          const SizedBox(height: 8),
          ffDivider(),
          const SizedBox(height: 8),

          // Staff Details
          if ((widget.assignedStaff ?? '').trim().isNotEmpty ||
              (widget.assessment ?? '').trim().isNotEmpty ||
              widget.assessedAt != null ||
              (widget.staffAttachments ?? const <String>[]).isNotEmpty)
            _Section(
              title: "Staff Details",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar, Name, Department
                  if ((widget.assignedStaff?.trim().isNotEmpty ?? false))
                    _AvatarNameBlock(
                      name: widget.assignedStaff!.trim(),
                      departmentTag:
                          (widget.staffDepartment?.trim().isNotEmpty ?? false)
                              ? widget.staffDepartment!.trim()
                              : null,
                      photoUrl:
                          (widget.staffPhotoUrl?.trim().isNotEmpty ?? false)
                              ? widget.staffPhotoUrl!.trim()
                              : null,
                    ),

                  // ===== Assessment Section =====
                  if (widget.assessedAt != null ||
                      (widget.assessment?.trim().isNotEmpty ?? false)) ...[
                    const SizedBox(height: 14),
                    _Section(
                      title: 'Assessment',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Assessed
                          if (widget.assessedAt != null) ...[
                            KeyValueRow.text(
                              label: 'Assessed At',
                              valueText: _relativeOrFullDT(widget.assessedAt),
                            ),
                            const SizedBox(height: 8),
                          ],

                          // Assessment Notes
                          if ((widget.assessment ?? '').trim().isNotEmpty) ...[
                            Text(
                              widget.assessment!.trim(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Attachments
                  if ((widget.staffAttachments ?? const <String>[])
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _Section(
                      title: "Assessment Attachments",
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            (widget.staffAttachments ?? const <String>[])
                                .map((u) => _thumb(u, h: 80, w: 140))
                                .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Materials used (optional)
          if ((widget.materialsUsed ?? const <String>[]).isNotEmpty)
            _Section(
              title: "Materials Used",
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    (widget.materialsUsed ?? const <String>[])
                        .map((m) => Chip(label: Text(m)))
                        .toList(),
              ),
            ),

          // Admin Notes (uses _buildSectionCard with proper alignment)
          if ((widget.adminNote ?? '').trim().isNotEmpty)
            _Section(
              title: "Admin Notes",
              child: _buildSectionCard(
                backgroundColor: const Color(0xFFEFF5FF),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF005CE7),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.adminNote!.trim(),
                        style: const TextStyle(
                          color: Color(0xFF005CE7),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.55,
                        ),
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
}

// Announcement Details Screen ------------------------------------------

class AnnouncementDetails extends StatelessWidget {
  // ===== Basic Info =====
  final String id;
  final String? isActive; // "true"/"false"
  final String createdAt; // e.g. "2025-08-02"
  final String? updatedAt;

  // ===== Schedule =====
  final String scheduleStart;
  final String scheduleEnd;

  // ===== Classification / Audience =====
  final String? audience;
  final String announcementType;

  // ===== Location =====
  final String locationAffected;
  final String? buildingId;

  // ===== Content =====
  final String title;
  final String description;
  final String? attachment;

  // ===== Contact =====
  final String contactNumber;
  final String contactEmail;

  // ===== Read Status =====
  final bool isRead;
  final VoidCallback? onMarkAsRead;

  const AnnouncementDetails({
    super.key,
    required this.id,
    this.isActive,
    required this.createdAt,
    this.updatedAt,
    required this.scheduleStart,
    required this.scheduleEnd,
    this.audience,
    required this.announcementType,
    required this.locationAffected,
    this.buildingId,
    required this.title,
    required this.description,
    this.attachment,
    required this.contactNumber,
    required this.contactEmail,
    this.isRead = false,
    this.onMarkAsRead,
  });

  String get _statusLabel {
    final s = isActive?.trim().toLowerCase();
    if (s == null) return '';
    if (s == 'true' || s == 'active' || s == '1' || s == 'yes') return 'Active';
    if (s == 'false' || s == 'inactive' || s == '0' || s == 'no')
      return 'Inactive';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // Parse raw date safely
    final rawDate =
        (updatedAt != null && updatedAt!.trim().isNotEmpty)
            ? updatedAt!.trim()
            : createdAt.trim();

    final parsedDate = DateTime.tryParse(rawDate) ?? UiDateUtils.parse(rawDate);

    // Use timeAgo first, switch to fullDate after 48 hours
    final diffHours = DateTime.now().difference(parsedDate).inHours;
    final displayDate =
        (diffHours < 48)
            ? UiDateUtils.timeAgo(parsedDate)
            : UiDateUtils.fullDate(parsedDate);

    final hasAttachment = (attachment?.trim().isNotEmpty ?? false);
    final hasStatus = _statusLabel.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: ShapeDecoration(
        color: const Color(0xFFFEFEFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Header =====
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                      letterSpacing: -0.2,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (hasStatus)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF1F5),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFEAECF0)),
                    ),
                    child: Text(
                      _statusLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF344054),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // ID + Date
            Row(
              children: [
                Expanded(
                  child: Text(
                    id,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF475467),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  displayDate, // shows “3 hours ago” then “Aug 23, 2025”
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Classification Tag
            AnnouncementType(announcementType),
            const SizedBox(height: 16),

            // Main Sections
            _buildSectionCard(title: 'Description', content: description),
            _buildSectionCard(
              title: 'Location Affected',
              content: locationAffected,
            ),
  

            if (hasAttachment)
              _buildSectionCard(title: 'Attachment', content: attachment!),

            // Mark as Read Button
            if (!isRead && onMarkAsRead != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onMarkAsRead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005CE7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Mark as Read',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Already Read Indicator
            if (isRead)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Reuse your section card builder exactly
  Widget _buildSectionCard({
    required String title,
    required String content,
    Color backgroundColor = Colors.transparent,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFEAECF0), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF101828),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF475467),
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryDetailsScreen extends StatelessWidget {
  // ----- Item Details -----
  // Basic Information
  final String itemName; // Item name or Requested item name
  final String itemId; // Item ID (show in header if not empty)
  final String? dateAdded; // e.g., 'Automated'
  final String? classification; // reused by request item details if you like
  final String? department; // e.g., 'Civil/Carpentry' (for item details only)
  final String? status; // Inventory Request e.g., Pending or Approved

  // divider

  // Stock and Supplier Details
  // Stock (Item)
  final String? stockStatus; // 'In Stock' | 'Out of Stock' | 'Critical'
  final String? quantity; // '150 pcs'
  final String? reorderLevel; // '50 pcs'
  final String? unit; // 'pcs'

  // divider
  // Supplier (Information) (optional)
  final String? supplierName;
  final String? supplierNumber;
  final String? warrantyUntil; // 'DD / MM / YY'

  // divider
  // Item details (Request)
  final String? requestId;
  final String? requestQuantity;
  final String? dateNeeded;
  final String? reqLocation;
  final String? requestUnit;

  // Requestor Details
  final String? staffName;
  final String? staffDepartment;

  // divider
  // Notes
  final String? notes;

  const InventoryDetailsScreen({
    super.key,

    // header
    required this.itemName,
    required this.itemId,
    this.status,

    // item
    this.dateAdded,
    this.classification,
    this.department,

    // stock
    this.stockStatus,
    this.quantity,
    this.reorderLevel,
    this.unit,

    // supplier
    this.supplierName,
    this.supplierNumber,
    this.warrantyUntil,

    // request
    this.requestId,
    this.requestQuantity,
    this.dateNeeded,
    this.reqLocation,
    this.requestUnit,

    // requestor
    this.staffName,
    this.staffDepartment,

    // notes
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      color: Color(0xFF101828),
      fontSize: 20,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.2,
    );

    const idStyle = TextStyle(
      color: Color(0xFF475467),
      fontSize: 14,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.14,
      letterSpacing: -0.5,
    );

    // Prefer itemId; if empty, fall back to requestId
    final String headerId = _firstNonEmpty([itemId, requestId]) ?? '-';

    final List<Widget> sections = [];

    // ===== Basic Information =====
    final bool showBasicInfo = _any([dateAdded, classification, department]);
    if (showBasicInfo) {
      sections.add(
        _Section(
          title: 'Item Details',
          child: Column(
            children: [
              if (_isNotEmpty(dateAdded))
                KeyValueRow(label: 'Date Added', value: _kvText(dateAdded!)),
              if (_isNotEmpty(classification)) const SizedBox(height: 8),
              if (_isNotEmpty(classification))
                KeyValueRow(
                  label: 'Classification',
                  value: _kvText(classification!),
                ),
              if (_isNotEmpty(department)) const SizedBox(height: 8),
              if (_isNotEmpty(department))
                KeyValueRow(
                  label: 'Department',
                  value: DepartmentTag(department!),
                ),
            ],
          ),
        ),
      );
    }

    // ===== Stock =====
    final bool showStock = _any([stockStatus, quantity, reorderLevel, unit]);
    if (showStock) {
      sections.add(
        _Section(
          title: 'Stock Details',
          child: Column(
            children: [
              if (_isNotEmpty(stockStatus)) const SizedBox(height: 8),
              if (_isNotEmpty(stockStatus))
                KeyValueRow(
                  label: 'Stock Status',
                  value: StockStatusTag(stockStatus!),
                ),
              if (_isNotEmpty(quantity)) const SizedBox(height: 8),
              if (_isNotEmpty(quantity))
                KeyValueRow(label: 'Quantity', value: _kvText(quantity!)),
              if (_isNotEmpty(reorderLevel)) const SizedBox(height: 8),
              if (_isNotEmpty(reorderLevel))
                KeyValueRow(
                  label: 'Reorder Level',
                  value: _kvText(reorderLevel!),
                ),
              if (_isNotEmpty(unit)) const SizedBox(height: 8),
              if (_isNotEmpty(unit))
                KeyValueRow(label: 'Unit', value: _kvText(unit!)),
            ],
          ),
        ),
      );
    }

    // ===== Supplier =====
    final bool showSupplier = _any([
      supplierName,
      supplierNumber,
      warrantyUntil,
    ]);
    if (showSupplier) {
      sections.add(
        _Section(
          title: 'Supplier Information',
          child: Column(
            children: [
              if (_isNotEmpty(supplierName))
                KeyValueRow(
                  label: 'Supplier Name',
                  value: _kvText(supplierName!),
                ),
              if (_isNotEmpty(supplierNumber)) const SizedBox(height: 8),
              if (_isNotEmpty(supplierNumber))
                KeyValueRow(
                  label: 'Supplier Number',
                  value: _kvText(supplierNumber!),
                ),
              if (_isNotEmpty(warrantyUntil)) const SizedBox(height: 8),
              if (_isNotEmpty(warrantyUntil))
                KeyValueRow(
                  label: 'Warranty Until',
                  value: _kvText(warrantyUntil!),
                ),
            ],
          ),
        ),
      );
    }

    // ===== Request Item Details =====
    final bool showRequestItem = _any([
      requestId,
      requestQuantity,
      dateNeeded,
      reqLocation,
      requestUnit,
    ]);
    if (showRequestItem) {
      sections.add(
        _Section(
          title: 'Request Item Details',
          child: Column(
            children: [
              if (_isNotEmpty(requestId))
                KeyValueRow(label: 'Request ID', value: _kvText(requestId!)),
              if (_isNotEmpty(requestQuantity)) const SizedBox(height: 8),
              if (_isNotEmpty(requestQuantity))
                KeyValueRow(
                  label: 'Quantity',
                  value: _kvText(requestQuantity!),
                ),
              if (_isNotEmpty(requestUnit)) const SizedBox(height: 8),
              if (_isNotEmpty(requestUnit))
                KeyValueRow(label: 'Unit', value: _kvText(requestUnit!)),
              if (_isNotEmpty(dateNeeded)) const SizedBox(height: 8),
              if (_isNotEmpty(dateNeeded))
                KeyValueRow(label: 'Date Needed', value: _kvText(dateNeeded!)),
              if (_isNotEmpty(reqLocation)) const SizedBox(height: 8),
              if (_isNotEmpty(reqLocation))
                KeyValueRow(
                  label: 'Location / Unit',
                  value: _kvText(reqLocation!),
                ),
            ],
          ),
        ),
      );
    }

    // ===== Requestor Details =====
    final bool showRequestor = _any([staffName, staffDepartment]);
    if (showRequestor) {
      sections.add(
        _Section(
          title: 'Requestor Details',
          child: Column(
            children: [
              if (_isNotEmpty(staffName))
                KeyValueRow(label: 'Staff Name', value: _kvText(staffName!)),
              if (_isNotEmpty(staffDepartment)) const SizedBox(height: 8),
              if (_isNotEmpty(staffDepartment))
                KeyValueRow(
                  label: 'Department',
                  value: DepartmentTag(staffDepartment!),
                ),
            ],
          ),
        ),
      );
    }

    // ===== Notes =====
    if (_isNotEmpty(notes)) {
      sections.add(_SectionCard(
        title: 'Notes / Purpose',
        content: notes!,
        padding: const EdgeInsets.all(14),
        hideIfEmpty: false,
      ));
    }

    // Interleave with dividers
    final List<Widget> interspersed = [];
    for (int i = 0; i < sections.length; i++) {
      interspersed.add(sections[i]);
      if (i < sections.length - 1) interspersed.add(_divider());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(itemName, style: titleStyle)),
              if (_isNotEmpty(status)) ...[
                const SizedBox(width: 8),
                StatusTag(status: status!.trim()),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(headerId, style: idStyle),
          _divider(),
          // Body
          ...interspersed,
        ],
      ),
    );
  }

  // ---------- Helpers ----------
  static bool _isNotEmpty(String? s) => (s ?? '').trim().isNotEmpty;

  static bool _any(List<String?> vals) {
    for (final v in vals) {
      if (_isNotEmpty(v)) return true;
    }
    return false;
  }

  static String? _firstNonEmpty(List<String?> vals) {
    for (final v in vals) {
      if (_isNotEmpty(v)) return v!.trim();
    }
    return null;
  }

  static Widget _kvText(String text) => Text(
    text,
    textAlign: TextAlign.right,
    style: const TextStyle(
      color: Color(0xFF475467),
      fontSize: 13,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w400,
      height: 1.85,
    ),
  );

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 16),
    child: Divider(thickness: 1, color: Color(0xFFE4E7EC)),
  );
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
    this.maxWidth, // optional: cap overall width
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
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  12,
                                ),
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

// UI HELPERS -------------------------------

/// ------------------------------------------------------------
/// Responsive scale helper (baseline 375pt width, clamped)
/// ------------------------------------------------------------
double uiScale(BuildContext context) =>
    (MediaQuery.of(context).size.width / 375.0).clamp(0.85, 1.0);

/// ------------------------------------------------------------
/// Divider: full-bleed friendly with optional indents
/// ------------------------------------------------------------
Widget ffDivider({double indent = 0, double endIndent = 0}) => Divider(
  height: 1,
  thickness: 1,
  color: const Color(0xFFEAECF0),
  indent: indent,
  endIndent: endIndent,
);

/// ------------------------------------------------------------
/// Thumbnails + fallback
/// ------------------------------------------------------------
Widget brokenThumb({double h = 80, double w = 140, BorderRadius? radius}) =>
    Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: radius ?? BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Color(0xFF98A2B3)),
    );

Widget _thumb(
  String url, {
  double h = 80,
  double w = 140,
  BorderRadius? radius,
}) {
  final r = radius ?? BorderRadius.circular(8);
  final isNetwork = url.startsWith('http');
  final img =
      isNetwork
          ? Image.network(
            url,
            height: h,
            width: w,
            fit: BoxFit.cover,
            errorBuilder:
                (context, _, __) => brokenThumb(h: h, w: w, radius: r),
          )
          : Image.asset(
            url,
            height: h,
            width: w,
            fit: BoxFit.cover,
            errorBuilder:
                (context, _, __) => brokenThumb(h: h, w: w, radius: r),
          );
  return ClipRRect(borderRadius: r, child: img);
}

/// ------------------------------------------------------------
/// Key/Value row (responsive type + tighter mobile spacing)
/// ------------------------------------------------------------
class KeyValueRow extends StatelessWidget {
  final String label;
  final Widget value;
  final double labelWidth;

  const KeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 120,
  });

  /// Convenience: plain text value
  factory KeyValueRow.text({
    Key? key,
    required String label,
    required String valueText,
    double labelWidth = 120,
    TextStyle? valueStyle,
  }) {
    return KeyValueRow(
      key: key,
      label: label,
      labelWidth: labelWidth,
      value: _ValueText(valueText: valueText, valueStyle: valueStyle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);

    final labelStyle = TextStyle(
      fontFamily: 'Inter',
      color: const Color(0xFF475467),
      fontSize: 12 * s, // was 13
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    // Keep your API but scale effective width on smaller phones
    final effectiveLabelWidth = (labelWidth * s).clamp(96.0, 160.0);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * s),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: effectiveLabelWidth,
            child: Text(label, style: labelStyle),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DefaultTextStyle(
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: const Color(0xFF344054),
                  fontSize: 12.5 * s, // was 14
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
                child: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  final String valueText;
  final TextStyle? valueStyle;
  const _ValueText({required this.valueText, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return Text(
      valueText,
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
      style:
          (valueStyle ??
              TextStyle(
                fontFamily: 'Inter',
                color: const Color(0xFF344054),
                fontSize: 12.5 * s, // was 14
                fontWeight: FontWeight.w500,
                height: 1.3,
              )),
    );
  }
}



/// ------------------------------------------------------------
/// Section Title (already responsive; tightened weights/colors)
/// ------------------------------------------------------------
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700, // slightly bolder to anchor sections
        fontSize: 13.5 * s, // tuned size
        color: const Color(0xFF101828),
        letterSpacing: 0.1 * s,
        height: 1.2,
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Section shell (lightweight heading above a child)
/// ------------------------------------------------------------
class _Section extends StatelessWidget {
  final String? title;
  final Widget child;
  const _Section({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 13 * s,
              color: const Color(0xFF111827),
              height: 1.25,
            ),
          ),
          SizedBox(height: 10 * s),
        ],
        child,
      ],
    );
  }
}

/// ------------------------------------------------------------
/// Generic bordered card (mobile-friendly)
/// ------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String? title; // optional heading
  final String? content; // optional body text
  final Widget? child; // optional custom body
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final bool hideIfEmpty;

  const _SectionCard({
    this.title,
    this.content,
    this.child,
    required this.padding,
    this.margin,
    required this.hideIfEmpty,
  });

  double _scale(BuildContext context) => uiScale(context);

  EdgeInsets _scaledInsets(EdgeInsets insets, double s) => EdgeInsets.fromLTRB(
    insets.left * s,
    insets.top * s,
    insets.right * s,
    insets.bottom * s,
  );

  @override
  Widget build(BuildContext context) {
    final s = _scale(context);

    final trimmed = (content ?? '').trim();
    final shouldHide = hideIfEmpty && child == null && trimmed.isEmpty;
    if (shouldHide) return const SizedBox.shrink();

    final pad = _scaledInsets(padding, s);
    final mar = margin == null ? null : _scaledInsets(margin!, s);
    final radius = 10.0 * s;
    final gapTitleBody = 8.0 * s;
    final gapBodyChild = 8.0 * s;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: Container(
        margin: mar,
        padding: pad,
        decoration: ShapeDecoration(
          color: const Color(0xFFFAFAFB),
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(radius),
          ),
          shadows: [
            BoxShadow(
              color: const Color(0x14000000),
              blurRadius: 8 * s,
              offset: Offset(0, 2 * s),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((title ?? '').trim().isNotEmpty) ...[
              Text(
                title!.trim(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: const Color(0xFF101828),
                  fontSize: 13.5 * s,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2 * s,
                  height: 1.2,
                ),
              ),
              SizedBox(height: gapTitleBody),
            ],
            if (trimmed.isNotEmpty) ...[
              Text(
                trimmed,
                softWrap: true,
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: const Color(0xFF475467),
                  fontSize: 12.5 * s,
                  fontWeight: FontWeight.w400,
                  height: 1.55,
                  letterSpacing: 0.1 * s,
                ),
              ),
            ],
            if (child != null) ...[
              if (trimmed.isNotEmpty) SizedBox(height: gapBodyChild),
              child!,
            ],
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Avatar + Name + optional Department tag (compact)
/// ------------------------------------------------------------
class _AvatarNameBlock extends StatelessWidget {
  final String name;
  final String? departmentTag;
  final String? photoUrl;

  const _AvatarNameBlock({
    required this.name,
    this.departmentTag,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final s = uiScale(context);
    final hasPhoto = (photoUrl ?? '').trim().isNotEmpty;

    return Row(
      children: [
        // Avatar (photo or initials)
        Container(
          width: 40 * s,
          height: 40 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: 1.2 * s, color: Colors.white),
            color: hasPhoto ? Colors.transparent : const Color(0xFF9CA3AF),
            image:
                hasPhoto
                    ? DecorationImage(
                      image: NetworkImage(photoUrl!.trim()),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          alignment: Alignment.center,
          child:
              !hasPhoto
                  ? Text(
                    _initials(name),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15 * s,
                      height: 1.0,
                      letterSpacing: 0.2 * s,
                    ),
                  )
                  : null,
        ),

        SizedBox(width: 8 * s),

        // Name + DepartmentTag
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: const Color(0xFF101828),
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  letterSpacing: 0.1 * s,
                ),
              ),
              if ((departmentTag ?? '').isNotEmpty) ...[
                SizedBox(height: 4 * s),
                DepartmentTag(departmentTag!.trim()),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Extract initials from name (e.g. "Juan Tamad" → "JT")
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// ------------------------------------------------------------
/// Rich text body (notes + ordered instructions)
/// ------------------------------------------------------------
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
    final s = uiScale(context);

    final headingStyle = TextStyle(
      color: const Color(0xFF1D1D1F),
      fontSize: 12 * s,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w800,
      height: 1.2,
    );

    final textStyle = TextStyle(
      color: const Color(0xFF1D1D1F),
      fontSize: 12 * s,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      height: 1.45,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(notesHeading, style: headingStyle),
        SizedBox(height: 6 * s),
        Text(notes, style: textStyle),

        if (instructions.isNotEmpty) ...[
          SizedBox(height: 14 * s),
          Text(subHeading, style: headingStyle),
          SizedBox(height: 6 * s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(instructions.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8 * s),
                child: RichText(
                  text: TextSpan(
                    style: textStyle,
                    children: [
                      TextSpan(
                        text: '${i + 1}. ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12 * s,
                        ),
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
