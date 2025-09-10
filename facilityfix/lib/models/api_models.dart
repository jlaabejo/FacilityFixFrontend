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
  final String role;
  final String? buildingId;
  final String? unitId;
  final String? department;

  UserRegistrationRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.role,
    this.buildingId,
    this.unitId,
    this.department,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'role': role,
      if (buildingId != null) 'building_id': buildingId,
      if (unitId != null) 'unit_id': unitId,
      if (department != null) 'department': department,
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
  final String? department;
  final String? status;

  UserUpdateRequest({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.department,
    this.status,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (phoneNumber != null) data['phone_number'] = phoneNumber;
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
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
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
      if (scheduledDate != null) 'scheduled_date': scheduledDate!.toIso8601String(),
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
      scheduledDate: json['scheduled_date'] != null ? DateTime.parse(json['scheduled_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}
