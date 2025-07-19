
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

  Future<Chat> newChat(Chat chat) async {
    try {
      final responseChat = chat.is_group
        ? await _apiClient.newChat(chat.name!)
        // il nome dell'uttente che crea la chat è sempre il primo,
        // quindi il second membro è l'altro utente
        : await _apiClient.newPrivateChat(chat.members[1]);
      Chat newChat = Chat.fromJson(responseChat.data);
      newChat = newChat.copyWith(
        created_by: chat.created_by,
      );
      if (kDebugMode) {
        print("Repo_Chat| New chat created: ${newChat}");
      }
      await LocalData.saveChats([newChat]);
      if (kDebugMode) {
        print("Repo_Chat| All chats saved locally.");
      }
      return newChat;
    } catch (e) {
      throw Exception('Error saving chats in message_repo: $e, ${e.runtimeType}, ${chat.toString()}');
    }
  }

  // Future<Chat> newPrivateChat(Chat chat) async {
  //   try {
  //     // print("MEMBERS: "+chat.members[0]+" "+chat.members[1]);
  //     final responseChat = await _apiClient.newPrivateChat(int.parse(chat.members[1]));//todo change to user name
  //     Chat newChat = Chat.fromJson(responseChat.data);
  //     // print(newChat);
  //     newChat = newChat.copyWith(
  //       created_by: chat.created_by,
  //     );
  //     if (kDebugMode) {
  //       print("Repo_Chat| New chat created: ${newChat}");
  //     }
  //     await LocalData.saveChats([newChat]);
  //     if (kDebugMode) {
  //       print("Repo_Chat| All chats saved locally.");
  //     }
  //     return newChat;
  //   } catch (e) {
  //     throw Exception('Error saving chats: $e');
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

  Future<Chat> getChatInfo(String chatId) async {
    try {
      final response = await _apiClient.getChatInfo(chatId);
      var chat = Chat.fromJson(response.data['chat']);
      final creator = response.data['members'].firstWhere(
        (member) => member['user_id'] == int.parse(chat.created_by),
        orElse: () => 'unknown',
      );

      chat.members.addAll(
        (response.data['members'] as List).map((member) => member['username'] as String).toList(),
      );
      chat = chat.copyWith(
        created_by: creator['username']
      );
      if (kDebugMode) {
        print("Chat info retrieved: ${chat.id}");
      }
      return chat;
    } catch (e) {
      throw Exception('Error fetching chat info: $e');
    }
  }

  Future<void> saveChat(Chat chat) async {
    try {
      await LocalData.saveChat(chat);
      if (kDebugMode) {
        print("Chat saved: ${chat.id}");
      }
    } catch (e) {
      throw Exception('Error saving chat: $e');
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