import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  return (MessagesNotifier(repo, chatNotifier));
});



//mantains order of chats
class MessagesNotifier extends StateNotifier<List<Message>?> {
  final MessagesRepo _repo;
  final ChatsNotifier _chatNotifier;
  String? _chatId;

  MessagesNotifier(this._repo, this._chatNotifier) : super(null) {}

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

  Future<void> loadMessages(String chatId) async {
    try {
      if (_chatId != null && _chatId != chatId) {
        // Reset state if the chat ID changes
        state = [];
      }
      _chatId = chatId; // Update the current chat ID
      final messages = await _repo.getMessages(chatId);

      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        // If state is null, initialize it with the messages
        if (state != null) {
          state = sortMessages([...?state, ...messages]);
        } else {
          state = messages;
        }
        if (lastMessage == state?.last) {
          await _chatNotifier.updateLastMessage(chatId, lastMessage);
        }
      } else if (state == null) {
        state = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading messages: $e");
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

}