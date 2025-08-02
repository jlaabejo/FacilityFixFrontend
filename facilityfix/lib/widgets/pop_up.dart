import 'package:flutter/material.dart';

class CustomPopup extends StatelessWidget {
  final String title;
  final String message;
  final String primaryText;
  final VoidCallback onPrimaryPressed;
  final String secondaryText;
  final VoidCallback onSecondaryPressed;
  final Widget? image;

const CustomPopup({
  super.key,
  required this.title,
  required this.message,
  required this.primaryText,
  required this.onPrimaryPressed,
  required this.secondaryText,
  required this.onSecondaryPressed,
  this.image,
});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 31, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(height: 100, width: 100, child: image),
              ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF393B41),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFF005CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: onPrimaryPressed,
                  child: Text(
                    primaryText,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFF005CE7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  onPressed: onSecondaryPressed,
                  child: Text(
                    secondaryText,
                    style: const TextStyle(
                      color: Color(0xFF005CE7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget iconOverlayContainer = Container(
  width: 100,
  height: 100,
  decoration: ShapeDecoration(
    color: const Color(0xFFADD1EF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  child: const Center(
    child: Icon(
      Icons.note_alt,
      size: 48,
      color: Color(0xFFFFFFFF),
    ),
  ),
);



