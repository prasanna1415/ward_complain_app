import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String userId;
  final String municipality;
  final String wardId;
  final String categoryId;
  final String title;
  final String description;
  final String? imageUrl;
  final double latitude;
  final double longitude;
  final String? address;
  final String status;
  final String priority;
  final int priorityScore;
  final int voteCount;
  final DateTime? createdAt;
  final DateTime? verifiedAt;
  final DateTime? assignedAt;
  final DateTime? resolvedAt;
  final DateTime? deadline;
  final String? assignedDepartment;
  final String? adminComment;
  final String? resolutionImageUrl;
  final String? resolutionDescription;

  Complaint({
    required this.id,
    required this.userId,
    required this.municipality,
    required this.wardId,
    required this.categoryId,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.status,
    required this.priority,
    required this.priorityScore,
    required this.voteCount,
    this.createdAt,
    this.verifiedAt,
    this.assignedAt,
    this.resolvedAt,
    this.deadline,
    this.assignedDepartment,
    this.adminComment,
    this.resolutionImageUrl,
    this.resolutionDescription,
  });

  /// Converts a Firestore document into a Complaint object.
  factory Complaint.fromFirestore(String id, Map<String, dynamic> data) {
    return Complaint(
      id: id,
      userId: data['userId'] ?? '',
      municipality: data['municipality'] ?? '',
      wardId: data['wardId'] ?? 'Unconfirmed',
      categoryId: data['categoryId'] ?? 'other',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      address: data['address'],
      status: data['status'] ?? 'submitted',
      priority: data['priority'] ?? 'LOW',
      priorityScore: (data['priorityScore'] ?? 0).toInt(),
      voteCount: (data['voteCount'] ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      assignedDepartment: data['assignedDepartment'],
      adminComment: data['adminComment'],
      resolutionImageUrl: data['resolutionImageUrl'],
      resolutionDescription: data['resolutionDescription'],
    );
  }

  /// Converts this object back into a Map, ready to save to Firestore.
  /// Used only when CREATING - updates use smaller, targeted maps instead.
  Map<String, dynamic> toFirestoreForCreate() {
    return {
      'userId': userId,
      'municipality': municipality,
      'wardId': wardId,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      'priority': priority,
      'priorityScore': priorityScore,
      'voteCount': voteCount,
      'createdAt': FieldValue.serverTimestamp(),
      'verifiedAt': null,
      'assignedAt': null,
      'resolvedAt': null,
      'deadline': deadline,
      'assignedDepartment': null,
      'adminComment': null,
      'resolutionImageUrl': null,
      'resolutionDescription': null,
    };
  }
}