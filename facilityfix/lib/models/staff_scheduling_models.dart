// Staff Scheduling Models for Flutter

enum AvailabilityStatus { available, unavailable, onBreak, busy, offDuty }

enum DayOffStatus { pending, approved, rejected }

enum WorkloadLevel { low, medium, high, overloaded }

// Extensions for enum string conversion
extension AvailabilityStatusExtension on AvailabilityStatus {
  String get value {
    switch (this) {
      case AvailabilityStatus.available:
        return 'available';
      case AvailabilityStatus.unavailable:
        return 'unavailable';
      case AvailabilityStatus.onBreak:
        return 'on_break';
      case AvailabilityStatus.busy:
        return 'busy';
      case AvailabilityStatus.offDuty:
        return 'off_duty';
    }
  }

  static AvailabilityStatus fromString(String status) {
    switch (status) {
      case 'available':
        return AvailabilityStatus.available;
      case 'unavailable':
        return AvailabilityStatus.unavailable;
      case 'on_break':
        return AvailabilityStatus.onBreak;
      case 'busy':
        return AvailabilityStatus.busy;
      case 'off_duty':
        return AvailabilityStatus.offDuty;
      default:
        return AvailabilityStatus.available;
    }
  }

  String get displayName {
    switch (this) {
      case AvailabilityStatus.available:
        return 'Available';
      case AvailabilityStatus.unavailable:
        return 'Unavailable';
      case AvailabilityStatus.onBreak:
        return 'On Break';
      case AvailabilityStatus.busy:
        return 'Busy';
      case AvailabilityStatus.offDuty:
        return 'Off Duty';
    }
  }
}

extension DayOffStatusExtension on DayOffStatus {
  String get value {
    switch (this) {
      case DayOffStatus.pending:
        return 'pending';
      case DayOffStatus.approved:
        return 'approved';
      case DayOffStatus.rejected:
        return 'rejected';
    }
  }

  static DayOffStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return DayOffStatus.pending;
      case 'approved':
        return DayOffStatus.approved;
      case 'rejected':
        return DayOffStatus.rejected;
      default:
        return DayOffStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case DayOffStatus.pending:
        return 'Pending';
      case DayOffStatus.approved:
        return 'Approved';
      case DayOffStatus.rejected:
        return 'Rejected';
    }
  }
}

// Staff Availability Model
class StaffAvailability {
  final String? id;
  final String staffId;
  final String weekStartDate;
  final String weekEndDate;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  final String? mondayHours;
  final String? tuesdayHours;
  final String? wednesdayHours;
  final String? thursdayHours;
  final String? fridayHours;
  final String? saturdayHours;
  final String? sundayHours;
  final String status;
  final DateTime? submittedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StaffAvailability({
    this.id,
    required this.staffId,
    required this.weekStartDate,
    required this.weekEndDate,
    this.monday = true,
    this.tuesday = true,
    this.wednesday = true,
    this.thursday = true,
    this.friday = true,
    this.saturday = false,
    this.sunday = false,
    this.mondayHours,
    this.tuesdayHours,
    this.wednesdayHours,
    this.thursdayHours,
    this.fridayHours,
    this.saturdayHours,
    this.sundayHours,
    this.status = 'active',
    this.submittedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffAvailability.fromJson(Map<String, dynamic> json) {
    return StaffAvailability(
      id: json['id'],
      staffId: json['staff_id'],
      weekStartDate: json['week_start_date'],
      weekEndDate: json['week_end_date'],
      monday: json['monday'] ?? true,
      tuesday: json['tuesday'] ?? true,
      wednesday: json['wednesday'] ?? true,
      thursday: json['thursday'] ?? true,
      friday: json['friday'] ?? true,
      saturday: json['saturday'] ?? false,
      sunday: json['sunday'] ?? false,
      mondayHours: json['monday_hours'],
      tuesdayHours: json['tuesday_hours'],
      wednesdayHours: json['wednesday_hours'],
      thursdayHours: json['thursday_hours'],
      fridayHours: json['friday_hours'],
      saturdayHours: json['saturday_hours'],
      sundayHours: json['sunday_hours'],
      status: json['status'] ?? 'active',
      submittedAt:
          json['submitted_at'] != null
              ? DateTime.parse(json['submitted_at'])
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'week_start_date': weekStartDate,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
      if (mondayHours != null) 'monday_hours': mondayHours,
      if (tuesdayHours != null) 'tuesday_hours': tuesdayHours,
      if (wednesdayHours != null) 'wednesday_hours': wednesdayHours,
      if (thursdayHours != null) 'thursday_hours': thursdayHours,
      if (fridayHours != null) 'friday_hours': fridayHours,
      if (saturdayHours != null) 'saturday_hours': saturdayHours,
      if (sundayHours != null) 'sunday_hours': sundayHours,
    };
  }

  // Get availability for a specific day
  bool getAvailabilityForDay(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return monday;
      case 'tuesday':
        return tuesday;
      case 'wednesday':
        return wednesday;
      case 'thursday':
        return thursday;
      case 'friday':
        return friday;
      case 'saturday':
        return saturday;
      case 'sunday':
        return sunday;
      default:
        return false;
    }
  }

  // Count available days
  int get availableDaysCount {
    int count = 0;
    if (monday) count++;
    if (tuesday) count++;
    if (wednesday) count++;
    if (thursday) count++;
    if (friday) count++;
    if (saturday) count++;
    if (sunday) count++;
    return count;
  }
}

// Staff Real-time Status Model
class StaffRealTimeStatus {
  final String? id;
  final String staffId;
  final AvailabilityStatus currentStatus;
  final WorkloadLevel workloadLevel;
  final int activeTaskCount;
  final List<String> activeTaskIds;
  final String? currentLocation;
  final String? contactNumber;
  final DateTime? statusUpdatedAt;
  final DateTime? lastActivityAt;
  final DateTime? breakStartTime;
  final DateTime? dutyStartTime;
  final DateTime? dutyEndTime;
  final bool isScheduledOnDuty;
  final bool isCurrentlyAvailable;
  final bool autoAssignEligible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StaffRealTimeStatus({
    this.id,
    required this.staffId,
    this.currentStatus = AvailabilityStatus.available,
    this.workloadLevel = WorkloadLevel.low,
    this.activeTaskCount = 0,
    this.activeTaskIds = const [],
    this.currentLocation,
    this.contactNumber,
    this.statusUpdatedAt,
    this.lastActivityAt,
    this.breakStartTime,
    this.dutyStartTime,
    this.dutyEndTime,
    this.isScheduledOnDuty = false,
    this.isCurrentlyAvailable = true,
    this.autoAssignEligible = true,
    this.createdAt,
    this.updatedAt,
  });

  factory StaffRealTimeStatus.fromJson(Map<String, dynamic> json) {
    return StaffRealTimeStatus(
      id: json['id'],
      staffId: json['staff_id'],
      currentStatus: AvailabilityStatusExtension.fromString(
        json['current_status'] ?? 'available',
      ),
      workloadLevel: WorkloadLevel.values.firstWhere(
        (e) =>
            e.toString().split('.').last == (json['workload_level'] ?? 'low'),
        orElse: () => WorkloadLevel.low,
      ),
      activeTaskCount: json['active_task_count'] ?? 0,
      activeTaskIds: List<String>.from(json['active_task_ids'] ?? []),
      currentLocation: json['current_location'],
      contactNumber: json['contact_number'],
      statusUpdatedAt:
          json['status_updated_at'] != null
              ? DateTime.parse(json['status_updated_at'])
              : null,
      lastActivityAt:
          json['last_activity_at'] != null
              ? DateTime.parse(json['last_activity_at'])
              : null,
      breakStartTime:
          json['break_start_time'] != null
              ? DateTime.parse(json['break_start_time'])
              : null,
      dutyStartTime:
          json['duty_start_time'] != null
              ? DateTime.parse(json['duty_start_time'])
              : null,
      dutyEndTime:
          json['duty_end_time'] != null
              ? DateTime.parse(json['duty_end_time'])
              : null,
      isScheduledOnDuty: json['is_scheduled_on_duty'] ?? false,
      isCurrentlyAvailable: json['is_currently_available'] ?? true,
      autoAssignEligible: json['auto_assign_eligible'] ?? true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'current_status': currentStatus.value,
      'workload_level': workloadLevel.toString().split('.').last,
      'active_task_count': activeTaskCount,
      'active_task_ids': activeTaskIds,
      'current_location': currentLocation,
      'contact_number': contactNumber,
      'is_scheduled_on_duty': isScheduledOnDuty,
      'is_currently_available': isCurrentlyAvailable,
      'auto_assign_eligible': autoAssignEligible,
    };
  }
}

// Day Off Request Model
class DayOffRequest {
  final String? id;
  final String? formattedId;
  final String staffId;
  final DateTime requestDate;
  final String reason;
  final String? description;
  final String requestType;
  final DayOffStatus status;
  final DateTime requestedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final String? adminNotes;
  final bool affectsCriticalTasks;
  final String? replacementStaffId;
  final String? impactAssessment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DayOffRequest({
    this.id,
    this.formattedId,
    required this.staffId,
    required this.requestDate,
    required this.reason,
    this.description,
    this.requestType = 'day_off',
    this.status = DayOffStatus.pending,
    required this.requestedAt,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    this.adminNotes,
    this.affectsCriticalTasks = false,
    this.replacementStaffId,
    this.impactAssessment,
    this.createdAt,
    this.updatedAt,
  });

  factory DayOffRequest.fromJson(Map<String, dynamic> json) {
    return DayOffRequest(
      id: json['id'],
      formattedId: json['formatted_id'],
      staffId: json['staff_id'],
      requestDate: DateTime.parse(json['request_date']),
      reason: json['reason'],
      description: json['description'],
      requestType: json['request_type'] ?? 'day_off',
      status: DayOffStatusExtension.fromString(json['status'] ?? 'pending'),
      requestedAt: DateTime.parse(json['requested_at']),
      approvedBy: json['approved_by'],
      approvedAt:
          json['approved_at'] != null
              ? DateTime.parse(json['approved_at'])
              : null,
      rejectionReason: json['rejection_reason'],
      adminNotes: json['admin_notes'],
      affectsCriticalTasks: json['affects_critical_tasks'] ?? false,
      replacementStaffId: json['replacement_staff_id'],
      impactAssessment: json['impact_assessment'],
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'request_date': requestDate.toIso8601String().split('T')[0],
      'reason': reason,
      if (description != null) 'description': description,
      'request_type': requestType,
    };
  }

  // Helper method to get formatted date
  String get formattedRequestDate {
    return "${requestDate.year}-${requestDate.month.toString().padLeft(2, '0')}-${requestDate.day.toString().padLeft(2, '0')}";
  }

  // Helper method to get days ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(requestedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// Request Models
class WeeklyAvailabilityRequest {
  final String weekStartDate;
  final bool monday;
  final bool tuesday;
  final bool wednesday;
  final bool thursday;
  final bool friday;
  final bool saturday;
  final bool sunday;
  final String? mondayHours;
  final String? tuesdayHours;
  final String? wednesdayHours;
  final String? thursdayHours;
  final String? fridayHours;
  final String? saturdayHours;
  final String? sundayHours;

  WeeklyAvailabilityRequest({
    required this.weekStartDate,
    this.monday = true,
    this.tuesday = true,
    this.wednesday = true,
    this.thursday = true,
    this.friday = true,
    this.saturday = false,
    this.sunday = false,
    this.mondayHours,
    this.tuesdayHours,
    this.wednesdayHours,
    this.thursdayHours,
    this.fridayHours,
    this.saturdayHours,
    this.sundayHours,
  });

  Map<String, dynamic> toJson() {
    return {
      'week_start_date': weekStartDate,
      'monday': monday,
      'tuesday': tuesday,
      'wednesday': wednesday,
      'thursday': thursday,
      'friday': friday,
      'saturday': saturday,
      'sunday': sunday,
      if (mondayHours != null) 'monday_hours': mondayHours,
      if (tuesdayHours != null) 'tuesday_hours': tuesdayHours,
      if (wednesdayHours != null) 'wednesday_hours': wednesdayHours,
      if (thursdayHours != null) 'thursday_hours': thursdayHours,
      if (fridayHours != null) 'friday_hours': fridayHours,
      if (saturdayHours != null) 'saturday_hours': saturdayHours,
      if (sundayHours != null) 'sunday_hours': sundayHours,
    };
  }
}

class StatusUpdateRequest {
  final AvailabilityStatus status;
  final String? location;
  final String? notes;

  StatusUpdateRequest({required this.status, this.location, this.notes});

  Map<String, dynamic> toJson() {
    return {
      'status': status.value,
      if (location != null) 'location': location,
      if (notes != null) 'notes': notes,
    };
  }
}

class DayOffRequestSubmission {
  final String requestDate;
  final String reason;
  final String? description;
  final String requestType;

  DayOffRequestSubmission({
    required this.requestDate,
    required this.reason,
    this.description,
    this.requestType = 'day_off',
  });

  Map<String, dynamic> toJson() {
    return {
      'request_date': requestDate,
      'reason': reason,
      if (description != null) 'description': description,
      'request_type': requestType,
    };
  }
}

// Response Models
class StaffScheduleOverview {
  final int totalStaff;
  final int availableThisWeek;
  final int unavailableCount;
  final int pendingDayOffRequests;
  final Map<String, int> staffByStatus;
  final Map<String, int> staffByDepartment;
  final List<Map<String, dynamic>> weeklyAvailability;

  StaffScheduleOverview({
    required this.totalStaff,
    required this.availableThisWeek,
    required this.unavailableCount,
    required this.pendingDayOffRequests,
    required this.staffByStatus,
    required this.staffByDepartment,
    required this.weeklyAvailability,
  });

  factory StaffScheduleOverview.fromJson(Map<String, dynamic> json) {
    return StaffScheduleOverview(
      totalStaff: json['total_staff'] ?? 0,
      availableThisWeek: json['available_this_week'] ?? 0,
      unavailableCount: json['unavailable_count'] ?? 0,
      pendingDayOffRequests: json['pending_day_off_requests'] ?? 0,
      staffByStatus: Map<String, int>.from(json['staff_by_status'] ?? {}),
      staffByDepartment: Map<String, int>.from(
        json['staff_by_department'] ?? {},
      ),
      weeklyAvailability: List<Map<String, dynamic>>.from(
        json['weekly_availability'] ?? [],
      ),
    );
  }
}

class StaffMember {
  final String staffId;
  final String? userId;
  final String firstName;
  final String lastName;
  final String? email;
  final List<String> departments;
  final String? phoneNumber;
  final bool isAvailableToday;
  final String daysAvailableThisWeek;
  final String availabilityStatus;
  final AvailabilityStatus currentStatus;
  final WorkloadLevel workloadLevel;
  final int activeTaskCount;
  final String? currentLocation;
  final DateTime? lastActivity;
  final bool autoAssignEligible;
  final String overallStatus;

  StaffMember({
    required this.staffId,
    this.userId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.departments = const [],
    this.phoneNumber,
    this.isAvailableToday = true,
    this.daysAvailableThisWeek = '5/7',
    this.availabilityStatus = 'submitted',
    this.currentStatus = AvailabilityStatus.available,
    this.workloadLevel = WorkloadLevel.low,
    this.activeTaskCount = 0,
    this.currentLocation,
    this.lastActivity,
    this.autoAssignEligible = true,
    this.overallStatus = 'Available',
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      staffId: json['staff_id'],
      userId: json['user_id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      departments: List<String>.from(json['departments'] ?? []),
      phoneNumber: json['phone_number'],
      isAvailableToday: json['is_available_today'] ?? true,
      daysAvailableThisWeek: json['days_available_this_week'] ?? '5/7',
      availabilityStatus: json['availability_status'] ?? 'submitted',
      currentStatus: AvailabilityStatusExtension.fromString(
        json['current_status'] ?? 'available',
      ),
      workloadLevel: WorkloadLevel.values.firstWhere(
        (e) =>
            e.toString().split('.').last == (json['workload_level'] ?? 'low'),
        orElse: () => WorkloadLevel.low,
      ),
      activeTaskCount: json['active_task_count'] ?? 0,
      currentLocation: json['current_location'],
      lastActivity:
          json['last_activity'] != null
              ? DateTime.parse(json['last_activity'])
              : null,
      autoAssignEligible: json['auto_assign_eligible'] ?? true,
      overallStatus: json['overall_status'] ?? 'Available',
    );
  }

  String get fullName => '$firstName $lastName';

  String get departmentsString => departments.join(', ');

  String get statusColor {
    switch (currentStatus) {
      case AvailabilityStatus.available:
        return 'green';
      case AvailabilityStatus.busy:
        return 'orange';
      case AvailabilityStatus.onBreak:
        return 'blue';
      case AvailabilityStatus.unavailable:
      case AvailabilityStatus.offDuty:
        return 'red';
    }
  }

  String get workloadColor {
    switch (workloadLevel) {
      case WorkloadLevel.low:
        return 'green';
      case WorkloadLevel.medium:
        return 'yellow';
      case WorkloadLevel.high:
        return 'orange';
      case WorkloadLevel.overloaded:
        return 'red';
    }
  }
}
