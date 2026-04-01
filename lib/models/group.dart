import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Group {
  Group({
    required this.name,
    required this.createdBy,
    required this.members,
    String? id,
    String? inviteCode,
  })  : id = id ?? _uuid.v4(),
        inviteCode = inviteCode ?? _generateCode();

  final String id;
  final String name;
  final String createdBy;
  final List<String> members;
  final String inviteCode;

  // Generate a random 6-character invite code
  static String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = List.generate(
        6, (i) => chars[DateTime.now().microsecondsSinceEpoch % chars.length + i % chars.length >= chars.length
            ? (DateTime.now().microsecondsSinceEpoch % chars.length + i % chars.length) - chars.length
            : DateTime.now().microsecondsSinceEpoch % chars.length + i % chars.length]);
    return random.join();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'members': members,
      'inviteCode': inviteCode,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      name: map['name'] as String,
      createdBy: map['createdBy'] as String,
      members: List<String>.from(map['members']),
      inviteCode: map['inviteCode'] as String,
    );
  }
}