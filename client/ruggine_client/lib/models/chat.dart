import 'package:hive/hive.dart';

part 'chat.g.dart';

@HiveType(typeId: 0, adapterName: 'ChatAdapter')
class Chat {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String lastSender;
  @HiveField(2)
  final String? lastMessage;
  @HiveField(3)
  final DateTime lastTime;
  @HiveField(4)
  final int newMessages; // Number of new messages since last read
  @HiveField(5)
  final String? name; // Optional group name for group chats
  @HiveField(6)
  final String created_by;
  @HiveField(7)
  final List<String> members;
  @HiveField(8)
  final bool is_group;
  @HiveField(9)
  final DateTime created_at;


  Chat({
    this.name,
    required this.is_group,
    required this.created_by,
    required this.created_at,
    required this.members,
    required this.id,
    required this.lastSender,
    required this.lastMessage,
    required this.lastTime,
    this.newMessages = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'].toString(),
      lastSender: json['lastSender'] ?? '',
      lastMessage: json['lastMessage'],
      lastTime: DateTime.parse(json['lastTime'] ?? DateTime.now().toIso8601String()),
      newMessages: json['newMessages'] ?? 0,
      name: json['name'],
      created_by: json['created_by'].toString(),
      members: List<String>.from(json['members'] ?? []),
      is_group: json['is_group'] ?? false,
      created_at: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, lastSender: $lastSender, lastMessage: $lastMessage, lastTime: $lastTime, newMessages: $newMessages, name: $name, created_by: $created_by, members: $members, is_group: $is_group, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Chat &&
        other.id == id;
  }

  Chat copyWith({
    String? id,
    String? lastSender,
    String? lastMessage,
    DateTime? lastTime,
    int? newMessages,
    String? created_by,
    List<String>? members,
  }) {
    return Chat(
      id: id ?? this.id,
      lastSender: lastSender ?? this.lastSender,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      newMessages: newMessages ?? this.newMessages,
      name: name,
      created_by: created_by ?? this.created_by,
      members: members ?? this.members,
      // Copy members list
      is_group: is_group ?? false,
      created_at: created_at,
    );
  }

  @override
  int get hashCode => id.hashCode;

  toJson() {
    return {
      'id': id,
      'lastSender': lastSender,
      'lastMessage': lastMessage,
      'lastTime': lastTime.toIso8601String(),
      'newMessages': newMessages,
      'name': name,
      'created_by': created_by,
      'members': members,
      'is_group': is_group,
      'created_at': created_at.toIso8601String(),
    };
  }





}