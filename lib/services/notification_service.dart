import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification.dart';

class NotificationService {
  static final _notificationsRef = FirebaseFirestore.instance.collection('notifications');

  /// CREATE - used internally whenever something notification-worthy
  /// happens (complaint submitted, status changed, etc). Not called
  /// directly by the UI - other services call this after they act.
  static Future<void> create({
    required String userId,
    required String message,
    String? relatedComplaintId,
  }) async {
    await _notificationsRef.add({
      'userId': userId,
      'message': message,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'relatedComplaintId': relatedComplaintId,
    });
  }

  /// READ - live stream of the current user's notifications, newest first.
  static Stream<List<AppNotification>> myNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return _notificationsRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  /// Live count of unread notifications, for the badge icon.
  static Stream<int> unreadCountStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);

    return _notificationsRef
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'read': true});
  }

  static Future<void> markAllAsRead(List<String> notificationIds) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in notificationIds) {
      batch.update(_notificationsRef.doc(id), {'read': true});
    }
    await batch.commit();
  }
}