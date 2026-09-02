import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../constants/categories.dart';
import '../widgets/priority_badge.dart';
import 'complaint_details_screen.dart';

class MyComplaintsScreen extends StatelessWidget {
  const MyComplaintsScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
      case 'closed':
        return Colors.green;
      case 'rejected':
      case 'duplicate':
        return Colors.red;
      case 'in_progress':
      case 'assigned':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: ComplaintService.myComplaintsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          final complaints = snapshot.data ?? [];

          if (complaints.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'You haven\'t reported any complaints yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final category = categoryById(complaint.categoryId);

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplaintDetailsScreen(complaintId: complaint.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: category.color.withValues(alpha: 0.15),
                          child: Icon(category.icon, color: category.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                complaint.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(category.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                _statusLabel(complaint.status),
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                              backgroundColor: _statusColor(complaint.status),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(height: 6),
                            PriorityBadge(priority: complaint.priority),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}