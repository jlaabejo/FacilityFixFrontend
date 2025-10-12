import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String roomCode;
  final String? concernSlipId;
  final String? maintenanceId;
  final String? jobServiceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? lastMessage;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.roomCode,
    this.concernSlipId,
    this.maintenanceId,
    this.jobServiceId,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      roomCode: data['room_code'] ?? '',
      concernSlipId: data['concern_slip_id'],
      maintenanceId: data['maintenance_id'],
      jobServiceId: data['job_service_id'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['last_message'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'room_code': roomCode,
      if (concernSlipId != null) 'concern_slip_id': concernSlipId,
      if (maintenanceId != null) 'maintenance_id': maintenanceId,
      if (jobServiceId != null) 'job_service_id': jobServiceId,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      if (lastMessage != null) 'last_message': lastMessage,
    };
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String message;
  final String contentType;
  final String sentBy;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.message,
    this.contentType = 'text',
    required this.sentBy,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ChatMessage(
      id: doc.id,
      roomId: data['room_id'] ?? '',
      message: data['message'] ?? '',
      contentType: data['content_type'] ?? 'text',
      sentBy: data['sent_by'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'room_id': roomId,
      'message': message,
      'content_type': contentType,
      'sent_by': sentBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'is_read': isRead,
    };
  }
}

enum MessageContentType {
  text,
  image,
  file,
  system,
}

extension MessageContentTypeExtension on MessageContentType {
  String get value {
    switch (this) {
      case MessageContentType.text:
        return 'text';
      case MessageContentType.image:
        return 'image';
      case MessageContentType.file:
        return 'file';
      case MessageContentType.system:
        return 'system';
    }
  }
}