import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:ruggine_client/core/const.dart';

import '../models/chat.dart';
import '../models/message.dart';

class SecureStorage{
  static const storage = FlutterSecureStorage();

  static Future<String?> readToken() async {
    return await storage.read(key: kJwtTokenKey);
  }

  static Future<void> writeToken(String token) async {
    await storage.write(key: kJwtTokenKey, value: token);
  }

  static Future<void> deleteToken() async {
    await storage.delete(key: kJwtTokenKey);
  }

  static Future<String> getUserName() async{
    final token = await readToken();
    if (token == null) {
      return 'Unknown User';
    }
    final decodedToken = JwtDecoder.decode(token);
    return decodedToken['username'] ??
        'Unknown User'; // Replace with actual username retrieval logic
  }
}

class LocalData{

  static Future<String> _getUserId() async {
    final token = await SecureStorage.readToken();
    if (token == null) {
      throw Exception('User not authenticated. No token found.');
    }
    return JwtDecoder.decode(token)['user_id'].toString(); // Replace with actual user ID retrieval logic
  }

  //store all chats and messages in a local database
  static Future<List<Chat>> getStoredChats(String uid) async {
    final box = await Hive.openBox<Chat>(uid + kChatsBox).catchError( (_) {
      return Hive.openBox<Chat>(uid + kChatsBox);
    });
    if (kDebugMode) {
      print("Storage| Retrieved ${box.length} chats from local storage.");
    }
    return box.values.toList();
  }

  static Future<void> saveChat(Chat chat) async {
    final userId = await _getUserId();
    final box = await Hive.openBox<Chat>(userId + kChatsBox);
    await box.put(chat.id, chat);
    if (kDebugMode) {
      print("Storage| Chat salvata: ${chat.id}, ${chat.is_group}");
    }
  }

  static Future<void> saveChats(List<Chat> chats) async {
    final userId = await _getUserId();
    final box = await Hive.openBox<Chat>(userId + kChatsBox);
    for (var chat in chats){
      await box.put(chat.id, chat);
      if (kDebugMode) {
        print("Storage| Chat salvata: ${chat.id}");
      }
    }
  }

  static Future<void> deleteChat(String chatId) async {
    final userId = await _getUserId();
    final box = await Hive.openBox<Chat>(userId + kChatsBox);
    final msgBox = await Hive.openBox<Message>(userId + chatId + kMessagesBox);
    if (box.containsKey(chatId)) {
      await box.delete(chatId);
      await msgBox.clear(); // Clear messages associated with the chat
      if (kDebugMode) {
        print("Chat rimossa: $chatId");
      }
    } else {
      if (kDebugMode) {
        print("Chat non trovata: $chatId");
      }
    }
  }

  static Future<List<Message>> getStoredMessages(String chatId) async {
    final userId = await _getUserId();
    final box = await Hive.openBox<Message>(userId + chatId + kMessagesBox);
    if (kDebugMode) {
      print("Retrieved ${box.length} messages for chat $chatId from local storage.");
    }
    return box.values.toList();
  }

  static Future<void> saveMessage(String chatId, Message message) async {
    final userId = await _getUserId();
    final box = await Hive.openBox<Message>(userId + chatId + kMessagesBox);
    final exists = box.values.any((msg) => msg.id == message.id);
    if (exists) {
      if (kDebugMode) {
        print("Message already exists: ${message.id} for chat $chatId");
      }
      return; // Message already exists, no need to save again
    }
    await box.add(message);
    if (kDebugMode) {
      print("Message saved: ${message.id} for chat $chatId");
    }
  }

  static Future<void> saveMessages(String chatId, List<Message> messages) async {
    final userId = await _getUserId();
    final box = await Hive.openBox<Message>(userId + chatId + kMessagesBox);
    for (var message in messages) {
      final exists = box.values.any((msg) => msg.id == message.id);
      if (!exists) {
        await box.add(message);
        if (kDebugMode) {
          print("Message saved: ${message.id} for chat $chatId");
        }
      } else {
        if (kDebugMode) {
          print("Message already exists: ${message.id} for chat $chatId");
        }
      }
    }
  }

  static Future<void> resetUnreadCount(String chatId) async {
    final userId = await _getUserId();
    final box = await Hive.openBox<Chat>(userId + kChatsBox);
    if (box.containsKey(chatId)) {
      var chat = box.get(chatId);
      if (chat != null) {
        chat = chat.copyWith(newMessages: 0);
        await box.put(chatId, chat);
        if (kDebugMode) {
          print("Storage| Unread count reset for chat: $chatId");
        }
      } else {
        if (kDebugMode) {
          print("Chat not found: $chatId");
        }
      }
    } else {
      if (kDebugMode) {
        print("Chat not found in local storage: $chatId");
      }
    }
  }

  static Future<DateTime?> getLastMessage(String uid) async{
    final box = await Hive.openBox<DateTime>(uid + kLastUpdateBox);
    DateTime? lastMessage = box.get(uid, defaultValue: null);
    if (kDebugMode) {
      print("Storage| Last message timestamp: $lastMessage");
    }
    return lastMessage;
  }

  static Future<void> setLastMessage(DateTime timestamp) async {
    final userId = await _getUserId();
    final box = await Hive.openBox<DateTime>(userId + kLastUpdateBox);
    await box.put(userId, timestamp);
    if (kDebugMode) {
      print("Storage| Last message timestamp updated: $timestamp");
    }
  }

}