import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:ruggine_client/core/const.dart';

import '../UI/providers/chats_provider.dart';
import '../models/chat.dart';

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
      print("Retrieved ${box.length} chats from local storage.");
    }
    return box.values.toList();
  }

  static Future<void> saveChatIfNotExists(Chat chat) async {
    final box = await Hive.openBox<Chat>(kChatsBox);
    if (!box.containsKey(chat.id)) {
      await box.put(chat.id, chat);
      if (kDebugMode) {
        print("Chat salvata: ${chat.id}");
      }
    } else {
      if (kDebugMode) {
        print("Chat già presente: ${chat.id}");
      }
    }
  }

  static Future<void> saveChats(List<Chat> chats) async {
    for (var chat in chats) {
      await saveChatIfNotExists(chat);
    }
    if (kDebugMode) {
      print("Tutte le chat salvate localmente.");
    }
  }

  static Future<void> deleteChat(String chatId) async {
    final box = await Hive.openBox<Chat>(kChatsBox);
    if (box.containsKey(chatId)) {
      await box.delete(chatId);
      if (kDebugMode) {
        print("Chat rimossa: $chatId");
      }
    } else {
      if (kDebugMode) {
        print("Chat non trovata: $chatId");
      }
    }
  }

}