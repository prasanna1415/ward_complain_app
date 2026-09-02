import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AdminActionService {
  static final _complaintsRef = FirebaseFirestore.instance.collection('complaints');

  /// Fetches the complaint's owner and title, so we can send a
  /// meaningful notification after each status change.
  static Future<Map<String, dynamic>?> _getOwnerInfo(String complaintId) async {
    final doc = await _complaintsRef.doc(complaintId).get();
    if (!doc.exists) return null;
    return {
      'userId': doc.data()!['userId'],
      'title': doc.data()!['title'],
    };
  }

  static Future<void> _notifyOwner(String complaintId, String message) async {
    final info = await _getOwnerInfo(complaintId);
    if (info == null) return;
    await NotificationService.create(
      userId: info['userId'],
      message: message,
      relatedComplaintId: complaintId,
    );
  }

  static Future<void> markUnderReview(String complaintId) async {
    await _complaintsRef.doc(complaintId).update({'status': 'under_review'});
    await _notifyOwner(complaintId, 'Your complaint is now under review.');
  }

  static Future<void> verify(String complaintId) async {
    await _complaintsRef.doc(complaintId).update({
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
    });
    await _notifyOwner(complaintId, 'Your complaint has been verified.');
  }

  static Future<void> reject(String complaintId, String reason) async {
    await _complaintsRef.doc(complaintId).update({
      'status': 'rejected',
      'adminComment': reason,
    });
    await _notifyOwner(complaintId, 'Your complaint was rejected. Reason: $reason');
  }

  static Future<void> markDuplicate(String complaintId, String reason) async {
    await _complaintsRef.doc(complaintId).update({
      'status': 'duplicate',
      'adminComment': reason,
    });
    await _notifyOwner(complaintId, 'Your complaint was marked as a duplicate. $reason');
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
    await _notifyOwner(complaintId, 'Your complaint was assigned to $department.');
  }

  static Future<void> startProgress(String complaintId) async {
    await _complaintsRef.doc(complaintId).update({'status': 'in_progress'});
    await _notifyOwner(complaintId, 'Work has started on your complaint.');
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
    await _notifyOwner(complaintId, 'Your complaint has been resolved!');
  }

  static Future<void> close(String complaintId) async {
    await _complaintsRef.doc(complaintId).update({'status': 'closed'});
    await _notifyOwner(complaintId, 'Your complaint has been closed.');
  }

  static Future<void> updateAdminComment(
      String complaintId,
      String comment,
      ) async {
    await _complaintsRef.doc(complaintId).update({
      'adminComment': comment,
    });

    await _notifyOwner(
      complaintId,
      'The admin has added a note to your complaint: $comment',
    );
  }
}