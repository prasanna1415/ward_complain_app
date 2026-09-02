import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/complaint.dart';
import 'notification_service.dart';

class ComplaintService {
  static final _complaintsRef =
  FirebaseFirestore.instance.collection('complaints');

  /// CREATE - submits a new complaint.
  /// Ward starts as 'Unconfirmed' and is assigned by an admin during review.
  static Future<void> createComplaint({
    required String municipality,
    required String categoryId,
    required String title,
    required String description,
    double latitude = 0,
    double longitude = 0,
    String? address,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'You must be logged in to report a complaint.',
      );
    }

    final complaint = Complaint(
      id: '',
      userId: user.uid,
      municipality: municipality,
      wardId: 'Unconfirmed',
      categoryId: categoryId,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      address: address,
      status: 'submitted',
      priority: 'LOW',
      priorityScore: 0,
      voteCount: 0,
    );

    // Save the complaint to Firestore
    final docRef = await _complaintsRef.add(
      complaint.toFirestoreForCreate(),
    );

    // Notify the citizen
    await NotificationService.create(
      userId: user.uid,
      message: 'Your complaint "$title" was submitted successfully.',
      relatedComplaintId: docRef.id,
    );

// Notify all admins
    await NotificationService.notifyAdmins(
      message: 'A new complaint "$title" has been submitted.',
      relatedComplaintId: docRef.id,
    );
  }

  /// READ - returns the currently logged-in user's complaints.
  static Stream<List<Complaint>> myComplaintsStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _complaintsRef
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => Complaint.fromFirestore(
          doc.id,
          doc.data(),
        ),
      )
          .toList(),
    );
  }

  /// READ - listens to a single complaint.
  static Stream<Complaint?> complaintStream(String complaintId) {
    return _complaintsRef.doc(complaintId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      return Complaint.fromFirestore(
        doc.id,
        doc.data()!,
      );
    });
  }

  /// UPDATE - updates the complaint details.
  static Future<void> updateComplaint({
    required String complaintId,
    required String title,
    required String description,
    required String categoryId,
  }) async {
    await _complaintsRef.doc(complaintId).update({
      'title': title,
      'description': description,
      'categoryId': categoryId,
    });
  }

  /// UPDATE - updates only the complaint location.
  static Future<void> updateComplaintLocation({
    required String complaintId,
    required double latitude,
    required double longitude,
    required String municipality,
    String? address,
  }) async {
    await _complaintsRef.doc(complaintId).update({
      'latitude': latitude,
      'longitude': longitude,
      'municipality': municipality,
      'address': address,
    });
  }

  /// DELETE - deletes a complaint.
  static Future<void> deleteComplaint(String complaintId) async {
    await _complaintsRef.doc(complaintId).delete();
  }
}