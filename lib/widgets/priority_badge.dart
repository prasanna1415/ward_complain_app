import 'package:flutter/material.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  Color _color() {
    switch (priority) {
      case 'CRITICAL':
        return Colors.red.shade700;
      case 'HIGH':
        return Colors.orange.shade700;
      case 'MEDIUM':
        return Colors.amber.shade800;
      default:
        return Colors.green.shade700;
    }
  }

  IconData _icon() {
    switch (priority) {
      case 'CRITICAL':
        return Icons.priority_high;
      case 'HIGH':
        return Icons.arrow_upward;
      case 'MEDIUM':
        return Icons.remove;
      default:
        return Icons.arrow_downward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 12, color: color),
          const SizedBox(width: 4),
          Text(priority, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}