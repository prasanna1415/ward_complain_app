import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String text;
  final DateTime? createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.text,
    this.createdAt,
  });

  factory Comment.fromFirestore(String id, Map<String, dynamic> data) {
    return Comment(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      userRole: data['userRole'] ?? 'citizen',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}