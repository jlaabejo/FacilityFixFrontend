import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum MaintenanceChoice { internal, external }

/// Call this from anywhere to run the full 2-step flow:
/// 1) "Create maintenance task?" (Yes/No)
/// 2) pick Internal vs External
Future<void> showCreateMaintenanceTaskDialog(
  BuildContext context, {
  VoidCallback? onInternal,         // optional override
  VoidCallback? onExternal,         // optional override
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Create Maintenance Task',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          SizedBox(height: 16),
          Divider(thickness: 1, height: 1),
        ],
      ),
      content: const SizedBox(
        width: 300,
        child: Text(
          'Would you like to create a maintenance task?',
          style: TextStyle(fontSize: 16, color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 200, height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Yes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 200, height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('No', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
          ]),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    ),
  );

  if (confirmed != true) return;

  final choice = await _showMaintenanceTypeDialog(context);
  if (choice == null) return;

  // Default actions if callbacks not provided
  if (choice == MaintenanceChoice.internal) {
    if (onInternal != null) {
      onInternal();
    } else {
      context.go('/adminweb/pages/workmaintenance_form');
    }
  } else if (choice == MaintenanceChoice.external) {
    if (onExternal != null) {
      onExternal();
    } else {
      context.go('/adminweb/pages/externalmaintenance_form');
    }
  }
}

Future<MaintenanceChoice?> _showMaintenanceTypeDialog(BuildContext context) {
  return showDialog<MaintenanceChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select type of maintenance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          SizedBox(height: 16),
          Divider(thickness: 1, height: 1),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(MaintenanceChoice.internal),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Internal Preventive Maintenance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('(Handled by in-house staff)', style: TextStyle(fontSize: 14, color: Colors.black)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 60,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(MaintenanceChoice.external),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('External Preventive Maintenance',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('(Outsourced to contractor/service provider)',
                style: TextStyle(fontSize: 14, color: Colors.black)),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    ),
  );
}
