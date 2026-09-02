import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActionService {
  static final _complaintsRef = FirebaseFirestore.instance.collection('complaints');

  static Future<void> markUnderReview(String complaintId) async {
    await _complaintsRef.doc(complaintId).update({'status': 'under_review'});
  }

  static Future<void> verify(String complaintId) async {
    await _complaintsRef.doc(complaintId).update({
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> reject(String complaintId, String reason) async {
    await _complaintsRef.doc(complaintId).update({
      'status': 'rejected',
      'adminComment': reason,
    });
  }

  static Future<void> markDuplicate(String complaintId, String reason) async {
    await _complaintsRef.doc(complaintId).update({
      'status': 'duplicate',
      'adminComment': reason,
    });
  }

  static Future<void> assign({
    required String complaintId,
    required String department,
    required DateTime deadline,
  }) async {
    await _complaintsRef.doc(complaintId).update({
      'status': 'assigned',
      'assignedAt': FieldValue.serverTimestamp(),
      'assignedDepartment': department,
      'deadline': Timestamp.fromDate(deadline),
    });
  }

  static Future<void> startProgress(String complaintId) async {
    await _complaintsRef.doc(complaintId).update({'status': 'in_progress'});
  }

  static Future<void> resolve({
    required String complaintId,
    required String resolutionDescription,
  }) async {
    await _complaintsRef.doc(complaintId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolutionDescription': resolutionDescription,
    });
  }

  static Future<void> close(String complaintId) async {
    await _complaintsRef.doc(complaintId).update({'status': 'closed'});
  }

  static Future<void> updateAdminComment(String complaintId, String comment) async {
    await _complaintsRef.doc(complaintId).update({'adminComment': comment});
  }
}