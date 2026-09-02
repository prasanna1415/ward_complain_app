import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String message;
  final bool read;
  final DateTime? createdAt;
  final String? relatedComplaintId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    required this.read,
    this.createdAt,
    this.relatedComplaintId,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      relatedComplaintId: data['relatedComplaintId'],
    );
  }
}