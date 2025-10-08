class ChatModel {
  final String id;
  final String lastMessage;
  final List<String> members;
  final String type;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.lastMessage,
    required this.members,
    required this.type,
    required this.updatedAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      lastMessage: map['lastMessage'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      type: map['type'] ?? 'private',
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lastMessage': lastMessage,
      'members': members,
      'type': type,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
