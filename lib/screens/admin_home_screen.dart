import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'admin_complaint_list_screen.dart';
import 'complaint_map_screen.dart';
import '../services/admin_stats_service.dart';
import '../services/sla_stats_service.dart';
import '../models/complaint.dart';
import '../constants/categories.dart';
import 'notifications_screen.dart';
import '../services/notification_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          StreamBuilder<int>(
            stream: NotificationService.unreadCountStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: AdminStatsService.allComplaintsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final complaints = snapshot.data ?? [];
          final stats = AdminStats.fromComplaints(complaints);
          final slaStats = SlaStats.fromComplaints(complaints);

          final mostVoted = [...complaints]..sort((a, b) => b.voteCount.compareTo(a.voteCount));
          final topVoted = mostVoted.take(5).toList();

          final highestPriority = [...complaints]..sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
          final topPriority = highestPriority.take(5).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.6,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _StatCard(label: 'Total Complaints', value: stats.total, color: Colors.blueGrey, icon: Icons.list_alt),
                  _StatCard(label: 'Submitted', value: stats.submitted, color: Colors.grey, icon: Icons.inbox),
                  _StatCard(label: 'Under Review', value: stats.underReview, color: Colors.blue, icon: Icons.rate_review),
                  _StatCard(label: 'In Progress', value: stats.inProgress, color: Colors.orange, icon: Icons.build),
                  _StatCard(label: 'Resolved', value: stats.resolved, color: Colors.green, icon: Icons.check_circle),
                  _StatCard(label: 'High Priority', value: stats.highPriority, color: Colors.red, icon: Icons.priority_high),
                  _StatCard(label: 'Overdue', value: slaStats.overdueCount, color: Colors.red.shade900, icon: Icons.warning_amber),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resolution Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            label: 'Average',
                            value: SlaStats.formatDuration(slaStats.averageResolutionTime),
                          ),
                        ),
                        Expanded(
                          child: _MiniStat(
                            label: 'Fastest',
                            value: SlaStats.formatDuration(slaStats.fastestResolutionTime),
                          ),
                        ),
                      ],
                    ),
                    if (slaStats.longestUnresolvedComplaint != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Longest unresolved: "${slaStats.longestUnresolvedComplaint!.title}" '
                            '(${DateTime.now().difference(slaStats.longestUnresolvedComplaint!.createdAt!).inDays} days pending)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AdminComplaintListScreen()),
                        );
                      },
                      icon: const Icon(Icons.list),
                      label: const Text('All Complaints'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ComplaintMapScreen()),
                        );
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Map View'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Complaints by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              if (stats.byCategory.isEmpty)
                const Text('No complaints yet.', style: TextStyle(color: Colors.grey))
              else
                ...stats.byCategory.entries.map((entry) {
                  final category = categoryById(entry.key);
                  final fraction = stats.total == 0 ? 0.0 : entry.value / stats.total;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(category.icon, size: 18, color: category.color),
                        const SizedBox(width: 8),
                        SizedBox(width: 110, child: Text(category.name, style: const TextStyle(fontSize: 12))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(category.color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${entry.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),
              const Text('Most Voted Complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (topVoted.isEmpty)
                const Text('No complaints yet.', style: TextStyle(color: Colors.grey))
              else
                ...topVoted.map((c) => _MiniComplaintRow(complaint: c, trailingValue: '${c.voteCount} votes')),
              const SizedBox(height: 24),
              const Text('Highest Priority Complaints', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (topPriority.isEmpty)
                const Text('No complaints yet.', style: TextStyle(color: Colors.grey))
              else
                ...topPriority.map((c) => _MiniComplaintRow(complaint: c, trailingValue: c.priority)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _MiniComplaintRow extends StatelessWidget {
  final Complaint complaint;
  final String trailingValue;

  const _MiniComplaintRow({required this.complaint, required this.trailingValue});

  @override
  Widget build(BuildContext context) {
    final category = categoryById(complaint.categoryId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(category.icon, size: 16, color: category.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(complaint.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
          ),
          Text(trailingValue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}