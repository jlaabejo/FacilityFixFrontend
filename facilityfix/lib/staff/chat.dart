
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:facilityfix/services/firebase_chat_service.dart';
import 'package:facilityfix/models/chat_models.dart';
import 'package:facilityfix/services/auth_storage.dart';
import 'package:facilityfix/staff/firebase_chat.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/staff/announcement.dart';
import 'package:facilityfix/staff/calendar.dart';
import 'package:facilityfix/staff/home.dart';
import 'package:facilityfix/staff/inventory.dart';
import 'package:facilityfix/staff/workorder.dart';

class ChatPage extends StatefulWidget {
  final String? roomId;
  final String? roomCode;
  final String? concernSlipId;
  final String? maintenanceId;
  final String? jobServiceId;
  
  const ChatPage({
    super.key,
    this.roomId,
    this.roomCode,
    this.concernSlipId,
    this.maintenanceId,
    this.jobServiceId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final int _selectedIndex = 1;
  final FirebaseChatService _chatService = FirebaseChatService();
  String? _currentUserId;
  ChatRoom? _specificRoom;

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.calendar_month),
    NavItem(icon: Icons.inventory),
  ];

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
    
    // If specific room parameters provided, load or create the room
    if (widget.roomId != null || widget.roomCode != null || 
        widget.concernSlipId != null || widget.maintenanceId != null || 
        widget.jobServiceId != null) {
      await _loadSpecificRoom();
    }
  }

  Future<void> _loadSpecificRoom() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    
    try {
      ChatRoom? room;
      
      if (widget.roomId != null) {
        room = await _chatService.getRoomById(widget.roomId!);
      } else if (widget.concernSlipId != null) {
        room = await _chatService.findRoomByReference(concernSlipId: widget.concernSlipId);
        if (room == null) {
          room = await _chatService.createOrGetRoom(
            participants: [_currentUserId!],
            concernSlipId: widget.concernSlipId,
          );
        }
      } else if (widget.maintenanceId != null) {
        room = await _chatService.findRoomByReference(maintenanceId: widget.maintenanceId);
        if (room == null) {
          room = await _chatService.createOrGetRoom(
            participants: [_currentUserId!],
            maintenanceId: widget.maintenanceId,
          );
        }
      } else if (widget.jobServiceId != null) {
        room = await _chatService.findRoomByReference(jobServiceId: widget.jobServiceId);
        if (room == null) {
          room = await _chatService.createOrGetRoom(
            participants: [_currentUserId!],
            jobServiceId: widget.jobServiceId,
          );
        }
      }
      
      if (room != null) {
        setState(() {
          _specificRoom = room;
        });
      }
    } catch (e) {
      print('[StaffChat] Error loading specific room: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const CalendarPage(),
      const InventoryPage(),
    ];

    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
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
      return 'General Chat';
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
        title: Row(
          children: [
            Expanded(
              child: Text(
                _getRoomTitle(room),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (room.roomCode.isNotEmpty)
              GestureDetector(
                onTap: () => _copyRoomCode(room.roomCode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF213ED7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    room.roomCode,
                    style: const TextStyle(
                      color: Color(0xFF213ED7),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (lastMessage != null)
              Text(
                _formatTimestamp(room.updatedAt),
                style: const TextStyle(
                  color: Color(0xFF919EAB),
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            // Show participant count for staff
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF919EAB).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${room.participants.length} users',
                style: const TextStyle(
                  color: Color(0xFF919EAB),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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

  void _copyRoomCode(String roomCode) {
    Clipboard.setData(ClipboardData(text: roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room code $roomCode copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCreateChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Chat Room'),
        content: const Text('Choose how to create a new chat room:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showJoinByCodeDialog();
            },
            child: const Text('Join by Code'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _createGeneralChat();
            },
            child: const Text('Create General Chat'),
          ),
        ],
      ),
    );
  }

  void _showJoinByCodeDialog() {
    final TextEditingController codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Chat by Code'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Room Code',
            hintText: 'Enter 8-character room code',
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              if (code.length == 8) {
                Navigator.pop(context);
                // TODO: Implement join by code functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Join by code feature coming soon')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGeneralChat() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    
    try {
      final room = await _chatService.createOrGetRoom(
        participants: [_currentUserId!],
      );
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StaffChatDetailPage(room: room),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If specific room is provided, go directly to chat detail
    if (_specificRoom != null) {
      return StaffChatDetailPage(room: _specificRoom!);
    }

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
      appBar: CustomAppBar(
        title: 'Chat',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: _showCreateChatDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<ChatRoom>>(
        // Get rooms where staff is a participant
        stream: _chatService.getUserRoomsStream(_currentUserId!),
        builder: (context, snapshot) {
          print('[StaffChat] Current user ID: $_currentUserId');
          print('[StaffChat] Rooms stream state: ${snapshot.connectionState}');
          if (snapshot.hasData) {
            print('[StaffChat] Received ${snapshot.data!.length} rooms');
            for (final room in snapshot.data!) {
              print('[StaffChat] Room ${room.id}: participants=${room.participants}');
            }
          }
          if (snapshot.hasError) {
            print('[StaffChat] Rooms stream error: ${snapshot.error}');
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Error loading chat rooms: ${snapshot.error}');
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
                    'Error loading chats',
                    style: TextStyle(
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Refresh the stream
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Color(0xFF919EAB),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF919EAB),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chat rooms will appear here when conversations\nare started from work orders or created manually',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF919EAB),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateChatDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Chat Room'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF213ED7),
                      foregroundColor: Colors.white,
                    ),
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
