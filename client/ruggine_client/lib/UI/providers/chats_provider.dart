
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/data/messages_repo.dart';
import 'package:ruggine_client/models/chat.dart';
import 'package:ruggine_client/models/message.dart';

import '../../data/api_client.dart';

final chatsRepositoryProvider = Provider<ChatsRepo>((ref) {
  return ChatsRepo(ApiClient());
});

final chatProvider = StateNotifierProvider<ChatsNotifier, List<Chat>?>((ref) {
  final repo = ref.read(chatsRepositoryProvider);
  return (ChatsNotifier(repo));
});



//mantains order of chats
class ChatsNotifier extends StateNotifier<List<Chat>?> {
  final ChatsRepo _repo;

  ChatsNotifier(this._repo) : super(null) {}

  List<Chat> sortChats(List<Chat> chats) {
    return chats..sort((a, b) => b.lastTime.compareTo(a.lastTime));
  }

  int get length => state?.length ?? 0;

  Chat? getChat(int index) {
    if (state == null || index < 0 || index >= state!.length) {
      return null;
    }
    return state![index];
  }

  Future<void> loadLocalChats(String uid) async {
    try {
      final chats = await _repo.getLocalChats(uid);
      if (chats.isNotEmpty) {
        state = sortChats(chats);
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

  Future<void> loadNewChats(List<String> excludedIds) async {
    try {
      var newChats = await _repo.getNewChats();
      if (newChats.isNotEmpty) {
        newChats = newChats.where((chat) => !excludedIds.contains(chat.id)).toList();
        await _repo.saveChats(newChats);
        state = sortChats([...?state, ...newChats]);
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
      state = sortChats([...?state, chat]);
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

  Future<void> resetUnreadCount(String chatId) async {
    try {
      await _repo.resetUnreadCount(chatId);
      if (state != null) {
        final index = state!.indexWhere((chat) => chat.id == chatId);
        if (index != -1) {
          final updatedChat = state![index].copyWith(id: chatId, newMessages: 0);
          state![index] = updatedChat;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error resetting unread count: $e");
      }
    }
  }

  Future<void> setUnreadCount(String chatId, int newMsgs) async {
    try {
      if (state != null) {
        final index = state!.indexWhere((chat) => chat.id == chatId);
        if (index != -1) {
          final updatedChat = state![index].copyWith(id: chatId, newMessages: state![index].newMessages + newMsgs);
          state![index] = updatedChat;
          state = sortChats([...?state]);
          await _repo.saveChats([updatedChat]);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error setting unread count: $e");
      }
    }
  }
  
  Future<void> updateLastMessage(String chatId, Message? msg,
      {int unreadCount = 0}) async {
    try {
      if (state != null) {
        final index = state!.indexWhere((chat) => chat.id == chatId);
        if (index != -1) {
          if (msg == null) {
            state![index] = state![index].copyWith(
                id: chatId,
                lastMessage: null
            );
          } else {
            state![index] = state![index].copyWith(
              id: chatId,
              lastSender: msg.senderName,
              lastMessage: msg.content,
              lastTime: msg.timestamp,
              newMessages: unreadCount,
            );
          }
        } else {
          final chatinfo = await _repo.getChatInfo(chatId);
          state!.add(chatinfo.copyWith(
            lastSender: msg?.senderName ?? '',
            lastMessage: msg?.content ?? '',
            lastTime: msg?.timestamp ?? DateTime.now(),
            newMessages: unreadCount,
          ));
        }
        state = sortChats(state!);
        final newindex = state!.indexWhere((chat) => chat.id == chatId);
        await _repo.saveChats([state![newindex]]);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error updating last message: $e");
      }
    }
  }

  Future<void> newMessage(String? chatId, Message msg,
      bool isChatOpened) async {
    if (chatId == null) {
      if (kDebugMode) {
        print("Chat ID is null, cannot add message.");
        return;
      }
    }
    await updateLastMessage(chatId!, msg);
    if (state != null) {
      final index = state!.indexWhere((chat) => chat.id == chatId);
      if (index != -1) {
        state![index] = state![index].copyWith(newMessages: state![index].newMessages + (isChatOpened ? 0 : 1));
      } else {
        // If chat not found, create a new one
        final chatinfo = await _repo.getChatInfo(chatId);
        state!.add(chatinfo.copyWith(
          lastSender: msg.senderName,
          lastMessage: msg.content,
          lastTime: msg.timestamp,
          newMessages: isChatOpened ? 0 : 1,
        ));
      }
      state = sortChats(state!);
    } else {
      final chatinfo = await _repo.getChatInfo(chatId);
      state = [chatinfo.copyWith(
        lastSender: msg.senderName,
        lastMessage: msg.content,
        lastTime: msg.timestamp,
        newMessages: isChatOpened ? 0 : 1,
      )
      ];
    }
    if (kDebugMode) {
      print("Message added to chat $chatId: ${msg.content}");
    }
  }
}