
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/providers/invites_provider.dart';
import 'package:ruggine_client/data/messages_repo.dart';
import 'package:ruggine_client/models/chat.dart';
import 'package:ruggine_client/models/message.dart';

import '../../data/api_client.dart';

final chatsRepositoryProvider = Provider<ChatsRepo>((ref) {
  return ChatsRepo(ApiClient());
});

final chatProvider = StateNotifierProvider<ChatsNotifier, List<Chat>?>((ref) {
  final repo = ref.read(chatsRepositoryProvider);
  return (ChatsNotifier(repo, ref));
});



//mantains order of chats
class ChatsNotifier extends StateNotifier<List<Chat>?> {
  final ChatsRepo _repo;
  Ref _ref;

  ChatsNotifier(this._repo, this._ref) : super(null) {}

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


  Future<void> addChat(Chat chat) async {
    await _repo.saveChat(chat);
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
          await _repo.saveChat(updatedChat);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error setting unread count: $e");
      }
    }
  }
  
  Future<void> updateLastMessage(String chatId, Message? msg,
      {int newUnread = 0}) async {
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
              newMessages: state![index].newMessages + newUnread,
            );
          }
        } else {
          final chatinfo = await _repo.getChatInfo(chatId);
          state!.add(chatinfo.copyWith(
            lastSender: msg?.senderName ?? '',
            lastMessage: msg?.content ?? '',
            lastTime: msg?.timestamp ?? DateTime.now(),
            newMessages: (msg != null) ? 1 : 0,
          ));
        }
        state = sortChats([...state!]);
        final newindex = state!.indexWhere((chat) => chat.id == chatId);
        await _repo.saveChat(state![newindex]);
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
    await updateLastMessage(chatId!, msg, newUnread: isChatOpened ? 0 : 1);
    if (kDebugMode) {
      print("Message added to chat $chatId: ${msg.content}");
    }
  }

  Future<List<String>> newChat(Chat newChat) async{
    if (kDebugMode) {
      print("Creating new chat: ${newChat.members}");
    }
    try {
      Chat newchatresponse;
      if (newChat.is_group) {
        newchatresponse = await _repo.newChat(newChat);
      } else {
        newchatresponse = await _repo.newPrivateChat(newChat);
      }
      // print("sosoosososos");
      if (state == null) {
        state = [newchatresponse];
      } else {
        final updatedChats = [...state!, newchatresponse];
        state = sortChats(updatedChats);
      }

      if (newChat.is_group){
        final List<String> okInvites = [];
        for (String username in newChat.members){
          if (kDebugMode) {
            print("New chat member: $username");
          }
          if (username != newChat.created_by) {
            await _ref.watch(invitesProvider.notifier).sendInvite(
              username,
              newChat.name!,
            ).then((_) {
              if (kDebugMode) {
                print("Invite sent to $username for chat ${newChat.name}");
              }
              okInvites.add(username);
            }).catchError((_) {
              if (kDebugMode) {
                print("Error sending invite to $username for chat ${newChat.name}");
              }
            });
          }
        }
        return okInvites;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print("Error adding new chat: $e");
      }
      return [];
    }

  }

   void cleanup() {
    if (kDebugMode) {
      print("Cleaning up chat state...");
    }
    try {
      state = [];
    } catch (e) {
      if (kDebugMode) {
        print("Error during cleanup: $e");
      }
    }
  }
}
