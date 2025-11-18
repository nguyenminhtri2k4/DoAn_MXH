import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String authorId;
  final String mediaUrl;
  final String mediaType; // 'image', 'video', or 'text'
  final String content; // Dùng cho story dạng text
  final String backgroundColor; // Dùng cho story dạng text
  final DateTime createdAt;
  final List<String> views; 

  // --- THÊM CÁC TRƯỜNG MỚI ---
  final String? audioId;
  final String? audioUrl;
  final String? audioName;
  final String? audioCoverUrl;
  // --------------------------

  StoryModel({
    required this.id,
    required this.authorId,
    this.mediaUrl = '',
    this.mediaType = 'image',
    this.content = '',
    this.backgroundColor = '',
    required this.createdAt,
    this.views = const [],
    // --- THÊM VÀO CONSTRUCTOR ---
    this.audioId,
    this.audioUrl,
    this.audioName,
    this.audioCoverUrl,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return StoryModel(
      id: doc.id,
      authorId: map['authorId'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      mediaType: map['mediaType'] ?? 'image',
      content: map['content'] ?? '',
      backgroundColor: map['backgroundColor'] ?? '',
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      views: List<String>.from(map['views'] ?? []),

      // --- LẤY DỮ LIỆU MỚI ---
      audioId: map['audioId'],
      audioUrl: map['audioUrl'],
      audioName: map['audioName'],
      audioCoverUrl: map['audioCoverUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'content': content,
      'backgroundColor': backgroundColor,
      'createdAt': FieldValue.serverTimestamp(),
      'views': views,

      // --- LƯU DỮ LIỆU MỚI ---
      'audioId': audioId,
      'audioUrl': audioUrl,
      'audioName': audioName,
      'audioCoverUrl': audioCoverUrl,
    };
  }
}