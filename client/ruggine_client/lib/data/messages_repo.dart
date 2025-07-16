
import 'package:flutter/foundation.dart';
import 'package:ruggine_client/UI/providers/auth_provider.dart';

import '../core/storage.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'api_client.dart';

class ChatsRepo {
  late final ApiClient _apiClient;

  ChatsRepo(this._apiClient);

  Future<List<Chat>> getLocalChats(String uid) async {
    try {
      final chats = await LocalData.getStoredChats(uid);
      if (kDebugMode) {
        print("Repo_Chat| Retrieved ${chats.length} chats from local storage.");
      }
      return chats;
    } catch (e) {
      throw Exception('Error fetching local chats: $e');
    }
  }

  Future<List<Chat>> getNewChats() async {
    try {
      final response = await _apiClient.getChats();
      // Assuming the response data is a list of chat objects
      return (response.data as List).map((chat) => Chat.fromJson(chat)).toList();
    } catch (e) {
      throw Exception('Error fetching chats: $e');
    }
  }

  Future<void> saveChats(List<Chat> chats) async {
    try {
      await LocalData.saveChats(chats);
      if (kDebugMode) {
        print("Repo_Chat| All chats saved locally.");
      }
    } catch (e) {
      throw Exception('Error saving chats: $e');
    }
  }

  // Future<List<Chat>> loadAllChats() async {
  //   try {
  //     final localChats = await getLocalChats();
  //     if (kDebugMode) {
  //       print("Loaded ${localChats.length} local chats.");
  //     }
  //     final newChats = await getNewChats();
  //     if (kDebugMode) {
  //       print("Loaded ${newChats.length} new chats from API.");
  //     }
  //     await saveChats(newChats);
  //     return [...localChats, ...newChats];
  //   } catch (e) {
  //     throw Exception('Error loading all chats: $e');
  //   }
  // }

  Future<void> removeChat(String id) async {
    try {
      LocalData.deleteChat(id);
      if (kDebugMode) {
        print("Chat removed: $id");
      }
    } catch (e) {
      throw Exception('Error removing chat: $e');
    }
  }

  Future<void> resetUnreadCount(String chatId) async {
    try {
      await LocalData.resetUnreadCount(chatId);
      if (kDebugMode) {
        print("Repo| Unread count reset for chat: $chatId");
      }
    } catch (e) {
      throw Exception('Error resetting unread count: $e');
    }
  }
}


class MessagesRepo {
  late final ApiClient _apiClient;

  MessagesRepo(this._apiClient);


  Future<List<Message>> getLocalMessages(String chatId) async {
    try {
      final messages = await LocalData.getStoredMessages(chatId);
      if (kDebugMode) {
        print("Retrieved ${messages.length} messages for chat $chatId from local storage.");
      }
      return messages;
    } catch (e) {
      throw Exception('Error fetching local messages: $e');
    }
  }

  Future<List<Message>> getMessages(String chatId) async {
    try {
      final response = await _apiClient.getMessages(chatId);
      final msgs = (response.data as List).map((msg) => Message.fromJson(msg)).toList();
      msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (kDebugMode) {
        print("Retrieved ${msgs} messages for chat $chatId from API.");
      }
      // Save messages to local storage
      for (var msg in msgs) {
        await LocalData.saveMessage(chatId, msg);
      }
      return msgs;
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<Message> sendMessage(String chatId, String content) async {
    try {
      final res = await _apiClient.sendMessage(chatId, content);
      final newMessage = Message.fromJson(res.data);
      if (kDebugMode) {
        print("Message sent: ${newMessage}");
      }
      final updatedMessage = newMessage.copyWith(
        senderName: await SecureStorage.getUserName(),
      );
      await LocalData.saveMessage(chatId, updatedMessage);
      return updatedMessage;
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<void> saveMessage(String? chatId, Message message) async {
    if (chatId == null) {
      throw Exception('Chat ID cannot be null');
    }
    try {
      await LocalData.saveMessage(chatId, message);
      if (kDebugMode) {
        print("Message saved: ${message.id} for chat $chatId");
      }
    } catch (e) {
      throw Exception('Error saving message: $e');
    }
  }

  Future<void> saveMessages(String chatId, List<Message> messages) async {
    if (chatId.isEmpty) {
      throw Exception('Chat ID cannot be empty');
    }
    try {
      await LocalData.saveMessages(chatId, messages);
      if (kDebugMode) {
        print("Messages saved for chat $chatId");
      }
    } catch (e) {
      throw Exception('Error saving messages: $e');
    }
  }


  Future<Map<String, List<Message>>> retrieveNewMessages(DateTime? lastUpdate) async{
    try {
      final response = await _apiClient.getNewMessages(lastUpdate);
      if (response.data == null || response.data.isEmpty) {
        if (kDebugMode) {
          print("No new messages since $lastUpdate.");
        }
        return {};
      }
      final Map<String, List<Message>> newMessages = (response.data as List)
          .map((msg) => Message.fromJson(msg))
          .map((mex) => (mex.chatId, mex))
          .toList()
          .fold({}, (acc, tuple) {
        acc.putIfAbsent(tuple.$1, () => []).add(tuple.$2);
        return acc;
      });
      if (kDebugMode) {
        print("Retrieved ${newMessages.length} new messages since $lastUpdate.");
      }
      return newMessages;
    } catch (e) {
      throw Exception('Error retrieving new messages: $e');
    }
  }


}