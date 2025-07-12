import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/widgets/ruggine_appbar.dart';
import 'package:ruggine_client/models/chat.dart';
import 'package:ruggine_client/models/message.dart';

import '../providers/auth_provider.dart';
import '../providers/chats_provider.dart';
import '../providers/messages_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatPage({super.key, required this.chat});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    ref.read(msgProvider.notifier).sendMessage(
      widget.chat.id.toString(),
      _messageController.text.trim(),
    );
    _messageController.clear();
    _scrollToBottom();
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

  Future<void> _initMessages() async {
    // Delay provider modifications until after the widget tree is built
    Future(() async {
      final msgRepo = ref.read(msgProvider.notifier);
      try {
        // Remove the resetState call - let loadLocalMessages handle the state
        await msgRepo.loadLocalMessages(widget.chat.id);
        await msgRepo.loadMessages(widget.chat.id);
      } finally {
        ref.read(chatProvider.notifier).resetUnreadCount(widget.chat.id);
        if (mounted) {
          setState(() {
            _isInitializing = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(msgProvider);
    final currentUserName = ref.watch(authProvider)?.username ?? '';

    return Scaffold(
      appBar: buildRuggineAppBar(context, ref, widget.chat.lastSender),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: _isInitializing
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading messages...'),
                  ],
                ),
              )
                  : messages == null || messages.isEmpty
                  ? const Center(child: Text('No messages yet'))
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isCurrentUser = message.senderName == currentUserName;
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
              : colorScheme.surfaceContainerHighest,
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
                      message.senderName,
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
                          : colorScheme.onSurfaceVariant).withValues(alpha: 0.7),
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
              color: colorScheme.outline.withValues(alpha: 0.3),
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
                color: _isInitializing
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(
                  color: _isInitializing
                      ? colorScheme.outline.withValues(alpha: 0.3)
                      : colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !_isInitializing,
                style: TextStyle(
                  color: _isInitializing
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                      : colorScheme.onSurfaceVariant,
                ),
                decoration: InputDecoration(
                  hintText: _isInitializing
                      ? 'Loading chat...'
                      : 'Type a message...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _isInitializing ? null : (_) => _sendMessage(),
                maxLines: null,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Send button
          Container(
            decoration: BoxDecoration(
              color: _isInitializing
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isInitializing ? null : _sendMessage,
              icon: Icon(
                Icons.send,
                color: _isInitializing
                    ? colorScheme.onPrimary.withValues(alpha: 0.5)
                    : colorScheme.onPrimary,
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