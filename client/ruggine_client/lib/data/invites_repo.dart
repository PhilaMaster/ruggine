import 'package:flutter/foundation.dart';
import 'package:ruggine_client/models/invite.dart';

import '../models/chat.dart';
import 'api_client.dart';

class InvitesRepo {
  late final ApiClient _apiClient;

  InvitesRepo(this._apiClient);

  Future<List<Invite>> getInvites(String uid) async {
    try {
      final response = await _apiClient.getInvites(uid);
      if (kDebugMode) {
        print("Retrieved ${response.data.length} invites from API.");
      }
      return (response.data as List)
          .map((invite) => Invite.fromJson(invite))
          .toList();
    } catch (e) {
      throw Exception('Error fetching invites: $e');
    }
  }

  Future<Chat> acceptInvite(String inviteId) async {
    try {
      final Chat response = Chat.fromJson((await _apiClient.acceptInvite(inviteId)).data);
      if (kDebugMode) {
        print("Invite accepted: $inviteId");
      }
      return response;
    } catch (e) {
      throw Exception('Error accepting invite: $e');
    }

  }

  Future<void> declineInvite(String inviteId) async {
    try {
      final response = await _apiClient.declineInvite(inviteId);
      if (kDebugMode) {
        print("Invite declined: $inviteId");
      }
    } catch (e) {
      throw Exception('Error declining invite: $e');
    }
  }

  Future<void> sendInvite(String groupName) async {
    try {
      final response = await _apiClient.sendInvite(groupName);
      if (kDebugMode) {
        print("Invite sent to group: $groupName");
      }
    } catch (e) {
      throw Exception('Error sending invite: $e');
    }
  }
}