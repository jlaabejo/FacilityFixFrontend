import 'package:flutter/material.dart';

/// Reusable widget for bulk action buttons (Assign & Delete)
/// These buttons are used in tables to perform actions on selected items
class BulkActionButtons extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onAssign;
  final VoidCallback onDelete;
  final bool isEnabled;
  final bool canAssign;

  const BulkActionButtons({
    Key? key,
    required this.selectedCount,
    required this.onAssign,
    required this.onDelete,
    this.isEnabled = true,
    this.canAssign = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool buttonsActive = isEnabled && selectedCount > 0;
    final bool assignActive = buttonsActive && canAssign;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: assignActive ? onAssign : null,
          icon: const Icon(Icons.assignment_turned_in, size: 18),
          label: const Text('Assign'),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) =>
                  states.contains(WidgetState.disabled)
                      ? Colors.grey[300]
                      : Colors.green[600],
            ),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) =>
                  states.contains(WidgetState.disabled)
                      ? Colors.grey[600]
                      : Colors.white,
            ),
            elevation: WidgetStateProperty.resolveWith<double?>(
              (states) => states.contains(WidgetState.disabled) ? 0 : 2,
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: buttonsActive ? onDelete : null,
          icon: const Icon(Icons.delete_outline, size: 18),
          label: const Text('Delete'),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) =>
                  states.contains(WidgetState.disabled)
                      ? Colors.grey[300]
                      : Colors.red[600],
            ),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>(
              (states) =>
                  states.contains(WidgetState.disabled)
                      ? Colors.grey[600]
                      : Colors.white,
            ),
            elevation: WidgetStateProperty.resolveWith<double?>(
              (states) => states.contains(WidgetState.disabled) ? 0 : 2,
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
