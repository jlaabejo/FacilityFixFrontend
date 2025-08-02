import 'package:flutter/material.dart';

class RequestDetailsScreen extends StatelessWidget {
  final String title;
  final String requestId;
  final String classification;
  final String date;
  final String requestType;
  final String unit;
  final String description;
  final String priority;
  final String assigneeName;
  final String assigneeRole;
  final List<String> attachments;

  const RequestDetailsScreen({
    super.key,
    required this.title,
    required this.requestId,
    required this.classification,
    required this.date,
    required this.requestType,
    required this.unit,
    required this.description,
    required this.priority,
    required this.assigneeName,
    required this.assigneeRole,
    required this.attachments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAECF0),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  classification,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
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
          const SizedBox(height: 16),

          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              buildLabelValue("Submitted On", date),
              buildLabelValue("Request Type", requestType),
              buildLabelValue("Unit", unit),
            ],
          ),
          const SizedBox(height: 24),

          buildSection(
            title: "Description",
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475467),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          buildSection(
            title: "Priority",
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: getPriorityColor(priority),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(priority, style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),

          buildSection(
            title: "Assignee",
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFD9D9D9),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assigneeName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      assigneeRole,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7A5AF8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          buildSection(
            title: "Attachments",
            child: Wrap(
              spacing: 8,
              children: attachments.map((url) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    url,
                    height: 80,
                    width: 140,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF667085),
            )),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF344054),
            )),
      ],
    );
  }

  Widget buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF344054),
            )),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFF04438);
      case 'medium':
        return const Color(0xFFF79009);
      case 'low':
        return const Color(0xFF12B76A);
      default:
        return const Color(0xFF667085);
    }
  }
}


