import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class MockInvite {
  @HiveField(0)
  final String groupName;

  MockInvite({required this.groupName});

  Map<String, dynamic> toJson() {
    return {
      'groupName': groupName,
    };
  }

  factory MockInvite.fromJson(Map<String, dynamic> json) {
    return MockInvite(
      groupName: json['groupName'] ?? '',
    );
  }
}