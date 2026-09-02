import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoteService {
  static CollectionReference<Map<String, dynamic>> _votesRef(String complaintId) {
    return FirebaseFirestore.instance
        .collection('complaints')
        .doc(complaintId)
        .collection('votes');
  }

  /// Live stream of whether the CURRENT user has voted on this
  /// complaint. Since the vote document's ID is literally the user's
  /// uid, checking "have I voted" is just "does this one document exist."
  static Stream<bool> hasVotedStream(String complaintId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(false);

    return _votesRef(complaintId)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Adds or removes the current user's vote, and keeps the complaint's
  /// voteCount field in sync - both changes happen together atomically,
  /// so the count can never drift out of sync with the actual votes.
  static Future<void> toggleVote(String complaintId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('You must be logged in to vote.');

    final complaintRef = FirebaseFirestore.instance.collection('complaints').doc(complaintId);
    final voteRef = _votesRef(complaintId).doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final voteSnapshot = await transaction.get(voteRef);

      if (voteSnapshot.exists) {
        // Already voted - remove the vote.
        transaction.delete(voteRef);
        transaction.update(complaintRef, {'voteCount': FieldValue.increment(-1)});
      } else {
        // Not voted yet - add the vote.
        transaction.set(voteRef, {'votedAt': FieldValue.serverTimestamp()});
        transaction.update(complaintRef, {'voteCount': FieldValue.increment(1)});
      }
    });
  }
}