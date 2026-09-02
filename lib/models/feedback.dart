import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintFeedback {
  final String id;
  final String complaintId;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime? createdAt;

  ComplaintFeedback({
    required this.id,
    required this.complaintId,
    required this.userId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ComplaintFeedback.fromFirestore(String id, Map<String, dynamic> data) {
    return ComplaintFeedback(
      id: id,
      complaintId: data['complaintId'] ?? '',
      userId: data['userId'] ?? '',
      rating: (data['rating'] ?? 0).toInt(),
      comment: data['comment'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}