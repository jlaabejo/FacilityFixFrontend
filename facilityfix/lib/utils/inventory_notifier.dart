import 'package:flutter/foundation.dart';

/// Notifier for inventory item updates (e.g., stock changes, reservations)
class InventoryUpdateNotifier extends ChangeNotifier {
  static final InventoryUpdateNotifier _instance = InventoryUpdateNotifier._internal();

  factory InventoryUpdateNotifier() => _instance;

  InventoryUpdateNotifier._internal();

  /// Notify listeners that an inventory item has been updated
  void notifyItemUpdated(String itemId) {
    notifyListeners();
  }

  /// Notify listeners that a reservation has been received
  void notifyReservationReceived(String reservationId, String itemId) {
    notifyListeners();
  }
}