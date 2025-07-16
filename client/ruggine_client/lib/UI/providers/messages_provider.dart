import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/providers/auth_provider.dart';
import 'package:ruggine_client/core/storage.dart';
import 'package:ruggine_client/data/messages_repo.dart';
import '../../data/api_client.dart';
import '../../models/message.dart';
import 'chats_provider.dart';

final messageRepositoryProvider = Provider<MessagesRepo>((ref) {
  return MessagesRepo(ApiClient());
});

final msgProvider = StateNotifierProvider<MessagesNotifier, List<Message>?>((ref){
  final repo = ref.read(messageRepositoryProvider);
  final chatNotifier = ref.read(chatProvider.notifier);
  final authNotifier = ref.read(authProvider.notifier);
  return (MessagesNotifier(repo, chatNotifier, authNotifier));
});



//mantains order of chats
class MessagesNotifier extends StateNotifier<List<Message>?> {
  final MessagesRepo _repo;
  final ChatsNotifier _chatNotifier;
  final AuthNotifier _authNotifier;
  String? _chatId;

  MessagesNotifier(this._repo, this._chatNotifier, this._authNotifier)
      : super(null);

  int get length => state?.length ?? 0;

  Message? getMessage(int index) {
    if (state == null || index < 0 || index >= state!.length) {
      return null;
    }
    return state![index];
  }

  List<Message> sortMessages(List<Message> messages) {
    // Remove duplicates by ID and sort by timestamp in descending order
    final uniqueMessages = messages.toSet().toList();
    uniqueMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return uniqueMessages;
  }

  Future<void> loadNewMessages(String uid) async {
    final lastUpdate = await LocalData.getLastMessage(uid);
    final Map<String, List<Message>> newMessages = await _repo.retrieveNewMessages(lastUpdate);
    LocalData.setLastMessage(DateTime.now());
    if (newMessages.isEmpty) {
      if (kDebugMode) {
        print("No new message pending.");
      }
      return;
    }
    for (var chat in newMessages.entries) {
      final chatId = chat.key;
      final msglist = chat.value;
      msglist.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      await _repo.saveMessages(chatId, msglist);
      await updateMessages(chatId, msglist);
    }
  }

  Future<void> updateMessages(String chatId, List<Message> messages) async {
    try {
      bool currentChat = _chatId == chatId;
      if (_chatId != null && currentChat) {
        // im in the chat that received new messages display them
        if (state == null) {
          state = messages;
        } else {
          state = [...?state, ...messages];
        }
      }
      if (messages.isNotEmpty) {
        await _chatNotifier.updateLastMessage(chatId, messages.last,
            unreadCount: currentChat ? 0 : messages.length);
      }

    }catch (e) {
      if (kDebugMode) {
        print("Error updating messages: $e");
      }
    }
  }

  Future<void> sendMessage(String chatId, String content) async {
    try {
      final mex = await _repo.sendMessage(chatId, content);
      await _chatNotifier.updateLastMessage(chatId, mex);
      if (state == null) {
        state = [mex];
      } else {
        state = [...?state, mex];
      }

    } catch (e) {
      if (kDebugMode) {
        print("Error adding message: $e");
      }
    }
  }

  Future<void> loadLocalMessages(String chatId) async {
    // Simulate delay without blocking the UI thread
    //await Future.delayed(Duration(seconds: 5));
    try {
      if (_chatId != null && _chatId != chatId) {
        // Reset state if the chat ID changes
        state = [];
      }
      if (_chatId == chatId) {
        // If the chat ID is the same, no need to reload from local storage
        return;
      }
      _chatId = chatId; // Update the current chat ID
      final messages = await _repo.getLocalMessages(chatId);
      // Update the chat's last message if messages exist
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        await _chatNotifier.updateLastMessage(chatId, lastMessage);
        // If state is null, initialize it with the messages
        if (state != null) {
          state = [...?state, ...messages];
        } else {
          state = messages;
        }
      } else if (state == null) {
        state = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading local messages: $e");
      }
    }
  }



  Future<void> resetState(String id) async {
    state = [];
    if (kDebugMode) {
      print("Messages of chat $id state reset.");
    }
  }

  Future<void> newMessage(String? chatId, Message message) async{
    if (chatId == null) {
      if (kDebugMode) {
        print("Chat ID is null, cannot add message.");
        return;
      }
    }
    if (_chatId == chatId) {
      if (state == null) {
        state = [message];
      } else {
        state = [...?state, message];
      }
    }
    await _repo.saveMessage(chatId, message);
    await _chatNotifier.newMessage(chatId, message, _chatId == chatId);
    if (kDebugMode) {
      print("Message added to chat $chatId: ${message.content}");
    }
  }

}