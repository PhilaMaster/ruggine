import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/widgets/ruggine_appbar.dart';
import 'package:ruggine_client/models/chat.dart';
import 'package:ruggine_client/models/message.dart';

class ChatPage extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatPage({super.key, required this.chat});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<Message> messages;

  // For demo purposes, using a hardcoded current user ID
  // TODO: Replace with actual user provider when implementing real messaging
  final String currentUserId = "current_user_123";

  @override
  void initState() {
    super.initState();
    // TODO: Replace with actual message provider
    _initializeMockMessages();
  }

  void _initializeMockMessages() {
    messages = [
      Message(
        id: '1',
        senderId: widget.chat.lastSender,
        content: 'Hello, how are you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Message(
        id: '2',
        senderId: currentUserId,
        content: 'I am fine, thank you! How about you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      Message(
        id: '3',
        senderId: widget.chat.lastSender,
        content: 'Great! I wanted to discuss the project with you.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUserId,
      content: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      messages.add(newMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    // TODO: Add message to provider and send to backend
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildRuggineAppBar(context, ref, widget.chat.lastSender),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message.senderId == currentUserId;
                  final isLastMessage = index == messages.length - 1;

                  return _buildMessageBubble(
                    message,
                    isCurrentUser,
                    isLastMessage
                  );
                },
              ),
            ),
          ),
          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isCurrentUser,
    bool isLastMessage
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4.0,
          bottom: isLastMessage ? 8.0 : 4.0,
          left: isCurrentUser ? 80.0 : 8.0,
          right: isCurrentUser ? 8.0 : 80.0,
        ),
        child: Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          color: isCurrentUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16.0),
              topRight: const Radius.circular(16.0),
              bottomLeft: Radius.circular(isCurrentUser ? 16.0 : 4.0),
              bottomRight: Radius.circular(isCurrentUser ? 4.0 : 16.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sender name (only for received messages)
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      message.senderId,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.0,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                // Message content
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: isCurrentUser
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4.0),
                // Timestamp
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 11.0,
                      color: (isCurrentUser
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant).withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  Widget _buildInputField() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 0.5
          ),
        ),
      ),
      child: Row(
        children: [
          // Text input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Send button
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: Icon(
                Icons.send,
                color: colorScheme.onPrimary,
                size: 20.0,
              ),
              padding: const EdgeInsets.all(12.0),
            ),
          ),
        ],
      ),
    );
  }
}