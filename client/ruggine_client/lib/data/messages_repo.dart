
import 'package:flutter/foundation.dart';

import '../core/storage.dart';
import '../models/chat.dart';
import 'api_client.dart';

class ChatsRepo {
  late final ApiClient _apiClient;

  ChatsRepo(this._apiClient);

  Future<List<Chat>> getLocalChats() async {
    try {
      final chats = await LocalData.getStoredChats();
      if (kDebugMode) {
        print("Retrieved ${chats.length} chats from local storage.");
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
        print("All chats saved locally.");
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
}