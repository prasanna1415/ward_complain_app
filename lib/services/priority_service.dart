import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/categories.dart';

class PriorityService {
  /// The core formula:
  /// Priority Score = (Votes x 2) + (Severity x 20) + Days Pending
  ///
  /// - Votes: community support signal, weighted moderately.
  /// - Severity (1-5, from the category): how inherently serious this
  ///   TYPE of problem is, weighted heavily since it doesn't depend on
  ///   how many people happened to notice it.
  /// - Days Pending: gentle steady pressure so old, neglected
  ///   complaints naturally rise over time even without new votes.
  static int calculateScore({
    required int voteCount,
    required int severity,
    required int daysPending,
  }) {
    return (voteCount * 2) + (severity * 20) + daysPending;
  }

  /// Converts a numeric score into a human-readable priority label.
  static String labelForScore(int score) {
    if (score >= 120) return 'CRITICAL';
    if (score >= 80) return 'HIGH';
    if (score >= 40) return 'MEDIUM';
    return 'LOW';
  }

  static int daysBetween(DateTime? createdAt) {
    if (createdAt == null) return 0;
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Recalculates and saves a single complaint's priority. Called
  /// whenever something that affects priority changes (votes,
  /// creation) since we don't have a paid backend to run this on
  /// a schedule automatically.
  static Future<void> recalculateAndSave(String complaintId) async {
    final ref = FirebaseFirestore.instance.collection('complaints').doc(complaintId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final categoryId = data['categoryId'] as String? ?? 'other';
    final voteCount = (data['voteCount'] ?? 0) as int;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    final severity = categoryById(categoryId).severity;
    final daysPending = daysBetween(createdAt);

    final score = calculateScore(voteCount: voteCount, severity: severity, daysPending: daysPending);
    final label = labelForScore(score);

    await ref.update({
      'priorityScore': score,
      'priority': label,
    });
  }
}