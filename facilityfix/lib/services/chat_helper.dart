import 'package:flutter/material.dart';
import 'package:facilityfix/services/firebase_chat_service.dart';
import 'package:facilityfix/models/chat_models.dart';
import 'package:facilityfix/staff/firebase_chat.dart';
import 'package:facilityfix/services/auth_storage.dart';

class ChatHelper {
  static final FirebaseChatService _chatService = FirebaseChatService();

  /// Navigate to chat from work order (staff perspective)
  static Future<void> navigateToWorkOrderChat({
    required BuildContext context,
    required String workOrderId,
    bool isStaff = false,
  }) async {
    try {
      final profile = await AuthStorage.getProfile();
      final currentUserId = profile?['uid'] ?? profile?['user_id'] ?? '';
      
      if (currentUserId.isEmpty) {
        _showErrorSnackbar(context, 'User not authenticated');
        return;
      }

      // Find existing room or create new one based on concern slip ID
      ChatRoom? existingRoom = await _chatService.findRoomByReference(
        concernSlipId: workOrderId,
      );

      if (existingRoom == null) {
        existingRoom = await _chatService.createOrGetRoom(
          participants: [currentUserId], // Just add current user, others will join as needed
          concernSlipId: workOrderId,
        );
      } else {
        // If room exists but current user is not a participant, add them
        if (!existingRoom.participants.contains(currentUserId)) {
          await _chatService.addParticipantToRoom(existingRoom.id, currentUserId);
          // Refresh the room data to include the new participant
          existingRoom = await _chatService.getRoomById(existingRoom.id);
        }
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffChatDetailPage(room: existingRoom!),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to open chat: $e');
      }
    }
  }

  /// Navigate to chat from maintenance (staff perspective)
  static Future<void> navigateToMaintenanceChat({
    required BuildContext context,
    required String maintenanceId,
    bool isStaff = false,
  }) async {
    try {
      final profile = await AuthStorage.getProfile();
      final currentUserId = profile?['uid'] ?? profile?['user_id'] ?? '';
      
      if (currentUserId.isEmpty) {
        _showErrorSnackbar(context, 'User not authenticated');
        return;
      }

      // Find existing room or create new one based on maintenance ID
      ChatRoom? existingRoom = await _chatService.findRoomByReference(
        maintenanceId: maintenanceId,
      );

      if (existingRoom == null) {
        existingRoom = await _chatService.createOrGetRoom(
          participants: [currentUserId], // Just add current user, others will join as needed
          maintenanceId: maintenanceId,
        );
      } else {
        // If room exists but current user is not a participant, add them
        if (!existingRoom.participants.contains(currentUserId)) {
          await _chatService.addParticipantToRoom(existingRoom.id, currentUserId);
          // Refresh the room data to include the new participant
          existingRoom = await _chatService.getRoomById(existingRoom.id);
        }
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffChatDetailPage(room: existingRoom!),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to open chat: $e');
      }
    }
  }

  /// Navigate to chat from job service (staff perspective)
  static Future<void> navigateToJobServiceChat({
    required BuildContext context,
    required String jobServiceId,
    bool isStaff = false,
  }) async {
    try {
      final profile = await AuthStorage.getProfile();
      final currentUserId = profile?['uid'] ?? profile?['user_id'] ?? '';
      
      if (currentUserId.isEmpty) {
        _showErrorSnackbar(context, 'User not authenticated');
        return;
      }

      // Find existing room or create new one based on job service ID
      ChatRoom? existingRoom = await _chatService.findRoomByReference(
        jobServiceId: jobServiceId,
      );

      if (existingRoom == null) {
        existingRoom = await _chatService.createOrGetRoom(
          participants: [currentUserId], // Just add current user, others will join as needed
          jobServiceId: jobServiceId,
        );
      } else {
        // If room exists but current user is not a participant, add them
        if (!existingRoom.participants.contains(currentUserId)) {
          await _chatService.addParticipantToRoom(existingRoom.id, currentUserId);
          // Refresh the room data to include the new participant
          existingRoom = await _chatService.getRoomById(existingRoom.id);
        }
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffChatDetailPage(room: existingRoom!),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to open chat: $e');
      }
    }
  }

  /// Create a general chat room between users
  static Future<void> navigateToGeneralChat({
    required BuildContext context,
    required List<String> participantIds,
    bool isStaff = false,
  }) async {
    try {
      final profile = await AuthStorage.getProfile();
      final currentUserId = profile?['uid'] ?? profile?['user_id'] ?? '';
      
      if (currentUserId.isEmpty) {
        _showErrorSnackbar(context, 'User not authenticated');
        return;
      }

      // Ensure current user is in participants
      final allParticipants = <String>[
        currentUserId,
        ...participantIds.where((id) => id != currentUserId),
      ];

      final room = await _chatService.createOrGetRoom(
        participants: allParticipants,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffChatDetailPage(room: room),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to open chat: $e');
      }
    }
  }

  /// Join existing chat by reference ID (for tenants)
  static Future<void> joinChatByReference({
    required BuildContext context,
    String? concernSlipId,
    String? maintenanceId,
    String? jobServiceId,
    bool isStaff = false,
  }) async {
    try {
      final profile = await AuthStorage.getProfile();
      final currentUserId = profile?['uid'] ?? profile?['user_id'] ?? '';
      
      if (currentUserId.isEmpty) {
        _showErrorSnackbar(context, 'User not authenticated');
        return;
      }

      // Try to find existing room
      ChatRoom? room = await _chatService.findRoomByReference(
        concernSlipId: concernSlipId,
        maintenanceId: maintenanceId,
        jobServiceId: jobServiceId,
      );

      if (room == null) {
        // Create new room if none exists
        room = await _chatService.createOrGetRoom(
          participants: [currentUserId],
          concernSlipId: concernSlipId,
          maintenanceId: maintenanceId,
          jobServiceId: jobServiceId,
        );
      } else {
        // If room exists but current user is not a participant, add them
        if (!room.participants.contains(currentUserId)) {
          await _chatService.addParticipantToRoom(room.id, currentUserId);
          // Refresh the room data to include the new participant
          room = await _chatService.getRoomById(room.id);
        }
      }

      if (context.mounted && room != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffChatDetailPage(room: room!),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to join chat: $e');
      }
    }
  }

  /// Get unread message count for current user
  static Stream<int> getUnreadCountStream() async* {
    try {
      final profile = await AuthStorage.getProfile();
      final currentUserId = profile?['uid'] ?? profile?['user_id'] ?? '';
      
      if (currentUserId.isEmpty) {
        yield 0;
        return;
      }

      yield* _chatService.getUnreadCountStream(currentUserId);
    } catch (e) {
      print('Error getting unread count: $e');
      yield 0;
    }
  }

  /// Initialize Firebase chat collections
  static Future<void> initializeChat() async {
    try {
      await _chatService.initializeCollections();
      print('[ChatHelper] Chat collections initialized successfully');
    } catch (e) {
      print('[ChatHelper] Error initializing chat: $e');
      // Don't throw error, just log it
    }
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Widget to show chat button with unread count
class ChatButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isStaff;

  const ChatButton({
    super.key,
    required this.onPressed,
    this.isStaff = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: ChatHelper.getUnreadCountStream(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: onPressed,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}