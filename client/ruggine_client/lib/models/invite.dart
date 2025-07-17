import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class Invite {
  @HiveField(0)
  final String groupName;
  @HiveField(1)
  final String id;
  @HiveField(2)
  final String? senderName;

  Invite({required this.groupName, required this.id, required this.senderName});

  Map<String, dynamic> toJson() {
    return {
      'group_name': groupName,
      'group_id': id,
      'sender_name': senderName,
    };
  }

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      groupName: json['group_name'] ?? '',
      id: json['group_id'] ?? '',
      senderName: json['sender_name'] ?? 'Unknown Sender',
    );
  }
}