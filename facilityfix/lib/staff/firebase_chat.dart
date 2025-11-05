import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:facilityfix/services/firebase_chat_service.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/models/chat_models.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/widgets/chat.dart' as chat_widget;

class StaffChatListPage extends StatefulWidget {
  const StaffChatListPage({super.key});

  @override
  State<StaffChatListPage> createState() => _StaffChatListPageState();
}

class _StaffChatListPageState extends State<StaffChatListPage> {
  final int _selectedIndex = 1;
  final FirebaseChatService _chatService = FirebaseChatService();
  String? _currentUserId;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.build),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];

    if (index != 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final profile = await AuthStorage.getProfile();
    setState(() {
      _currentUserId = profile?['uid'] ?? profile?['user_id'] ?? '';
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _getRoomTitle(ChatRoom room) {
    if (room.concernSlipId != null) {
      return 'Concern Slip #${room.concernSlipId?.substring(0, 8)}';
    } else if (room.maintenanceId != null) {
      return 'Maintenance #${room.maintenanceId?.substring(0, 8)}';
    } else if (room.jobServiceId != null) {
      return 'Job Service #${room.jobServiceId?.substring(0, 8)}';
    } else {
      return 'Chat Room';
    }
  }

  Widget _buildRoomListTile(ChatRoom room) {
    final lastMessage = room.lastMessage;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF213ED7),
          child: Icon(
            room.concernSlipId != null
                ? Icons.report_problem
                : room.maintenanceId != null
                    ? Icons.build
                    : Icons.work,
            color: Colors.white,
          ),
        ),
        title: Text(
          _getRoomTitle(room),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: lastMessage != null
            ? Text(
                lastMessage['message'] ?? 'No messages yet',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF919EAB),
                  fontSize: 14,
                ),
              )
            : const Text(
                'Start a conversation',
                style: TextStyle(
                  color: Color(0xFF919EAB),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: lastMessage != null
            ? Text(
                _formatTimestamp(room.updatedAt),
                style: const TextStyle(
                  color: Color(0xFF919EAB),
                  fontSize: 12,
                ),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffChatDetailPage(room: room),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(title: 'Chat'),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
        bottomNavigationBar: NavBar(
          items: _navItems,
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: 'Chat'),
      body: StreamBuilder<List<ChatRoom>>(
        stream: _chatService.getUserRoomsStream(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFF919EAB),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF919EAB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF919EAB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Color(0xFF919EAB),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF919EAB),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chat rooms will appear here when you\nstart conversations from work orders',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF919EAB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              return _buildRoomListTile(rooms[index]);
            },
          );
        },
      ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class StaffChatDetailPage extends StatefulWidget {
  final ChatRoom room;

  const StaffChatDetailPage({
    super.key,
    required this.room,
  });

  @override
  State<StaffChatDetailPage> createState() => _StaffChatDetailPageState();
}

class _StaffChatDetailPageState extends State<StaffChatDetailPage> {
  final FirebaseChatService _chatService = FirebaseChatService();
  final APIService _apiService = APIService();
  String? _currentUserId;
  String _otherParticipantName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final profile = await AuthStorage.getProfile();
    setState(() {
      _currentUserId = profile?['uid'] ?? profile?['user_id'] ?? '';
    });

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      // Mark messages as read when entering the chat
      await _chatService.markMessagesAsRead(widget.room.id, _currentUserId!);
      // Load other participant's name
      await _loadOtherParticipantName();
    }
  }

  Future<void> _loadOtherParticipantName() async {
    try {
      // Get other participant ID (not current user)
      final otherParticipantId = widget.room.participants
          .firstWhere((id) => id != _currentUserId, orElse: () => '');
      
      if (otherParticipantId.isNotEmpty) {
        // Fetch user profile from API
        final userData = await _apiService.getUserById(otherParticipantId);
        
        if (userData != null) {
          // Extract the user's name from the profile
          String displayName = 'User';
          
          // Try different name fields based on the API response structure
          if (userData['first_name'] != null && userData['last_name'] != null) {
            displayName = '${userData['first_name']} ${userData['last_name']}';
          } else if (userData['name'] != null) {
            displayName = userData['name'];
          } else if (userData['username'] != null) {
            displayName = userData['username'];
          } else if (userData['email'] != null) {
            displayName = userData['email'].split('@')[0];
          }
          
          setState(() {
            _otherParticipantName = displayName;
          });
          
          print('[StaffChat] Loaded participant name: $displayName for ID: $otherParticipantId');
        } else {
          setState(() {
            _otherParticipantName = 'User';
          });
        }
      } else {
        setState(() {
          _otherParticipantName = 'Chat Room';
        });
      }
    } catch (e) {
      print('[StaffChat] Error loading participant name: $e');
      setState(() {
        _otherParticipantName = 'User';
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final isToday = now.year == timestamp.year &&
        now.month == timestamp.month &&
        now.day == timestamp.day;

    if (isToday) {
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  String _getRoomTitle() {
    // Show only the participant name, hide room code
    return _otherParticipantName;
  }
  Future<void> _editMessage(String messageId, String newText) async {
    try {
      // Directly update the message document in Firestore to avoid relying
      // on a possibly-missing method in FirebaseChatService.
      final roomId = widget.room.id;
      final messageRef = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .doc(messageId);

      await messageRef.update({
        'message': newText,
        'edited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[StaffChat] Error editing message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to edit message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMessage(List<String> messageIds) async {
    try {
      // Delete each message directly from Firestore since FirebaseChatService
      // does not expose a deleteMessage method.
      final roomId = widget.room.id;
      final messagesCollection = FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages');

      for (final messageId in messageIds) {
        final messageRef = messagesCollection.doc(messageId);
        await messageRef.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${messageIds.length} message${messageIds.length > 1 ? 's' : ''} deleted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('[StaffChat] Error deleting messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: _getRoomTitle(),
          leading: const BackButton(),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: _getRoomTitle(),
        leading: const BackButton(),
      ),
      body: StreamBuilder<List<ChatMessage>>(
        stream: _chatService.getMessagesStream(widget.room.id),
        builder: (context, snapshot) {
          print('[StaffChat] Messages stream state: ${snapshot.connectionState}');
          if (snapshot.hasData) {
            print('[StaffChat] Received ${snapshot.data!.length} messages');
          }
          if (snapshot.hasError) {
            print('[StaffChat] Messages stream error: ${snapshot.error}');
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFF919EAB),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading messages',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF919EAB),
                    ),
                  ),
                ],
              ),
            );
          }

          final messages = snapshot.data ?? [];

          // Convert ChatMessage models to chat_widget.ChatMessage format
          final chatMessages = messages.map((msg) {
            final isSender = msg.sentBy == _currentUserId;
            return chat_widget.ChatMessage(
              id: msg.id,
              text: msg.message,
              time: _formatTimestamp(msg.timestamp),
              isSender: isSender,
            );
          }).toList();

          // Use the ChatScreen widget
          return chat_widget.ChatScreen(
            assigneeName: _getRoomTitle(),
            messages: chatMessages,
            onSend: (message) async {
              if (message.trim().isEmpty) return;
              
              print('[StaffChat] Sending message: "$message" to room: ${widget.room.id}');
              
              try {
                await _chatService.sendMessage(
                  roomId: widget.room.id,
                  message: message,
                );
                
                print('[StaffChat] Message sent successfully');
              } catch (e) {
                print('[StaffChat] Error sending message: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send message: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onEdit: _editMessage,
            onDelete: _deleteMessage,
          );
        },
      ),
    );
  }
}