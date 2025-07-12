
import 'package:flutter/foundation.dart';

import '../core/storage.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'api_client.dart';

class ChatsRepo {
  late final ApiClient _apiClient;

  ChatsRepo(this._apiClient);

  Future<List<Chat>> getLocalChats() async {
    try {
      final chats = await LocalData.getStoredChats();
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

  Future<List<Chat>> loadAllChats() async {
    try {
      final localChats = await getLocalChats();
      if (kDebugMode) {
        print("Loaded ${localChats.length} local chats.");
      }
      final newChats = await getNewChats();
      if (kDebugMode) {
        print("Loaded ${newChats.length} new chats from API.");
      }
      await saveChats(newChats);
      return [...localChats, ...newChats];
    } catch (e) {
      throw Exception('Error loading all chats: $e');
    }
  }

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
      return msgs;
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<Message> sendMessage(String chatId, String content) async {
    try {
      final res = await _apiClient.sendMessage(chatId, content);
      if (kDebugMode) {
        print("Message sent: ${content}");
      }
      final newMessage = Message.fromJson(res.data);
      await LocalData.saveMessage(chatId, newMessage);
      return newMessage;
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}