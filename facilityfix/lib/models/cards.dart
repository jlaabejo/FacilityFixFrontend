import 'package:flutter/material.dart';

class WorkOrder {
  // Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt; // mirrors createdAt if null
  final String
  requestTypeTag; // e.g. "Concern Slip" | "Job Service" | "Work Order" | "Maintenance"
  final String? departmentTag; // e.g. "Plumbing"
  final String? resolutionType; // e.g. "job_service", "work_permit", "rejected"
  final String? priorityTag; // e.g. "High" | "Medium" | "Low"
  final String
  statusTag; // e.g. "Pending" | "Assigned" | "In Progress" | "Done"

  // Details
  final String title;
  final String? unitId; // e.g. "A-101"
  final String? location; // e.g. "Tower A - 5th Floor"

  // Staff
  final String? assignedStaff; // e.g. "Juan Dela Cruz"
  final String? staffDepartment; // e.g. "Electrical"
  final String? staffPhotoUrl; // local asset or network URL

  // Optional Assessment Fields (future-proof)
  final bool? hasInitialAssessment;
  final bool? hasCompletionAssessment;
  final String? completionRemarks;

  // Constructor
  const WorkOrder({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.requestTypeTag,
    this.departmentTag,
    this.resolutionType,
    this.priorityTag,
    required this.statusTag,
    required this.title,
    this.unitId,
    this.location,
    this.assignedStaff,
    this.staffDepartment,
    this.staffPhotoUrl,
    this.hasInitialAssessment,
    this.hasCompletionAssessment,
    this.completionRemarks,
  });
}

// Repair Card

class RepairCardVM {
  // Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt; // mirrors createdAt if null; not shown
  final String requestTypeTag; // e.g. "Concern Slip"
  final String? departmentTag;
  final String? resolutionType; // job_service, work_permit, rejected
  final String? priorityTag; // High | Medium | Low
  final String
  statusTag; // Pending | Scheduled | Assigned | In Progress | On Hold | Done

  // Details
  final String title;
  final String unitId;

  // Staff
  final String? assignedStaff;
  final String? staffDepartment;
  final String? staffPhotoUrl;

  // Constructor
  const RepairCardVM({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.requestTypeTag,
    this.departmentTag,
    this.resolutionType,
    this.priorityTag,
    required this.statusTag,
    required this.title,
    required this.unitId,
    this.assignedStaff,
    this.staffDepartment,
    this.staffPhotoUrl,
  });

  factory RepairCardVM.fromJson(Map<String, dynamic> json) {
    return RepairCardVM(
      id: json['id'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
      requestTypeTag: json['requestTypeTag'] ?? '',
      departmentTag: json['departmentTag'],
      resolutionType: json['resolutionType'],
      priorityTag: json['priorityTag'],
      statusTag: json['statusTag'] ?? 'Pending',
      title: json['title'] ?? '',
      unitId: json['unitId'] ?? '',
      assignedStaff: json['assignedStaff'],
      staffDepartment: json['staffDepartment'],
      staffPhotoUrl: json['staffPhotoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'requestTypeTag': requestTypeTag,
      'departmentTag': departmentTag,
      'resolutionType': resolutionType,
      'priorityTag': priorityTag,
      'statusTag': statusTag,
      'title': title,
      'unitId': unitId,
      'assignedStaff': assignedStaff,
      'staffDepartment': staffDepartment,
      'staffPhotoUrl': staffPhotoUrl,
    };
  }

  // Helpers

  DateTime get lastUpdated => updatedAt ?? createdAt;

  String get statusSummary {
    final resType = resolutionType != null ? ' (${resolutionType!})' : '';
    return '$requestTypeTag$resType';
  }

  @override
  String toString() {
    return 'RepairCard('
        'id: $id, title: $title, unitId: $unitId, '
        'status: $statusTag, priority: $priorityTag, '
        'assignedStaff: $assignedStaff)';
  }
}

// Maintenance ----------------------

class MaintenanceCardVM {
  // Basic Information
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt; // mirrors createdAt if null; not shown
  final String requestTypeTag; // e.g. "Concern Slip"
  final String? departmentTag;
  final String? resolutionType; // job_service, work_permit, rejected
  final String? priorityTag; // High | Medium | Low
  final String
  statusTag; // Pending | Scheduled | Assigned | In Progress | On Hold | Done

  // Details
  final String title;
  final String unitId;

  // Staff
  final String? assignedStaff;
  final String? staffDepartment;
  final String? staffPhotoUrl;

  // Constructor
  const MaintenanceCardVM({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.requestTypeTag,
    this.departmentTag,
    this.resolutionType,
    this.priorityTag,
    required this.statusTag,
    required this.title,
    required this.unitId,
    this.assignedStaff,
    this.staffDepartment,
    this.staffPhotoUrl,
  });

  factory MaintenanceCardVM.fromJson(Map<String, dynamic> json) {
    return MaintenanceCardVM(
      id: json['id'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'])
              : null,
      requestTypeTag: json['requestTypeTag'] ?? '',
      departmentTag: json['departmentTag'],
      resolutionType: json['resolutionType'],
      priorityTag: json['priorityTag'],
      statusTag: json['statusTag'] ?? 'Pending',
      title: json['title'] ?? '',
      unitId: json['unitId'] ?? '',
      assignedStaff: json['assignedStaff'],
      staffDepartment: json['staffDepartment'],
      staffPhotoUrl: json['staffPhotoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'requestTypeTag': requestTypeTag,
      'departmentTag': departmentTag,
      'resolutionType': resolutionType,
      'priorityTag': priorityTag,
      'statusTag': statusTag,
      'title': title,
      'unitId': unitId,
      'assignedStaff': assignedStaff,
      'staffDepartment': staffDepartment,
      'staffPhotoUrl': staffPhotoUrl,
    };
  }

  // Helpers

  DateTime get lastUpdated => updatedAt ?? createdAt;

  String get statusSummary {
    final resType = resolutionType != null ? ' (${resolutionType!})' : '';
    return '$requestTypeTag$resType';
  }

  @override
  String toString() {
    return 'MaintenanceCardVM('
        'id: $id, title: $title, unitId: $unitId, '
        'status: $statusTag, priority: $priorityTag, '
        'assignedStaff: $assignedStaff)';
  }
}
