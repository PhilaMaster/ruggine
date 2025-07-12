import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 3, adapterName: 'MessageAdapter')
class Message {

  @HiveField(0)
  final String id;
  @HiveField(1)
  final String content;
  @HiveField(2)
  final DateTime timestamp;
  @HiveField(3)
  final String senderName;

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.senderName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'senderId': senderName,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'].toString(),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      senderName: json['senderName'] ?? 'Unknown Sender',
    );
  }
}