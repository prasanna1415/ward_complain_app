import 'package:flutter/material.dart';
import '../widgets/complaints_map_view.dart';

class ComplaintMapScreen extends StatelessWidget {
  const ComplaintMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Map'),
        backgroundColor: Colors.blue,
      ),
      body: const ComplaintsMapView(interactive: true, showFilters: true),
    );
  }
}