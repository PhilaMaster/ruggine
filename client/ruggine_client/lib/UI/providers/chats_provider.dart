
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/data/messages_repo.dart';
import 'package:ruggine_client/models/chat.dart';

import '../../data/api_client.dart';

final chatsRepositoryProvider = Provider<ChatsRepo>((ref) {
  return ChatsRepo(ApiClient());
});

final chatProvider = StateNotifierProvider<ChatsNotifier, List<Chat>?>((ref) {
  final repo = ref.read(chatsRepositoryProvider);
  return (ChatsNotifier(repo));
});



class ChatsNotifier extends StateNotifier<List<Chat>?> {
  final ChatsRepo _repo;

  ChatsNotifier(this._repo) : super(null) {
    _loadLocalChats();
  }

  int get length => state?.length ?? 0;

  Chat? getChat(int index) {
    if (state == null || index < 0 || index >= state!.length) {
      return null;
    }
    return state![index];
  }

  Future<void> _loadLocalChats() async {
    try {
      final chats = await _repo.getLocalChats();
      if (chats.isNotEmpty) {
        state = chats;
      } else {
        state = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading local chats: $e");
      }
      state = [];
    }
  }

  Future<void> loadNewChats() async {
    try {
      final newChats = await _repo.getNewChats();
      if (newChats.isNotEmpty) {
        await _repo.saveChats(newChats);
        state = [...?state, ...newChats];
      } else {
        if (kDebugMode) {
          print("No new chats found.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading new chats: $e");
      }
    }
  }

  Future<void> addChat(Chat chat) async {
    await _repo.saveChats([chat]);
    if (state == null) {
      state = [chat];
    } else {
      state = [...?state, chat];
    }
  }

  Future<void> removeChat(String chatId) async {
    try {
      await _repo.removeChat(chatId);
      if (state != null) {
        state = state!.where((chat) => chat.id != chatId).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error removing chat: $e");
      }
    }
  }

}