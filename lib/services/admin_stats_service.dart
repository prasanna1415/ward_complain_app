import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';
import '../models/feedback.dart';

class AdminStats {
  final int total;
  final int submitted;
  final int underReview;
  final int inProgress;
  final int resolved;
  final int rejected;
  final int highPriority;
  final Map<String, int> byCategory;

  AdminStats({
    required this.total,
    required this.submitted,
    required this.underReview,
    required this.inProgress,
    required this.resolved,
    required this.rejected,
    required this.highPriority,
    required this.byCategory,
  });

  factory AdminStats.fromComplaints(List<Complaint> complaints) {
    final byCategory = <String, int>{};
    for (final c in complaints) {
      byCategory[c.categoryId] = (byCategory[c.categoryId] ?? 0) + 1;
    }

    return AdminStats(
      total: complaints.length,
      submitted: complaints.where((c) => c.status == 'submitted').length,
      underReview: complaints.where((c) => c.status == 'under_review').length,
      inProgress: complaints.where((c) => c.status == 'in_progress' || c.status == 'assigned').length,
      resolved: complaints.where((c) => c.status == 'resolved' || c.status == 'closed').length,
      rejected: complaints.where((c) => c.status == 'rejected' || c.status == 'duplicate').length,
      highPriority: complaints.where((c) => c.priority == 'HIGH' || c.priority == 'CRITICAL').length,
      byCategory: byCategory,
    );
  }
}

class AdminStatsService {
  /// A single live stream of ALL complaints, district-wide - the
  /// dashboard and complaint list both build on this one source.
  static Stream<List<Complaint>> allComplaintsStream() {
    return FirebaseFirestore.instance
        .collection('complaints')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Complaint.fromFirestore(doc.id, doc.data()))
        .toList());
  }
  static Stream<List<ComplaintFeedback>> allFeedbackStream() {
    return FirebaseFirestore.instance
        .collection('feedback')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ComplaintFeedback.fromFirestore(doc.id, doc.data()))
        .toList());
  }
}