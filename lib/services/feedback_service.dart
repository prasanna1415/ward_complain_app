import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback.dart';

class FeedbackService {
  static final _feedbackRef = FirebaseFirestore.instance.collection('feedback');

  /// CREATE - one feedback entry per complaint, keyed by complaintId
  /// as the document ID (same trick as votes) so a citizen can only
  /// leave feedback once per complaint - resubmitting just overwrites.
  static Future<void> submitFeedback({
    required String complaintId,
    required int rating,
    String? comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('You must be logged in to leave feedback.');

    await _feedbackRef.doc(complaintId).set({
      'complaintId': complaintId,
      'userId': user.uid,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// READ - live stream of feedback for one complaint (null if none yet).
  static Stream<ComplaintFeedback?> feedbackForComplaintStream(String complaintId) {
    return _feedbackRef.doc(complaintId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ComplaintFeedback.fromFirestore(doc.id, doc.data()!);
    });
  }

  /// For the admin dashboard's district-wide satisfaction stat.
  static Stream<List<ComplaintFeedback>> allFeedbackStream() {
    return _feedbackRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ComplaintFeedback.fromFirestore(doc.id, doc.data()))
        .toList());
  }
}