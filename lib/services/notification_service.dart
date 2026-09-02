import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification.dart';

class NotificationService {
  static final _notificationsRef =
  FirebaseFirestore.instance.collection('notifications');

  /// CREATE - creates a notification for one user.
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

  /// NOTIFY ALL ADMINS
  ///
  /// This is used when something happens that admins
  /// need to know about, such as a citizen submitting
  /// a complaint or adding a comment.
  static Future<void> notifyAdmins({
    required String message,
    String? relatedComplaintId,
  }) async {
    final admins = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();

    for (final admin in admins.docs) {
      await create(
        userId: admin.id,
        message: message,
        relatedComplaintId: relatedComplaintId,
      );
    }
  }

  /// READ - live stream of the current user's notifications.
  static Stream<List<AppNotification>> myNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _notificationsRef
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs
          .map(
            (doc) => AppNotification.fromFirestore(
          doc.id,
          doc.data(),
        ),
      )
          .toList();

      // Sort newest notifications first.
      notifications.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) {
          return 0;
        }

        if (a.createdAt == null) {
          return 1;
        }

        if (b.createdAt == null) {
          return -1;
        }

        return b.createdAt!.compareTo(a.createdAt!);
      });

      return notifications;
    });
  }

  /// Live count of unread notifications.
  static Stream<int> unreadCountStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return _notificationsRef
        .where('userId', isEqualTo: user.uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark one notification as read.
  static Future<void> markAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'read': true,
    });
  }

  /// Mark multiple notifications as read.
  static Future<void> markAllAsRead(
      List<String> notificationIds,
      ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final id in notificationIds) {
      batch.update(
        _notificationsRef.doc(id),
        {'read': true},
      );
    }

    await batch.commit();
  }
}