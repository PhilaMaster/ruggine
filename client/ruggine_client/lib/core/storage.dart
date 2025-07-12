import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
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
}

class LocalData{
  //store all chats and messages in a local database
  static Future<List<Chat>> getStoredChats() async {
    final box = await Hive.openBox<Chat>(kChatsBox);
    if (kDebugMode) {
      print("Storage| Retrieved ${box.length} chats from local storage.");
    }
    return box.values.toList();
  }

  static Future<void> saveChat(Chat chat) async {
    final box = await Hive.openBox<Chat>(kChatsBox);
    await box.put(chat.id, chat);
    if (kDebugMode) {
      print("Storage| Chat salvata: ${chat.id}");
    }
  }

  static Future<void> saveChats(List<Chat> chats) async {
    for (var chat in chats) {
      await saveChat(chat);
    }
  }

  static Future<void> deleteChat(String chatId) async {
    final box = await Hive.openBox<Chat>(kChatsBox);
    final msgBox = await Hive.openBox<Message>(chatId + kMessagesBox);
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
    final box = await Hive.openBox<Message>(chatId + kMessagesBox);
    if (kDebugMode) {
      print("Retrieved ${box.length} messages for chat $chatId from local storage.");
    }
    return box.values.toList();
  }

  static Future<void> saveMessage(String chatId, Message message) async {
    final box = await Hive.openBox<Message>(chatId + kMessagesBox);
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

  static Future<void> resetUnreadCount(String chatId) async {
    final box = await Hive.openBox<Chat>(kChatsBox);
    if (box.containsKey(chatId)) {
      final chat = box.get(chatId);
      if (chat != null) {
        chat.newMessages = 0; // Reset unread count
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

}