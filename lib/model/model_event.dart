import 'package:cloud_firestore/cloud_firestore.dart';

class ModelEvent {
  final String id;
  final String groupId;
  final String creatorId;
  final String title;
  final String description;
  final String location;
  final Timestamp startTime;
  final List<String> participants;

  ModelEvent({
    required this.id,
    required this.groupId,
    required this.creatorId,
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.participants,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'location': location,
      'startTime': startTime,
      'participants': participants,
    };
  }

  factory ModelEvent.fromMap(Map<String, dynamic> map) {
    return ModelEvent(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      creatorId: map['creatorId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      startTime: map['startTime'] ?? Timestamp.now(),
      participants: List<String>.from(map['participants'] ?? []),
    );
  }
}