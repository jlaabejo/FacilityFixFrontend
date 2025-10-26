class ConcernSlip {
  // Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? departmentTag;
  final String requestTypeTag;
  final String? priority;       // High | Medium | Low
  final String statusTag;       // Pending | Scheduled | Assigned | In Progress | On Hold | Done
  final String? resolutionType; // job_service, work_permit, rejected

  // Tenant / Requester
  final String requestedBy;
  final String unitId;
  final String? scheduleAvailability;

  // Request Details
  final String title;
  final String description;
  final List<String>? attachments;

  // Staff
  final String? assignedStaff;
  final String? staffDepartment;
  final String? assignedPhotoUrl;

  final DateTime? assessedAt;
  final String? assessment;
  final List<String>? staffAttachments;

  ConcernSlip({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.departmentTag,
    this.requestTypeTag ='Concern Slip',
    this.priority,
    required this.statusTag,
    this.resolutionType,
    required this.requestedBy,
    required this.unitId,
    this.scheduleAvailability,
    required this.title,
    required this.description,
    this.attachments,
    this.assignedStaff,
    this.staffDepartment,
    this.assignedPhotoUrl,
    this.assessedAt,
    this.assessment,
    this.staffAttachments,
  });

  factory ConcernSlip.fromJson(Map<String, dynamic> json) {
    // Handle both field name conventions
    final statusField = json['status'] ?? json['status_tag'];
    final categoryField = json['category'] ?? json['department_tag'];
    
    return ConcernSlip(
      id: json['id'] ?? json['formatted_id'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? json['submitted_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? ''),
      departmentTag: categoryField,
      requestTypeTag: json['request_type'] ?? 'Concern Slip',
      priority: json['priority'],
      statusTag: statusField ?? 'Pending',
      resolutionType: json['resolution_type'],
      requestedBy: json['requested_by'] ?? '',
      unitId: json['unit_id'] ?? '',
      scheduleAvailability: json['schedule_availability'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      attachments: (json['attachments'] as List?)?.map((e) => e.toString()).toList(),
      assignedStaff: json['assigned_staff'],
      staffDepartment: json['staff_department'],
      assignedPhotoUrl: json['assigned_photo_url'],
      assessedAt: DateTime.tryParse(json['assessed_at'] ?? ''),
      assessment: json['assessment'],
      staffAttachments: (json['staff_attachments'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'department_tag': departmentTag,
    'request_type': requestTypeTag,
    'priority': priority,
    'status_tag': statusTag,
    'resolution_type': resolutionType,
    'requested_by': requestedBy,
    'unit_id': unitId,
    'schedule_availability': scheduleAvailability,
    'title': title,
    'description': description,
    'attachments': attachments,
    'assigned_staff': assignedStaff,
    'staff_department': staffDepartment,
    'assigned_photo_url': assignedPhotoUrl,
    'assessed_at': assessedAt?.toIso8601String(),
    'assessment': assessment,
    'staff_attachments': staffAttachments,
  };
}


// JOB SERVICE
// ===== JOB SERVICE (single model for card + details) =========================
class JobService {
  // Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String requestTypeTag;     // "Job Service"
  final String? departmentTag;
  final String? priority;       // High | Medium | Low
  final String statusTag;       // Pending | Scheduled | Assigned | In Progress | On Hold | Done
  final String? resolutionType; // job_service | work_permit | rejected

  // Details
  final String title;
  final String unitId;

  // Requester / linkage (optional but useful in details)
  final String? requestedBy;
  final String? requestedByName;
  final String? requestedByEmail;
  final String? concernSlipId;
  final String? scheduleAvailability; // raw string or iso
  final String? additionalNotes;

  // Staff
  final String? assignedStaff;
  final String? staffDepartment;
  final String? assignedPhotoUrl;

  // Documentation
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? assessedAt;
  final String? assessment;
  final List<String>? attachments;      // work-order/request attachments
  final List<String>? staffAttachments; // staff-side docs

  // Tracking
  final List<String>? materialsUsed;

  JobService({
    // Basic
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.requestTypeTag = 'Job Service',
    this.departmentTag,
    this.priority,
    required this.statusTag,
    this.resolutionType,

    // Details
    required this.title,
    required this.unitId,

    // Requester / Linkage
    this.requestedBy,
    this.requestedByName,
    this.requestedByEmail,
    this.concernSlipId,
    this.scheduleAvailability,
    this.additionalNotes,

    // Staff
    this.assignedStaff,
    this.staffDepartment,
    this.assignedPhotoUrl,

    // Documentation
    this.startedAt,
    this.completedAt,
    this.assessedAt,
    this.assessment,
    this.attachments,
    this.staffAttachments,

    // Tracking
    this.materialsUsed,
  });

  factory JobService.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic x) => x == null ? null : DateTime.tryParse(x.toString());
    List<String>? _list(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList();

    // Handle both field name conventions
    final statusField = json['status'] ?? json['status_tag'];
    final categoryField = json['category'] ?? json['department_tag'];

    return JobService(
      id: json['id'] ?? json['formatted_id'] ?? '',
      createdAt: _dt(json['created_at'] ?? json['submitted_at']) ?? DateTime.now(),
      updatedAt: _dt(json['updated_at']),
      requestTypeTag: json['request_type'] ?? 'Job Service',
      departmentTag: categoryField,
      priority: json['priority'],
      statusTag: statusField ?? 'Pending',
      resolutionType: json['resolution_type'],
      title: json['title'] ?? '',
      unitId: json['unit_id'] ?? '',

      requestedBy: json['requested_by'],
      requestedByName: json['requested_by_name'],
      requestedByEmail: json['requested_by_email'],
      concernSlipId: json['concern_slip_id'],
      scheduleAvailability: json['schedule_availability'],
      additionalNotes: json['additional_notes'],

      assignedStaff: json['assigned_staff'],
      staffDepartment: json['staff_department'],
      assignedPhotoUrl: json['assigned_photo_url'],

      startedAt: _dt(json['started_at'] ?? json['actual_start_date']),
      completedAt: _dt(json['completed_at'] ?? json['actual_completion_date']),
      assessedAt: _dt(json['assessed_at']),
      assessment: json['assessment'],
      attachments: _list(json['attachments']),
      staffAttachments: _list(json['staff_attachments']),

      materialsUsed: _list(json['materials_used']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'request_type': requestTypeTag,
    'department_tag': departmentTag,
    'priority': priority,
    'status_tag': statusTag,
    'resolution_type': resolutionType,
    'title': title,
    'unit_id': unitId,

    'requested_by': requestedBy,
    'concern_slip_id': concernSlipId,
    'schedule_availability': scheduleAvailability,
    'additional_notes': additionalNotes,

    'assigned_staff': assignedStaff,
    'staff_department': staffDepartment,
    'assigned_photo_url': assignedPhotoUrl,

    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'assessed_at': assessedAt?.toIso8601String(),
    'assessment': assessment,
    'attachments': attachments,
    'staff_attachments': staffAttachments,

    'materials_used': materialsUsed,
  };
}


// ===== WORK ORDER  ===================================
class WorkOrderPermit {
  // Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String requestTypeTag;     // "Work Order"
  final String? departmentTag;
  final String? priority;       // High | Medium | Low
  final String statusTag;       // Pending | Scheduled | Assigned | In Progress | On Hold | Done
  final String? resolutionType; // job_service | work_permit | rejected

  // Details
  final String title;
  final String unitId;

  // Staff (for header/card + assigned)
  final String? assignedStaff;
  final String? staffDepartment;
  final String? assignedPhotoUrl;

  // Linkage / requester
  final String? concernSlipId;     // links back to slip
  final String? requestedBy;
  final String? requestedByName;   // Full name of requester

  // Permit Specific Details
  final String contractorName;     // required
  final String contractorNumber;   // required
  final String? contractorCompany;

  // Work Specifics
  final DateTime workScheduleFrom; // required
  final DateTime workScheduleTo;   // required
  final String? entryEquipments;

  // Approval tracking
  final String? approvedBy;
  final DateTime? approvalDate;
  final String? denialReason;
  final String? adminNotes;
  final String? completionNotes;

  // Attachments (optional)
  final List<String>? attachments;
  final List<String>? staffAttachments;

  WorkOrderPermit({
    // Basic
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.requestTypeTag = 'Work Order',
    this.departmentTag,
    this.priority,
    required this.statusTag,
    this.resolutionType,

    // Details
    required this.title,
    required this.unitId,

    // Staff
    this.assignedStaff,
    this.staffDepartment,
    this.assignedPhotoUrl,

    // Linkage / requester
    this.concernSlipId,
    this.requestedBy,
    this.requestedByName,

    // Permit specifics
    required this.contractorName,
    required this.contractorNumber,
    this.contractorCompany,

    // Work specifics
    required this.workScheduleFrom,
    required this.workScheduleTo,
    this.entryEquipments,

    // Approval
    this.approvedBy,
    this.approvalDate,
    this.denialReason,
    this.adminNotes,
    this.completionNotes,

    // Attachments
    this.attachments,
    this.staffAttachments,
  });

  factory WorkOrderPermit.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) {
      if (v == null) return null;

      // Try parsing ISO format first
      var parsed = DateTime.tryParse(v.toString());
      if (parsed != null) return parsed;

      // Try parsing human-readable format like "Oct 15, 2025 4:10 AM"
      try {
        // Common date formats
        final formats = [
          RegExp(r'^([A-Za-z]{3}) (\d+), (\d{4}) (\d+):(\d+) ([AP]M)$'),
        ];

        final str = v.toString().trim();
        for (var format in formats) {
          final match = format.firstMatch(str);
          if (match != null) {
            // Parse the matched groups
            final monthStr = match.group(1)!;
            final day = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            var hour = int.parse(match.group(4)!);
            final minute = int.parse(match.group(5)!);
            final ampm = match.group(6)!;

            // Convert month string to number
            const months = {
              'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
              'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
            };
            final month = months[monthStr] ?? 1;

            // Convert to 24-hour format
            if (ampm == 'PM' && hour != 12) hour += 12;
            if (ampm == 'AM' && hour == 12) hour = 0;

            return DateTime(year, month, day, hour, minute);
          }
        }
      } catch (e) {
        print('[WorkOrderPermit] Error parsing date: $e');
      }

      return null;
    }

    List<String>? _list(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList();

    // Handle both field name conventions from different API endpoints
    // Extract contractor info from contractors array if present
    String contractorName = json['contractor_name'] ?? '';
    String contractorContact = json['contractor_contact'] ?? json['contractor_number'] ?? '';
    String? contractorCompany = json['contractor_company'];

    // Check if contractors array exists and extract first contractor
    if (json['contractors'] != null && json['contractors'] is List && (json['contractors'] as List).isNotEmpty) {
      final firstContractor = (json['contractors'] as List)[0];
      if (firstContractor is Map) {
        contractorName = firstContractor['name']?.toString() ?? contractorName;
        contractorContact = firstContractor['contact']?.toString() ?? contractorContact;
        contractorCompany = firstContractor['company']?.toString() ?? contractorCompany;
      }
    }

    final validFrom = json['valid_from'] ?? json['work_schedule_from'];
    final validTo = json['valid_to'] ?? json['work_schedule_to'];
    final entryReqs = json['entry_requirements'] ?? json['entry_equipments'];
    final statusField = json['status'] ?? json['status_tag'];
    final categoryField = json['category'] ?? json['department_tag'];

    return WorkOrderPermit(
      id: json['id'] ?? json['formatted_id'] ?? '',
      createdAt: _dt(json['created_at'] ?? json['submitted_at']) ?? DateTime.now(),
      updatedAt: _dt(json['updated_at']),
      requestTypeTag: json['request_type'] ?? 'Work Order',
      departmentTag: categoryField,
      priority: json['priority'],
      statusTag: statusField ?? 'Pending',
      resolutionType: json['resolution_type'],
      title: json['title'] ?? '',
      unitId: json['unit_id'] ?? json['location'] ?? '',

      assignedStaff: json['assigned_staff'],
      staffDepartment: json['staff_department'],
      assignedPhotoUrl: json['assigned_photo_url'],

      concernSlipId: json['concern_slip_id'],
      requestedBy: json['requested_by'],
      requestedByName: json['requested_by_name'],

      contractorName: contractorName,
      contractorNumber: contractorContact,
      contractorCompany: contractorCompany,

      workScheduleFrom: _dt(validFrom) ?? DateTime.now(),
      workScheduleTo: _dt(validTo) ?? DateTime.now(),
      entryEquipments: entryReqs,

      approvedBy: json['approved_by'],
      approvalDate: _dt(json['approval_date']),
      denialReason: json['denial_reason'],
      adminNotes: json['admin_notes'],
      completionNotes: json['completion_notes'],

      attachments: _list(json['attachments']),
      staffAttachments: _list(json['staff_attachments']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'request_type': requestTypeTag,
    'department_tag': departmentTag,
    'priority': priority,
    'status_tag': statusTag,
    'resolution_type': resolutionType,
    'title': title,
    'unit_id': unitId,

    'assigned_staff': assignedStaff,
    'staff_department': staffDepartment,
    'assigned_photo_url': assignedPhotoUrl,

    'concern_slip_id': concernSlipId,
    'requested_by': requestedBy,
    'requested_by_name': requestedByName,

    'contractor_name': contractorName,
    'contractor_number': contractorNumber,
    'contractor_company': contractorCompany,

    'work_schedule_from': workScheduleFrom.toIso8601String(),
    'work_schedule_to': workScheduleTo.toIso8601String(),
    'entry_equipments': entryEquipments,

    'approved_by': approvedBy,
    'approval_date': approvalDate?.toIso8601String(),
    'denial_reason': denialReason,
    'admin_notes': adminNotes,
    'completion_notes': completionNotes,

    'attachments': attachments,
    'staff_attachments': staffAttachments,
  };
}


// MAINTENANCE ========================================

class Maintenance {
  // Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? departmentTag;
  final String requestTypeTag;     // "Maintenance"
  final String? priority;       // High | Medium | Low
  final String statusTag;       // Pending | Scheduled | Assigned | In Progress | On Hold | Done
  final String? resolutionType; // job_service, work_permit, rejected

  // Requester
  final String requestedBy;     // admin name

  // Request Details
  final String location;
  final String title;
  final String description;
  final String checklist;           // NOTE: single string (can be \n separated)
  final List<String>? attachments;
  final String? adminNote;

  // Staff
  final String? assignedStaff;
  final String? staffDepartment;
  final String? assignedPhotoUrl;

  final DateTime? assessedAt;       // staff assessment timestamp
  final String? assessment;         // staff assessment text
  final List<String>? staffAttachments;

  Maintenance({
    // Basic
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.departmentTag,
    this.requestTypeTag = 'Maintenance',
    this.priority,
    required this.statusTag,
    this.resolutionType,

    // Requester
    required this.requestedBy,

    // Details
    required this.location,
    required this.title,
    required this.description,
    required this.checklist,
    this.attachments,
    this.adminNote,

    // Staff
    this.assignedStaff,
    this.staffDepartment,
    this.assignedPhotoUrl,
    this.assessedAt,
    this.assessment,
    this.staffAttachments,
  });

  factory Maintenance.fromJson(Map<String, dynamic> json) {
    DateTime? _dt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    List<String>? _list(dynamic v) =>
        (v as List?)?.map((e) => e.toString()).toList();

    // Handle both field name conventions
    final statusField = json['status'] ?? json['status_tag'];
    final categoryField = json['category'] ?? json['department_tag'];

    return Maintenance(
      id: json['id'] ?? json['formatted_id'] ?? '',
      createdAt: _dt(json['created_at'] ?? json['submitted_at']) ?? DateTime.now(),
      updatedAt: _dt(json['updated_at']),
      departmentTag: categoryField,
      requestTypeTag: json['request_type'] ?? 'Maintenance',
      priority: json['priority'],
      statusTag: statusField ?? 'Pending',
      resolutionType: json['resolution_type'],

      requestedBy: json['requested_by'] ?? '',

      location: json['location'] ?? (json['unit_id'] ?? ''),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      checklist: json['checklist']?.toString() ?? '',
      attachments: _list(json['attachments']),
      adminNote: json['admin_note'] ?? json['admin_notes'],

      assignedStaff: json['assigned_staff'],
      staffDepartment: json['staff_department'],
      assignedPhotoUrl: json['assigned_photo_url'],

      assessedAt: _dt(json['assessed_at']),
      assessment: json['assessment'],
      staffAttachments: _list(json['staff_attachments']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'department_tag': departmentTag,
    'request_type': requestTypeTag,
    'priority': priority,
    'status_tag': statusTag,
    'resolution_type': resolutionType,

    'requested_by': requestedBy,

    'location': location,
    'title': title,
    'description': description,
    'checklist': checklist,
    'attachments': attachments,
    'admin_note': adminNote,

    'assigned_staff': assignedStaff,
    'staff_department': staffDepartment,
    'assigned_photo_url': assignedPhotoUrl,

    'assessed_at': assessedAt?.toIso8601String(),
    'assessment': assessment,
    'staff_attachments': staffAttachments,
  };
}

// WorkOrderDetails -------------------------------

class WorkOrderDetails {
  // Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String requestTypeTag;      // "Work Order", "Job Service", or "Maintenance"
  final String? departmentTag;
  final String? priority;           // High | Medium | Low
  final String statusTag;           // Pending | Scheduled | Assigned | In Progress | On Hold | Done
  final String? resolutionType;     // job_service | work_permit | rejected

  // Requester / Linkage
  final String? requestedBy;        // tenant or admin user ID (e.g., T-0001, S-0002)
  final String? requestedByName;    // full name of requester
  final String? requestedByEmail;   // email of requester
  final String? concernSlipId;      // link to related concern slip
  final String? unitId;             // unit or location identifier
  final String? scheduleAvailability; // for scheduling availability

  // Request Details
  final String title;
  final String? description;
  final String? location;           // optional: used for maintenance requests
  final String? checklist;          // maintenance checklist (string or \n separated)
  final String? additionalNotes;    // additional remarks or admin notes

  // Staff (assigned info)
  final String? assignedStaff;
  final String? staffDepartment;
  final String? assignedPhotoUrl;

  // Permit / Contractor Info (for Work Permits)
  final String? contractorName;
  final String? contractorNumber;
  final String? contractorCompany;

  // Work Schedule
  final DateTime? workScheduleFrom;
  final DateTime? workScheduleTo;
  final String? entryEquipments;

  // Approval & Admin Tracking
  final String? approvedBy;
  final DateTime? approvalDate;
  final String? denialReason;
  final String? adminNotes;
  final String? completionNotes;

  // Documentation & Assessment
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? assessedAt;
  final String? assessment;

  // Attachments
  final List<String>? attachments;       // request attachments (tenant/admin)
  final List<String>? staffAttachments;  // staff-side documentation
  final List<String>? materialsUsed;     // materials or items used for work

  const WorkOrderDetails({
    // Basic Info
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.requestTypeTag,
    this.departmentTag,
    this.priority,
    required this.statusTag,
    this.resolutionType,

    // Requester / Linkage
    this.requestedBy,
    this.requestedByName,
    this.requestedByEmail,
    this.concernSlipId,
    this.unitId,
    this.scheduleAvailability,

    // Request Details
    required this.title,
    this.description,
    this.location,
    this.checklist,
    this.additionalNotes,

    // Staff
    this.assignedStaff,
    this.staffDepartment,
    this.assignedPhotoUrl,

    // Contractor / Permit Info
    this.contractorName,
    this.contractorNumber,
    this.contractorCompany,

    // Work Schedule
    this.workScheduleFrom,
    this.workScheduleTo,
    this.entryEquipments,

    // Approval / Admin
    this.approvedBy,
    this.approvalDate,
    this.denialReason,
    this.adminNotes,
    this.completionNotes,

    // Documentation & Tracking
    this.startedAt,
    this.completedAt,
    this.assessedAt,
    this.assessment,

    // Attachments
    this.attachments,
    this.staffAttachments,
    this.materialsUsed,
  });
}
