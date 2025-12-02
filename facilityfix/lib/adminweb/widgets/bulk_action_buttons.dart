import 'package:flutter/material.dart';

/// Reusable widget for bulk action buttons
/// Supports both (Assign & Delete) and (Approve & Reject) modes
class BulkActionButtons extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onAssign;
  final VoidCallback? onDelete;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isEnabled;
  final bool canAssign;
  final BulkActionMode mode;

  const BulkActionButtons({
    Key? key,
    required this.selectedCount,
    this.onAssign,
    this.onDelete,
    this.onApprove,
    this.onReject,
    this.isEnabled = true,
    this.canAssign = true,
    this.mode = BulkActionMode.assignDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool buttonsActive = isEnabled && selectedCount > 0;
    final bool assignActive = buttonsActive && canAssign;

    if (mode == BulkActionMode.approveReject) {
      return _buildApproveRejectButtons(buttonsActive);
    }

    return _buildAssignDeleteButtons(assignActive, buttonsActive);
  }

  Widget _buildAssignDeleteButtons(bool assignActive, bool buttonsActive) {
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

  Widget _buildApproveRejectButtons(bool buttonsActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: buttonsActive ? onApprove : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                buttonsActive ? Colors.green[600] : Colors.grey[300],
            disabledBackgroundColor: Colors.grey[300],
            foregroundColor: buttonsActive ? Colors.white : Colors.grey[600],
            disabledForegroundColor: Colors.grey[600],
            elevation: buttonsActive ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Approve'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: buttonsActive ? onReject : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonsActive ? Colors.red[600] : Colors.grey[300],
            disabledBackgroundColor: Colors.grey[300],
            foregroundColor: buttonsActive ? Colors.white : Colors.grey[600],
            disabledForegroundColor: Colors.grey[600],
            elevation: buttonsActive ? 2 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

enum BulkActionMode { assignDelete, approveReject }
