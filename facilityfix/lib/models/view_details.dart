// Announcement Model

class Announcement {
  final String id;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String scheduleStart;
  final String scheduleEnd;

  final String audience;
  final String announcementType;
  final String locationAffected;
  final String buildingId;

  final String title;
  final String description;
  final String attachment;

  final String contactNumber;
  final String contactEmail;

  Announcement({
    required this.id,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.scheduleStart,
    required this.scheduleEnd,
    required this.audience,
    required this.announcementType,
    required this.locationAffected,
    required this.buildingId,
    required this.title,
    required this.description,
    required this.attachment,
    required this.contactNumber,
    required this.contactEmail,
  });

  // ------------------ JSON Helpers ------------------

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      scheduleStart: json['schedule_start'] ?? '',
      scheduleEnd: json['schedule_end'] ?? '',
      audience: json['audience'] ?? 'all',
      announcementType: json['announcement_type'] ?? 'general announcement',
      locationAffected: json['location_affected'] ?? 'Lobby',
      buildingId: json['building_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      attachment: json['attachment'] ?? '',
      contactNumber: json['contact_number'] ?? '',
      contactEmail: json['contact_email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'schedule_start': scheduleStart,
      'schedule_end': scheduleEnd,
      'audience': audience,
      'announcement_type': announcementType,
      'location_affected': locationAffected,
      'building_id': buildingId,
      'title': title,
      'description': description,
      'attachment': attachment,
      'contact_number': contactNumber,
      'contact_email': contactEmail,
    };
  }
}
