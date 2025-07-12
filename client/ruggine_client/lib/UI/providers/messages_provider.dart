import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/data/messages_repo.dart';
import 'package:ruggine_client/models/chat.dart';

import '../../data/api_client.dart';
import '../../models/message.dart';

final messageRepositoryProvider = Provider<MessagesRepo>((ref) {
  return MessagesRepo(ApiClient());
});

final msgProvider = StateNotifierProvider<MessagesNotifier, List<Message>?>((ref) {
  final repo = ref.read(messageRepositoryProvider);
  return (MessagesNotifier(repo));
});



//mantains order of chats
class MessagesNotifier extends StateNotifier<List<Message>?> {
  final MessagesRepo _repo;

  MessagesNotifier(this._repo) : super(null) {}


  int get length => state?.length ?? 0;

  Message? getMessage(int index) {
    if (state == null || index < 0 || index >= state!.length) {
      return null;
    }
    return state![index];
  }

  Future<void> loadMessages(String chatId) async {
    try {
      final messages = await _repo.getMessages(chatId);
      if (messages.isNotEmpty) {
        state = messages;
      } else {
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
      final messages = await _repo.getLocalMessages(chatId);
      if (messages.isNotEmpty) {
        state = messages;
      } else {
        state = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading local messages: $e");
      }
    }
  }

}