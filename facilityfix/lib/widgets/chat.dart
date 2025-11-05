import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String text;
  final String time;
  final bool isSender;

  ChatMessage({
    required this.id,
    required this.text,
    required this.time,
    required this.isSender,
  });
}

class ChatScreen extends StatefulWidget {
  final String assigneeName;
  final List<ChatMessage> messages;
  final void Function(String message) onSend;
  final void Function(String messageId, String newText)? onEdit;
  final void Function(List<String> messageIds)? onDelete;

  const ChatScreen({
    super.key,
    required this.assigneeName,
    required this.messages,
    required this.onSend,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isEditMode = false;
  bool _isDeleteMode = false;
  String? _editingMessageId;
  final Set<String> _selectedMessages = {};
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _editController.dispose();
    super.dispose();
  }

  void _showMessageOptions(ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Edit (only for sender)
              if (msg.isSender)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF213ED7),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Edit message',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _isEditMode = true;
                      _editingMessageId = msg.id;
                      _editController.text = msg.text;
                    });
                  },
                ),

              const SizedBox(height: 6),

              // Delete (only for sender)
              if (msg.isSender)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _isDeleteMode = true;
                      _selectedMessages.clear();
                      _selectedMessages.add(msg.id);
                    });
                    // open delete confirmation sheet
                    _confirmDelete();
                  },
                ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditMode = false;
      _editingMessageId = null;
      _editController.clear();
    });
  }

  void _saveEdit() {
    final newText = _editController.text.trim();
    if (newText.isNotEmpty &&
        _editingMessageId != null &&
        widget.onEdit != null) {
      widget.onEdit!(_editingMessageId!, newText);
      _cancelEdit();
    }
  }

  void _cancelDelete() {
    setState(() {
      _isDeleteMode = false;
      _selectedMessages.clear();
    });
  }

  void _confirmDelete() {
    if (_selectedMessages.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Text(
                    'Delete ${_selectedMessages.length} message${_selectedMessages.length > 1 ? 's' : ''}?',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Delete for everyone option
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Delete for everyone',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onDelete != null) {
                      widget.onDelete!(_selectedMessages.toList());
                    }
                    _cancelDelete();
                  },
                ),
                // Delete for me option
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Delete for me',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFEF4444),
                      fontFamily: 'Inter',
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    // For now, treat "delete for me" same as "delete for everyone"
                    // You can implement separate logic later
                    if (widget.onDelete != null) {
                      widget.onDelete!(_selectedMessages.toList());
                    }
                    _cancelDelete();
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );
  }

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessages.contains(messageId)) {
        _selectedMessages.remove(messageId);
      } else {
        _selectedMessages.add(messageId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          _isDeleteMode
                ? null
              : null,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Chat Messages List
            Expanded(
              child: ListView.separated(
                itemCount: widget.messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final msg = widget.messages[index];
                  return GestureDetector(
                    onLongPress: () => _showMessageOptions(msg),
                    child: Row(
                      children: [
                        // Checkbox for delete mode
                        if (_isDeleteMode)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _toggleMessageSelection(msg.id),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        _selectedMessages.contains(msg.id)
                                            ? const Color(0xFF213ED7)
                                            : const Color(0xFF919EAB),
                                    width: 2,
                                  ),
                                  color:
                                      _selectedMessages.contains(msg.id)
                                          ? const Color(0xFF213ED7)
                                          : Colors.transparent,
                                ),
                                child:
                                    _selectedMessages.contains(msg.id)
                                        ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                            ),
                          ),
                        // Message bubble
                        Expanded(
                          child: Align(
                            alignment:
                                msg.isSender
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment:
                                  msg.isSender
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  constraints: const BoxConstraints(
                                    maxWidth: 240,
                                  ),
                                  decoration: ShapeDecoration(
                                    color:
                                        msg.isSender
                                            ? const Color(0xFFD3FCD2)
                                            : const Color(0xFFF6F7F9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    msg.text,
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
                                SizedBox(
                                  width: msg.isSender ? 296 : null,
                                  child: Text(
                                    msg.time,
                                    textAlign:
                                        msg.isSender
                                            ? TextAlign.right
                                            : TextAlign.left,
                                    style: const TextStyle(
                                      color: Color(0xFF919EAB),
                                      fontSize: 10,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                      height: 1.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Border line above input (only in normal mode)
            if (!_isEditMode)
              Container(height: 1, color: const Color(0xFFE5E7EB)),

            if (!_isEditMode) const SizedBox(height: 16),

            // Input Field - Edit Mode
            if (_isEditMode)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with "Edit message" text and X button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit message',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: const Color(0xFF919EAB),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _cancelEdit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Text field with check button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 40,
                              maxHeight: 120,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextField(
                              controller: _editController,
                              autofocus: true,
                              maxLines: null,
                              minLines: 1,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Type your message',
                                hintStyle: TextStyle(
                                  color: Color(0xFF919EAB),
                                  fontSize: 15,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w400,
                                ),
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Improved mini check button with better tap target, ripple and disabled state
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _editController,
                          builder: (context, value, child) {
                            final enabled = value.text.trim().isNotEmpty;
                            return Material(
                              color:
                                  enabled
                                      ? const Color(0xFF213ED7)
                                      : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(99),
                              elevation: enabled ? 2 : 0,
                              child: InkWell(
                                onTap: enabled ? _saveEdit : null,
                                borderRadius: BorderRadius.circular(10),
                                splashColor: Colors.white24,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.check,
                                    size: 18,
                                    color:
                                        enabled
                                            ? Colors.white
                                            : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              )
            // Input Field - Delete Mode
            else if (_isDeleteMode)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _selectedMessages.isEmpty ? null : _confirmDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    'Delete (${_selectedMessages.length})',
                    style: TextStyle(
                      color:
                          _selectedMessages.isEmpty
                              ? const Color(0xFF9CA3AF)
                              : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              )
            // Input Field - Normal Mode
            else
              Row(
                children: [
                  // Input container (auto-expanding up to 120px)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: ShapeDecoration(
                        color: const Color(0xFFF6F7F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 120, // limit growth
                              ),
                              child: Scrollbar(
                                child: TextField(
                                  controller: _messageController,
                                  keyboardType: TextInputType.multiline,
                                  minLines: 1,
                                  maxLines: null, // allow vertical expansion
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 1.5,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Type your message',
                                    hintStyle: TextStyle(
                                      color: Color(0xFF919EAB),
                                      fontSize: 16,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w400,
                                    ),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Color(0xFF213ED7),
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final text = _messageController.text.trim();
                        if (text.isNotEmpty) {
                          widget.onSend(text);
                          _messageController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
