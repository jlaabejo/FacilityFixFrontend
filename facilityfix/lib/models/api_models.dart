// AppRole Enum
enum AppRole {
  admin,
  staff,
  resident,
}

// Authentication Models
class AuthResponse {
  final String accessToken;
  final String tokenType;
  final UserResponse user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      user: UserResponse.fromJson(json['user']),
    );
  }
}

class UserRegistrationRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String birthDate;
  final String role;
  final String? buildingId;
  final String? unitId;
  final String? staffDepartment;

  UserRegistrationRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.birthDate,
    required this.role,
    this.buildingId,
    this.unitId,
    this.staffDepartment,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'birth_date': birthDate,
      'role': role,
      if (buildingId != null) 'building_id': buildingId,
      if (unitId != null) 'unit_id': unitId,
      if (staffDepartment != null) 'staff_department': staffDepartment,
    };
  }
}

// User Models
class UserResponse {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String birthDate;
  final String role;
  final String? buildingId;
  final String? unitId;
  final String? department;
  final String status;
  final DateTime createdAt;

  UserResponse({
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.birthDate,
    required this.role,
    this.buildingId,
    this.unitId,
    this.department,
    required this.status,
    required this.createdAt,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      userId: json['user_id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      birthDate: json['birth_date'],
      role: json['role'],
      buildingId: json['building_id'],
      unitId: json['unit_id'],
      department: json['department'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class UserUpdateRequest {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? birthDate;
  final String? department;
  final String? status;

  UserUpdateRequest({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.birthDate,
    this.department,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
    if (birthDate != null) data['birth_date'] = birthDate;
    if (department != null) data['department'] = department;
    if (status != null) data['status'] = status;
    return data;
  }
}

// Repair Request Models
class RepairRequestSubmission {
  final String title;
  final String description;
  final String location;
  final String priority;
  final String category;
  final List<String>? attachments;

  RepairRequestSubmission({
    required this.title,
    required this.description,
    required this.location,
    required this.priority,
    required this.category,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'priority': priority,
      'category': category,
      if (attachments != null) 'attachments': attachments,
    };
  }
}

class RepairRequestResponse {
  final String requestId;
  final String title;
  final String description;
  final String location;
  final String priority;
  final String category;
  final String status;
  final String reportedBy;
  final String? assignedTo;
  final List<String>? attachments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RepairRequestResponse({
    required this.requestId,
    required this.title,
    required this.description,
    required this.location,
    required this.priority,
    required this.category,
    required this.status,
    required this.reportedBy,
    this.assignedTo,
    this.attachments,
    required this.createdAt,
    this.updatedAt,
  });

  factory RepairRequestResponse.fromJson(Map<String, dynamic> json) {
    return RepairRequestResponse(
      requestId: json['request_id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      priority: json['priority'],
      category: json['category'],
      status: json['status'],
      reportedBy: json['reported_by'],
      assignedTo: json['assigned_to'],
      attachments: json['attachments']?.cast<String>(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

// Work Order Models
class WorkOrderCreation {
  final String requestId;
  final String title;
  final String description;
  final String priority;
  final String? assignedTo;
  final DateTime? scheduledDate;

  WorkOrderCreation({
    required this.requestId,
    required this.title,
    required this.description,
    required this.priority,
    this.assignedTo,
    this.scheduledDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'title': title,
      'description': description,
      'priority': priority,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (scheduledDate != null)
        'scheduled_date': scheduledDate!.toIso8601String(),
    };
  }
}

class WorkOrderResponse {
  final String workOrderId;
  final String requestId;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? assignedTo;
  final DateTime? scheduledDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  WorkOrderResponse({
    required this.workOrderId,
    required this.requestId,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assignedTo,
    this.scheduledDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkOrderResponse.fromJson(Map<String, dynamic> json) {
    return WorkOrderResponse(
      workOrderId: json['work_order_id'],
      requestId: json['request_id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      status: json['status'],
      assignedTo: json['assigned_to'],
      scheduledDate: json['scheduled_date'] != null
          ? DateTime.parse(json['scheduled_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

// Announcement Models
class AnnouncementResponse {
  final String? id;
  final String title;
  final String description;
  final String announcementType;
  final String? attachment;
  final String audience;
  final String locationAffected;
  final String buildingId;
  final bool isActive;
  final DateTime? scheduleStart;
  final DateTime? scheduleEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? contactNumber;
  final String? contactEmail;

  AnnouncementResponse({
    this.id,
    required this.title,
    required this.description,
    required this.announcementType,
    this.attachment,
    required this.audience,
    required this.locationAffected,
    required this.buildingId,
    required this.isActive,
    this.scheduleStart,
    this.scheduleEnd,
    this.createdAt,
    this.updatedAt,
    this.contactNumber,
    this.contactEmail,
  });

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    return AnnouncementResponse(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      announcementType: json['announcement_type'],
      attachment: json['attachment'],
      audience: json['audience'],
      locationAffected: json['location_affected'],
      buildingId: json['building_id'],
      isActive: json['is_active'],
      scheduleStart: json['schedule_start'] != null
          ? DateTime.parse(json['schedule_start'])
          : null,
      scheduleEnd: json['schedule_end'] != null
          ? DateTime.parse(json['schedule_end'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      contactNumber: json['contact_number'],
      contactEmail: json['contact_email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'announcement_type': announcementType,
      'attachment': attachment,
      'audience': audience,
      'location_affected': locationAffected,
      'building_id': buildingId,
      'is_active': isActive,
      'schedule_start': scheduleStart?.toIso8601String(),
      'schedule_end': scheduleEnd?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'contact_number': contactNumber,
      'contact_email': contactEmail,
    };
  }
}

class CreateAnnouncementRequest {
  final String title;
  final String audience; // tenant | staff | all
  final String announcementType; // e.g., General Announcement
  final String locationAffected; // e.g., Lobby, Building A
  final String buildingId; // must match backend's building_id
  final String? description;
  final String? attachment;
  final bool isActive;
  final DateTime? scheduleStart;
  final DateTime? scheduleEnd;
  final String? contactNumber;
  final String? contactEmail;

  CreateAnnouncementRequest({
    required this.title,
    required this.audience,
    required this.announcementType,
    required this.locationAffected,
    required this.buildingId,
    this.description,
    this.attachment,
    this.isActive = true,
    this.scheduleStart,
    this.scheduleEnd,
    this.contactNumber,
    this.contactEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'audience': audience,
      'announcement_type': announcementType,
      'location_affected': locationAffected,
      'building_id': buildingId,
      'description': description,
      'attachment': attachment,
      'is_active': isActive,
      'schedule_start': scheduleStart?.toIso8601String(),
      'schedule_end': scheduleEnd?.toIso8601String(),
      'contact_number': contactNumber,
      'contact_email': contactEmail,
      // backend always sends notifications on create
    };
  }
}

class UpdateAnnouncementRequest {
  final String? title;
  final String? audience;
  final String? announcementType;
  final String? locationAffected;
  final String? buildingId;
  final String? description;
  final String? attachment;
  final bool? isActive;
  final DateTime? scheduleStart;
  final DateTime? scheduleEnd;
  final String? contactNumber;
  final String? contactEmail;

  UpdateAnnouncementRequest({
    this.title,
    this.audience,
    this.announcementType,
    this.locationAffected,
    this.buildingId,
    this.description,
    this.attachment,
    this.isActive,
    this.scheduleStart,
    this.scheduleEnd,
    this.contactNumber,
    this.contactEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      if (title != null) 'title': title,
      if (audience != null) 'audience': audience,
      if (announcementType != null) 'announcement_type': announcementType,
      if (locationAffected != null) 'location_affected': locationAffected,
      if (buildingId != null) 'building_id': buildingId,
      if (description != null) 'description': description,
      if (attachment != null) 'attachment': attachment,
      if (isActive != null) 'is_active': isActive,
      if (scheduleStart != null)
        'schedule_start': scheduleStart!.toIso8601String(),
      if (scheduleEnd != null)
        'schedule_end': scheduleEnd!.toIso8601String(),
      if (contactNumber != null) 'contact_number': contactNumber,
      if (contactEmail != null) 'contact_email': contactEmail,
      // notify_changes is enforced server-side
    };
  }
}

class AnnouncementListResponse {
  final List<AnnouncementResponse> announcements;
  final int totalCount;
  final String buildingId;
  final String audienceFilter;

  AnnouncementListResponse({
    required this.announcements,
    required this.totalCount,
    required this.buildingId,
    required this.audienceFilter,
  });

  factory AnnouncementListResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['announcements'] as List<dynamic>? ?? [])
        .map((e) => AnnouncementResponse.fromJson(
            e as Map<String, dynamic>))
        .toList();
    return AnnouncementListResponse(
      announcements: items,
      totalCount: json['total_count'] ?? items.length,
      buildingId: json['building_id'] ?? '',
      audienceFilter: json['audience_filter'] ?? 'all',
    );
  }
}