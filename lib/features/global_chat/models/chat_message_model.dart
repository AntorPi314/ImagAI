import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String id;
  final String uid;
  final String name;
  final String initials;
  final String text;
  final Timestamp? timestamp;

  const ChatMessageModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.initials,
    required this.text,
    this.timestamp,
  });

  factory ChatMessageModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'User',
      initials: data['initials'] ?? '?',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] as Timestamp?,
    );
  }
}