import 'package:flutter/material.dart';
import 'package:facilityfix/tenant/announcement.dart';
import 'package:facilityfix/tenant/home.dart';
import 'package:facilityfix/tenant/profile.dart';
import 'package:facilityfix/tenant/workorder.dart';
import 'package:facilityfix/widgets/chat.dart';
import 'package:facilityfix/widgets/app&nav_bar.dart';
import 'package:facilityfix/services/api_services.dart';
import 'package:facilityfix/services/auth_storage.dart';

class ChatPage extends StatefulWidget {
  final String? roomId;
  final String? concernSlipId;
  final String? assigneeName;
  
  const ChatPage({
    super.key,
    this.roomId,
    this.concernSlipId,
    this.assigneeName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final int _selectedIndex = 1;
  final APIService _apiService = APIService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _currentRoomId;
  String _assigneeDisplayName = 'Staff';

  final List<NavItem> _navItems = const [
    NavItem(icon: Icons.home),
    NavItem(icon: Icons.work),
    NavItem(icon: Icons.announcement_rounded),
    NavItem(icon: Icons.person),
  ];

  @override
  void initState() {
    super.initState();
    _assigneeDisplayName = widget.assigneeName ?? 'Staff';
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      setState(() => _isLoading = true);
      
      // Get or create room
      Map<String, dynamic>? room;
      
      if (widget.roomId != null) {
        // Use existing room ID
        room = await _apiService.getChatRoom(widget.roomId!);
      } else if (widget.concernSlipId != null) {
        // Get room by concern slip reference
        room = await _apiService.getChatRoomByReference(
          referenceType: 'concern_slip',
          referenceId: widget.concernSlipId!,
        );
      }
      
      if (room != null) {
        _currentRoomId = room['id'] as String;
        
        // Get participant names for display
        final participantNames = room['participant_names'] as Map<String, dynamic>?;
        if (participantNames != null && participantNames.isNotEmpty) {
          final profile = await AuthStorage.getProfile();
          final userId = profile?['id'] ?? profile?['user_id'];
          // Find the other participant's name
          for (final entry in participantNames.entries) {
            if (entry.key != userId) {
              _assigneeDisplayName = entry.value as String? ?? 'Staff';
              break;
            }
          }
        }
        
        // Load messages
        await _loadMessages();
        
        // Mark messages as read
        await _apiService.markMessagesAsRead(_currentRoomId!);
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_currentRoomId == null) return;
    
    try {
      final messages = await _apiService.getChatMessages(
        roomId: _currentRoomId!,
        limit: 100,
      );
      
      final profile = await AuthStorage.getProfile();
      final userId = profile?['id'] ?? profile?['user_id'];
      
      setState(() {
        _messages = messages.map((msg) {
          final createdAt = msg['created_at'];
          String timeStr = 'Now';
          
          if (createdAt != null) {
            try {
              final DateTime dt = DateTime.parse(createdAt.toString());
              final time = TimeOfDay.fromDateTime(dt);
              timeStr = time.format(context);
            } catch (e) {
              print('Error parsing time: $e');
            }
          }
          
          return ChatMessage(
            text: msg['message_text'] as String? ?? '',
            time: timeStr,
            isSender: (msg['sender_id'] as String?) == userId,
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _onTabTapped(int index) {
    final destinations = [
      const HomePage(),
      const WorkOrderPage(),
      const AnnouncementPage(),
      const ProfilePage(),
    ];

    if (index != _selectedIndex) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destinations[index]),
      );
    }
  }

  Future<void> _handleSendMessage(String messageText) async {
    if (_currentRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat room not initialized')),
      );
      return;
    }
    
    // Optimistically add message to UI
    final newMessage = ChatMessage(
      text: messageText,
      time: TimeOfDay.now().format(context),
      isSender: true,
    );
    
    setState(() {
      _messages.add(newMessage);
    });
    
    try {
      // Send message to backend
      await _apiService.sendChatMessage(
        roomId: _currentRoomId!,
        messageText: messageText,
      );
      
      // Reload messages to get accurate data
      await _loadMessages();
    } catch (e) {
      print('Error sending message: $e');
      // Remove optimistic message on error
      setState(() {
        _messages.remove(newMessage);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Chat',
        leading: Row(
          children: const [
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: BackButton(),
            ),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: ChatScreen(
              assigneeName: _assigneeDisplayName,
              messages: _messages,
              onSend: _handleSendMessage,
            ),
          ),
      bottomNavigationBar: NavBar(
        items: _navItems,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
