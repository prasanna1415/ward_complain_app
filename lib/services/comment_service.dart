import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/comment.dart';
import 'notification_service.dart';

class CommentService {
  static CollectionReference<Map<String, dynamic>> _commentsRef(
      String complaintId,
      ) {
    return FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .collection('comments');
  }

  /// READ - live stream of comments
  static Stream<List<Comment>> commentsStream(
      String complaintId,
      ) {
    return _commentsRef(complaintId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) {
        return snapshot.docs
            .map(
              (doc) => Comment.fromFirestore(
            doc.id,
            doc.data(),
          ),
        )
            .toList();
      },
    );
  }

  /// CREATE - add a comment
  static Future<void> addComment({
    required String complaintId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to comment.',
      );
    }

    // Get current user's profile.
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    final userName =
        userData?['name'] ??
            user.email ??
            'User';

    final userRole =
        userData?['role'] ??
            'citizen';

    // Save the comment.
    await _commentsRef(complaintId).add({
      'userId': user.uid,
      'userName': userName,
      'userRole': userRole,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Notify all admins when a citizen comments.
    if (userRole == 'citizen') {
      await NotificationService.notifyAdmins(
        message: '$userName commented on a complaint.',
        relatedComplaintId: complaintId,
      );
    }
  }

  /// DELETE - delete a comment
  static Future<void> deleteComment(
      String complaintId,
      String commentId,
      ) async {
    await _commentsRef(complaintId)
        .doc(commentId)
        .delete();
  }
}