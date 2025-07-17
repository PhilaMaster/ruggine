

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruggine_client/UI/providers/chats_provider.dart';
import 'package:ruggine_client/data/invites_repo.dart';

import '../../data/api_client.dart';
import '../../models/invite.dart';

final invitesRepositoryProvider = Provider<InvitesRepo>((ref) {
  return InvitesRepo(ApiClient());
});

final invitesProvider = StateNotifierProvider<InvitesNotifier, List<Invite>?>((ref) {
  final repo = ref.read(invitesRepositoryProvider);
  return (InvitesNotifier(repo, ref.read(chatProvider.notifier)));
});



//mantains order of chats
class InvitesNotifier extends StateNotifier<List<Invite>?> {
  final InvitesRepo _repo;
  final ChatsNotifier _chatsNotifier;

  InvitesNotifier(this._repo, this._chatsNotifier) : super(null) {}

  List<Invite> sortInvites(List<Invite> invites) {
    return invites..sort((a, b) => a.groupName.compareTo(b.groupName));
  }

  int get length => state?.length ?? 0;

  Invite? getInvite(int index) {
    if (state == null || index < 0 || index >= state!.length) {
      return null;
    }
    return state![index];
  }

  Future<void> receiveInvite(Invite invite) async {
    try {
      if (state == null) {
        state = [invite];
      } else {
        final updatedInvites = [...state!, invite];
        state = sortInvites(updatedInvites);
      }
      if (kDebugMode) {
        print("Invite received: ${invite.groupName}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error receiving invite: $e");
      }
    }
  }

  Future<void> loadInvites(String uid) async {
    try {
      final invites = await _repo.getInvites(uid);
      if (invites.isNotEmpty) {
        state = sortInvites(invites);
      } else {
        state = [];
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error loading invites: $e");
      }
      state = [];
    }
  }

  Future<void> acceptInvite(String inviteId) async {
    try {
      final chatinfo = await _repo.acceptInvite(inviteId);
      if (kDebugMode) {
        print("Invite accepted for: $chatinfo");
      }
      state = state?.where((invite) => invite.id != inviteId).toList();
      _chatsNotifier.addChat(chatinfo);
    } catch (e) {
      if (kDebugMode) {
        print("Error accepting invite: $e");
      }
    }
  }
  Future<void> declineInvite(String inviteId) async {
    try {
      await _repo.declineInvite(inviteId);
      if (kDebugMode) {
        print("Invite declined: $inviteId");
      }
      state = state?.where((invite) => invite.id != inviteId).toList();
    } catch (e) {
      if (kDebugMode) {
        print("Error declining invite: $e");
      }
    }
  }

  Future<void> sendInvite(String receiver, String chatname) async {
    try {
      await _repo.sendInvite(chatname, receiver);
    } catch (e) {
      if (kDebugMode) {
        print("Error sending invite: $e");
      }
      rethrow;
    }
  }


}