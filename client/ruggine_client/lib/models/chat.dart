
import 'package:hive/hive.dart';

part 'chat.g.dart';

@HiveType(typeId: 0, adapterName: 'ChatAdapter')
class Chat {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String lastSender;
  @HiveField(2)
  final String lastMessage;
  @HiveField(3)
  final DateTime lastTime;

  Chat({
    required this.id,
    required this.lastSender,
    required this.lastMessage,
    required this.lastTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lastSender': lastSender,
      'lastMessage': lastMessage,
      'lastTime': lastTime.toIso8601String(),
    };
  }
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] ?? '',
      lastSender: json['lastSender'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastTime: DateTime.parse(json['lastTime'] ?? DateTime.now().toIso8601String()),
    );
  }
}