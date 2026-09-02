import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/comment.dart';

class CommentService {
  static CollectionReference<Map<String, dynamic>> _commentsRef(String complaintId) {
    return FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .collection('comments');
  }

  /// READ - live stream of comments on a complaint, oldest first
  /// (reads naturally top-to-bottom like a conversation).
  static Stream<List<Comment>> commentsStream(String complaintId) {
    return _commentsRef(complaintId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Comment.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  /// CREATE - posts a new comment. Denormalizes the user's name and
  /// role onto the comment itself (rather than looking it up fresh
  /// every time the thread loads) since names rarely change and this
  /// keeps the comment list fast and simple to query.
  static Future<void> addComment({
    required String complaintId,
    required String text,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('You must be logged in to comment.');

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final userName = userData?['name'] ?? user.email ?? 'User';
    final userRole = userData?['role'] ?? 'citizen';

    await _commentsRef(complaintId).add({
      'userId': user.uid,
      'userName': userName,
      'userRole': userRole,
      'text': text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// DELETE - a citizen can delete their own comment; admins can
  /// delete any comment (e.g. to remove abusive/off-topic content).
  static Future<void> deleteComment(String complaintId, String commentId) async {
    await _commentsRef(complaintId).doc(commentId).delete();
  }
}