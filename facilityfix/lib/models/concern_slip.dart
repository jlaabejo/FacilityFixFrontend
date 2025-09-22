class ConcernSlip {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String location;
  final String reportedBy;
  final DateTime createdAt;

  ConcernSlip({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.location,
    required this.reportedBy,
    required this.createdAt,
  });

  factory ConcernSlip.fromJson(Map<String, dynamic> json) {
    return ConcernSlip(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'low',
      location: json['location'] ?? '',
      reportedBy: json['reported_by'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
