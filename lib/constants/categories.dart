import 'package:flutter/material.dart';

class ComplaintCategory {
  final String id;
  final String name;
  final IconData icon;
  final int defaultSlaDays;
  final Color color;
  final int severity; // 1 (low) to 5 (high) - how serious this category inherently is

  const ComplaintCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.defaultSlaDays,
    required this.color,
    required this.severity,
  });
}

const List<ComplaintCategory> kCategories = [
  ComplaintCategory(id: 'road', name: 'Road / Pothole', icon: Icons.construction, defaultSlaDays: 7, color: Color(0xFF8D6E63), severity: 4),
  ComplaintCategory(id: 'water', name: 'Water Supply', icon: Icons.water_drop, defaultSlaDays: 2, color: Color(0xFF1E88E5), severity: 5),
  ComplaintCategory(id: 'garbage', name: 'Garbage / Waste', icon: Icons.delete, defaultSlaDays: 2, color: Color(0xFF43A047), severity: 3),
  ComplaintCategory(id: 'streetlight', name: 'Street Light', icon: Icons.lightbulb, defaultSlaDays: 3, color: Color(0xFFFFB300), severity: 3),
  ComplaintCategory(id: 'drainage', name: 'Drainage / Sewer', icon: Icons.plumbing, defaultSlaDays: 3, color: Color(0xFF5E35B1), severity: 4),
  ComplaintCategory(id: 'traffic', name: 'Traffic', icon: Icons.traffic, defaultSlaDays: 5, color: Color(0xFFE53935), severity: 4),
  ComplaintCategory(id: 'infrastructure', name: 'Public Infrastructure', icon: Icons.apartment, defaultSlaDays: 10, color: Color(0xFF546E7A), severity: 3),
  ComplaintCategory(id: 'environment', name: 'Environment', icon: Icons.park, defaultSlaDays: 7, color: Color(0xFF00897B), severity: 2),
  ComplaintCategory(id: 'electricity', name: 'Electricity', icon: Icons.bolt, defaultSlaDays: 3, color: Color(0xFFFB8C00), severity: 5),
  ComplaintCategory(id: 'health', name: 'Public Health', icon: Icons.local_hospital, defaultSlaDays: 5, color: Color(0xFFD81B60), severity: 5),
  ComplaintCategory(id: 'animals', name: 'Stray Animals', icon: Icons.pets, defaultSlaDays: 5, color: Color(0xFF8E24AA), severity: 2),
  ComplaintCategory(id: 'other', name: 'Other', icon: Icons.report_problem, defaultSlaDays: 7, color: Color(0xFF6D4C41), severity: 2),
];

ComplaintCategory categoryById(String id) {
  return kCategories.firstWhere(
        (c) => c.id == id,
    orElse: () => kCategories.last,
  );
}