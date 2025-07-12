

import 'package:hive/hive.dart';

@HiveType(typeId: 3, adapterName: 'MessageAdapter')
class Message {

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String content;
  @HiveField(2)
  final DateTime timestamp;
  @HiveField(3)
  final String senderId;

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.senderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderId,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      senderId: json['senderId'],
    );
  }
}