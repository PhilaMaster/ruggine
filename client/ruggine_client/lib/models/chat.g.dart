// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatAdapter extends TypeAdapter<Chat> {
  @override
  final int typeId = 0;

  @override
  Chat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Chat(
      name: fields[5] as String?,
      is_group: fields[8] as bool,
      created_by: fields[6] as String,
      created_at: fields[9] as DateTime,
      members: (fields[7] as List).cast<String>(),
      id: fields[0] as String,
      lastSender: fields[1] as String,
      lastMessage: fields[2] as String?,
      lastTime: fields[3] as DateTime,
      newMessages: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Chat obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lastSender)
      ..writeByte(2)
      ..write(obj.lastMessage)
      ..writeByte(3)
      ..write(obj.lastTime)
      ..writeByte(4)
      ..write(obj.newMessages)
      ..writeByte(5)
      ..write(obj.name)
      ..writeByte(6)
      ..write(obj.created_by)
      ..writeByte(7)
      ..write(obj.members)
      ..writeByte(8)
      ..write(obj.is_group)
      ..writeByte(9)
      ..write(obj.created_at);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
