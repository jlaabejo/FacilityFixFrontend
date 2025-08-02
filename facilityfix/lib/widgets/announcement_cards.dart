import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String datePosted;
  final String details;
  final String classification; // e.g., "utility", "power", "pest", "maintenance"
  final VoidCallback? onViewPressed;

  const AnnouncementCard({
    super.key,
    required this.title,
    required this.datePosted,
    required this.details,
    required this.classification,
    this.onViewPressed,
  });

  Color _getCardColor() {
    switch (classification.toLowerCase()) {
      case 'utility':
        return const Color(0xFFEAECFD); // Blue-ish
      case 'power':
        return const Color(0xFFFDF6A3); // Yellow-ish
      case 'pest':
        return const Color(0xFF91E5B0); // Green-ish
      case 'maintenance':
        return const Color(0xFFFFD4B1); // Orange-ish
      default:
        return const Color(0xFFEEEEEE); // Neutral Gray
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: _getCardColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF282657),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          // Date Posted
          Opacity(
            opacity: 0.9,
            child: Text(
              'Posted $datePosted',
              style: const TextStyle(
                color: Color(0xFF6F6F6F),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Mini Details
          Opacity(
            opacity: 0.9,
            child: Text(
              details,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF6F6F6F),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.29,
              ),
            ),
          ),

          const SizedBox(height: 8),

        ],
      ),
    );
  }
}
