import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facilityfix/services/firebase_chat_service.dart';
import 'package:facilityfix/models/chat_models.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;

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
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    print('[StaffChat] Sending message: "$text" to room: ${widget.room.id}');

    try {
      await _chatService.sendMessage(
        roomId: widget.room.id,
        message: text,
      );
      _messageController.clear();
      
      print('[StaffChat] Message sent successfully');
      
      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollToBottom();
        }
      });
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
    String baseTitle;
    if (widget.room.concernSlipId != null) {
      baseTitle = 'Concern Slip Chat';
    } else if (widget.room.maintenanceId != null) {
      baseTitle = 'Maintenance Chat';
    } else if (widget.room.jobServiceId != null) {
      baseTitle = 'Job Service Chat';
    } else {
      baseTitle = 'General Chat';
    }
    
    // Append room code to title if available
    if (widget.room.roomCode.isNotEmpty) {
      return '$baseTitle (${widget.room.roomCode})';
    }
    return baseTitle;
  }

  void _copyRoomCode() {
    if (widget.room.roomCode.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: widget.room.roomCode));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room code ${widget.room.roomCode} copied to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareRoomCode() {
    if (widget.room.roomCode.isNotEmpty) {
      final shareText = 'Join this chat room with code: ${widget.room.roomCode}';
      Clipboard.setData(ClipboardData(text: shareText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room code copied for sharing'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showRoomInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getRoomTitle()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.room.roomCode.isNotEmpty) ...[
              Text('Room Code: ${widget.room.roomCode}'),
              const SizedBox(height: 8),
            ],
            Text('Participants: ${widget.room.participants.length}'),
            const SizedBox(height: 8),
            Text('Created: ${_formatTimestamp(widget.room.createdAt)}'),
            if (widget.room.concernSlipId != null) ...[
              const SizedBox(height: 8),
              Text('Concern Slip ID: ${widget.room.concernSlipId}'),
            ],
            if (widget.room.maintenanceId != null) ...[
              const SizedBox(height: 8),
              Text('Maintenance ID: ${widget.room.maintenanceId}'),
            ],
            if (widget.room.jobServiceId != null) ...[
              const SizedBox(height: 8),
              Text('Job Service ID: ${widget.room.jobServiceId}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'room_info':
                  _showRoomInfo();
                  break;
                case 'copy_code':
                  _copyRoomCode();
                  break;
                case 'share_code':
                  _shareRoomCode();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'room_info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Room Info'),
                  ],
                ),
              ),
              if (widget.room.roomCode.isNotEmpty) ...[
                PopupMenuItem(
                  value: 'copy_code',
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 20),
                      const SizedBox(width: 8),
                      Text('Copy Code (${widget.room.roomCode})'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share_code',
                  child: Row(
                    children: [
                      Icon(Icons.share, size: 20),
                      SizedBox(width: 8),
                      Text('Share Room Code'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
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
                        Text(
                          'Error loading messages',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Color(0xFF919EAB),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
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
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF919EAB),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start the conversation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF919EAB),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Auto scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollToBottom();
                  }
                });

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSender = message.sentBy == _currentUserId;

                    return Align(
                      alignment: isSender
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isSender
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(maxWidth: 240),
                            decoration: ShapeDecoration(
                              color: isSender
                                  ? const Color(0xFFD3FCD2)
                                  : const Color(0xFFF6F7F9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              message.message,
                              style: const TextStyle(
                                color: Color(0xFF161C24),
                                fontSize: 14,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.71,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(message.timestamp),
                            style: const TextStyle(
                              color: Color(0xFF919EAB),
                              fontSize: 10,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w400,
                              height: 1.8,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFF6F7F9)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 4),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFF6F7F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Color(0xFF919EAB),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF213ED7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}