import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';

class QuickStatsStrip extends StatelessWidget {
  const QuickStatsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('complaints').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final complaints = docs
            .map((d) => Complaint.fromFirestore(d.id, d.data() as Map<String, dynamic>))
            .toList();

        final total = complaints.length;
        final resolved = complaints.where((c) => c.status == 'resolved' || c.status == 'closed').length;
        final active = total - resolved - complaints.where((c) => c.status == 'rejected' || c.status == 'duplicate').length;

        return SizedBox(
          height: 62,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _StatPill(icon: Icons.report, label: 'Total', value: '$total', color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 10),
              _StatPill(icon: Icons.pending_actions, label: 'Active', value: '$active', color: Colors.orange),
              const SizedBox(width: 10),
              _StatPill(icon: Icons.check_circle, label: 'Resolved', value: '$resolved', color: Colors.green),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}