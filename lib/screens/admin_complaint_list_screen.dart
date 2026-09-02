import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../services/admin_stats_service.dart';
import '../constants/categories.dart';
import '../widgets/priority_badge.dart';
import 'complaint_details_screen.dart';

enum AdminSort { priority, votes, oldest, newest, status, category }

class AdminComplaintListScreen extends StatefulWidget {
  const AdminComplaintListScreen({super.key});

  @override
  State<AdminComplaintListScreen> createState() => _AdminComplaintListScreenState();
}

class _AdminComplaintListScreenState extends State<AdminComplaintListScreen> {
  AdminSort _sort = AdminSort.newest;
  String _statusFilter = 'all';

  static const List<String> _statusOptions = [
    'all', 'submitted', 'under_review', 'verified', 'assigned',
    'in_progress', 'resolved', 'closed', 'rejected', 'duplicate',
  ];

  List<Complaint> _sortComplaints(List<Complaint> complaints) {
    final list = [...complaints];
    switch (_sort) {
      case AdminSort.priority:
        list.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
        break;
      case AdminSort.votes:
        list.sort((a, b) => b.voteCount.compareTo(a.voteCount));
        break;
      case AdminSort.oldest:
        list.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
        break;
      case AdminSort.newest:
        list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case AdminSort.status:
        list.sort((a, b) => a.status.compareTo(b.status));
        break;
      case AdminSort.category:
        list.sort((a, b) => a.categoryId.compareTo(b.categoryId));
        break;
    }
    return list;
  }

  List<Complaint> _filterComplaints(List<Complaint> complaints) {
    if (_statusFilter == 'all') return complaints;
    return complaints.where((c) => c.status == _statusFilter).toList();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Complaints'),
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Status', isDense: true),
                        items: _statusOptions
                            .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s == 'all' ? 'All Statuses' : s.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(fontSize: 12)),
                        ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _statusFilter = value ?? 'all';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<AdminSort>(
                        initialValue: _sort,
                        decoration: const InputDecoration(labelText: 'Sort by', isDense: true),
                        items: const [
                          DropdownMenuItem(value: AdminSort.newest, child: Text('Newest', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: AdminSort.oldest, child: Text('Oldest', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: AdminSort.priority, child: Text('Highest Priority', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: AdminSort.votes, child: Text('Most Votes', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: AdminSort.status, child: Text('Status', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: AdminSort.category, child: Text('Category', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sort = value ?? AdminSort.newest;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Complaint>>(
              stream: AdminStatsService.allComplaintsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final complaints = _sortComplaints(_filterComplaints(snapshot.data ?? []));

                if (complaints.isEmpty) {
                  return const Center(child: Text('No complaints match this filter.', style: TextStyle(color: Colors.grey)));
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
                                    Text(complaint.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('${category.name} · ${complaint.municipality}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.thumb_up_outlined, size: 12, color: Colors.grey),
                                        const SizedBox(width: 3),
                                        Text('${complaint.voteCount}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
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
                                      complaint.status.replaceAll('_', ' ').toUpperCase(),
                                      style: const TextStyle(fontSize: 9, color: Colors.white),
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
          ),
        ],
      ),
    );
  }
}