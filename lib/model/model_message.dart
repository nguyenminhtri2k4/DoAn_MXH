class MessageModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final List<String> mediaIds;
  final String senderId;
  final String status;

  MessageModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.mediaIds,
    required this.senderId,
    required this.status,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      mediaIds: List<String>.from(map['mediaIds'] ?? []),
      senderId: map['senderId'] ?? '',
      status: map['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'mediaIds': mediaIds,
      'senderId': senderId,
      'status': status,
    };
  }
}
