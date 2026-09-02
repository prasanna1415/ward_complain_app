import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../constants/categories.dart';
import '../widgets/priority_badge.dart';
import '../widgets/comments_section.dart';
import '../widgets/admin_actions_panel.dart';
import 'pick_location_screen.dart';

class ComplaintDetailsScreen extends StatelessWidget {
  final String complaintId;
  const ComplaintDetailsScreen({super.key, required this.complaintId});

  Future<String?> _fetchCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data()?['role'] as String?;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Complaint?'),
        content: const Text('This will permanently delete this complaint. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel It', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ComplaintService.deleteComplaint(complaintId);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint cancelled.')),
        );
      }
    }
  }

  Future<void> _editComplaint(BuildContext context, Complaint complaint) async {
    final titleController = TextEditingController(text: complaint.title);
    final descriptionController = TextEditingController(text: complaint.description);
    String selectedCategoryId = complaint.categoryId;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Complaint'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: kCategories
                      .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategoryId = value ?? selectedCategoryId;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await ComplaintService.updateComplaint(
        complaintId: complaintId,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        categoryId: selectedCategoryId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint updated.')),
        );
      }
    }
  }

  Future<void> _editLocation(BuildContext context, Complaint complaint) async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (context) => PickLocationScreen(
          initialPoint: LatLng(complaint.latitude, complaint.longitude),
          initialAddress: complaint.address,
        ),
      ),
    );

    if (result == null) return;

    await ComplaintService.updateComplaintLocation(
      complaintId: complaintId,
      latitude: result.point.latitude,
      longitude: result.point.longitude,
      municipality: result.municipality,
      address: result.address,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Details'),
      ),
      body: FutureBuilder<String?>(
        future: _fetchCurrentUserRole(),
        builder: (context, roleSnapshot) {
          final isAdmin = roleSnapshot.data == 'admin';

          return StreamBuilder<Complaint?>(
            stream: ComplaintService.complaintStream(complaintId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final complaint = snapshot.data;
              if (complaint == null) {
                return const Center(child: Text('This complaint no longer exists.'));
              }

              final category = categoryById(complaint.categoryId);
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final isOwner = complaint.userId == currentUserId;
              final canModify = isOwner && complaint.status == 'submitted';
              final isOverdue = complaint.deadline != null &&
                  DateTime.now().isAfter(complaint.deadline!) &&
                  complaint.status != 'resolved' &&
                  complaint.status != 'closed';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: category.color.withValues(alpha: 0.15),
                          child: Icon(category.icon, color: category.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            complaint.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(label: Text(category.name)),
                        const SizedBox(width: 8),
                        PriorityBadge(priority: complaint.priority),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      complaint.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 16),
                    _StatusTimeline(currentStatus: complaint.status),
                    const SizedBox(height: 16),
                    const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(complaint.description),
                    const SizedBox(height: 16),
                    const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(complaint.address ?? '${complaint.municipality} (exact address not available)'),
                    const SizedBox(height: 4),
                    Text(
                      'Ward: ${complaint.wardId == 'Unconfirmed' ? 'To be confirmed by admin' : complaint.wardId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: complaint.wardId == 'Unconfirmed' ? Colors.orange : Colors.grey,
                        fontStyle: complaint.wardId == 'Unconfirmed' ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (complaint.assignedDepartment != null) ...[
                      Text('Assigned to: ${complaint.assignedDepartment}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                    ],
                    if (complaint.deadline != null) ...[
                      Text(
                        isOverdue
                            ? 'OVERDUE - Deadline was ${complaint.deadline!.day}/${complaint.deadline!.month}/${complaint.deadline!.year}'
                            : 'Deadline: ${complaint.deadline!.day}/${complaint.deadline!.month}/${complaint.deadline!.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey,
                          fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (complaint.adminComment != null && complaint.adminComment!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Admin Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(complaint.adminComment!, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (complaint.resolutionDescription != null && complaint.resolutionDescription!.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Resolution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(complaint.resolutionDescription!, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (isAdmin) ...[
                      AdminActionsPanel(complaint: complaint),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.thumb_up_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text('${complaint.voteCount} citizens support this'),
                      ],
                    ),
                    if (complaint.createdAt != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Reported on ${complaint.createdAt!.day}/${complaint.createdAt!.month}/${complaint.createdAt!.year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                    if (complaint.resolvedAt != null && complaint.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Resolved on ${complaint.resolvedAt!.day}/${complaint.resolvedAt!.month}/${complaint.resolvedAt!.year} '
                            '(${complaint.resolvedAt!.difference(complaint.createdAt!).inDays} days)',
                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                    if (canModify) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editComplaint(context, complaint),
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(context),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _editLocation(context, complaint),
                          icon: const Icon(Icons.edit_location_alt),
                          label: const Text('Edit Location'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    CommentsSection(complaintId: complaint.id),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String currentStatus;
  const _StatusTimeline({required this.currentStatus});

  static const List<String> _stages = [
    'submitted', 'under_review', 'verified', 'assigned', 'in_progress', 'resolved', 'closed',
  ];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == 'rejected' || currentStatus == 'duplicate') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Text(
              currentStatus == 'rejected' ? 'This complaint was rejected.' : 'Marked as a duplicate complaint.',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    final currentIndex = _stages.indexOf(currentStatus);

    return Column(
      children: List.generate(_stages.length, (index) {
        final isDone = index <= currentIndex;
        final isLast = index == _stages.length - 1;
        final stageLabel = _stages[index].replaceAll('_', ' ').toUpperCase();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  isDone ? Icons.check_circle : Icons.circle_outlined,
                  color: isDone ? Colors.green : Colors.grey.shade400,
                  size: 22,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 24,
                    color: isDone && index < currentIndex ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                stageLabel,
                style: TextStyle(
                  fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                  color: isDone ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}