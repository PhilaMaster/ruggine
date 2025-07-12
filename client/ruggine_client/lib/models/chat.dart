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

  int newMessages = 0;


  Chat({
    required this.id,
    required this.lastSender,
    required this.lastMessage,
    required this.lastTime,
    this.newMessages = 0,
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

  @override
  String toString() {
    return 'Chat(id: $id, lastSender: $lastSender, lastMessage: $lastMessage, lastTime: $lastTime, newMessages: $newMessages)';
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
  }) {
    return Chat(
      id: id ?? this.id,
      lastSender: lastSender ?? this.lastSender,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      newMessages: newMessages ?? this.newMessages,
    );
  }

  @override
  int get hashCode => id.hashCode;





}