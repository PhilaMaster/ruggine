import 'package:flutter/foundation.dart';
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
  @HiveField(4)
  final String chatId;

  Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.senderName,
    required this.chatId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sent_at': timestamp.toUtc().toIso8601String(),
      'senderName': senderName,
      'chat_id': chatId,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print("Creating Message from JSON: $json");
    }

    // Parse timestamp from server (assume UTC) and convert to local time
    DateTime parsedTimestamp;
    String timestampStr = json['sent_at'];
    parsedTimestamp = DateTime.parse(timestampStr).toLocal();

    return Message(
      id: json['id'].toString(),
      content: json['content'],
      timestamp: parsedTimestamp,
      senderName: json['username'] ?? json['sender_id'].toString() ??
          'Unknown Sender',
      chatId: json['chat_id'].toString(),
    );
  }

  @override
  toString() {
    return 'Message(id: $id, content: $content, timestamp: $timestamp, senderName: $senderName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Message copyWith({required String senderName}) {
    return Message(
      id: id,
      content: content,
      timestamp: timestamp,
      senderName: senderName,
      chatId: chatId,
    );
  }

}