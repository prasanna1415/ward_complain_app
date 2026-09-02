import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/complaint.dart';
import '../constants/categories.dart';
import '../constants/municipality_centers.dart';
import '../screens/complaint_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vote_button.dart';
import 'priority_badge.dart';

enum MapFilter { all, unresolved, resolved, highPriority }

class ComplaintsMapView extends StatefulWidget {
  final bool interactive;
  final bool showFilters;
  const ComplaintsMapView({super.key, this.interactive = true, this.showFilters = false});

  @override
  State<ComplaintsMapView> createState() => _ComplaintsMapViewState();
}

class _ComplaintsMapViewState extends State<ComplaintsMapView> {
  MapFilter _filter = MapFilter.all;

  Stream<List<Complaint>> _allComplaintsStream() {
    return FirebaseFirestore.instance
        .collection('complaints')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Complaint.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  List<Complaint> _applyFilter(List<Complaint> complaints) {
    switch (_filter) {
      case MapFilter.unresolved:
        return complaints.where((c) => !['resolved', 'closed', 'rejected', 'duplicate'].contains(c.status)).toList();
      case MapFilter.resolved:
        return complaints.where((c) => c.status == 'resolved' || c.status == 'closed').toList();
      case MapFilter.highPriority:
        return complaints.where((c) => c.priority == 'HIGH' || c.priority == 'CRITICAL').toList();
      case MapFilter.all:
        return complaints;
    }
  }

  void _showComplaintPreview(BuildContext context, Complaint complaint) {
    final category = categoryById(complaint.categoryId);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  child: Text(complaint.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${complaint.municipality}, ${complaint.wardId}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text(complaint.status.replaceAll('_', ' ').toUpperCase()), padding: EdgeInsets.zero),
                const SizedBox(width: 8),
                PriorityBadge(priority: complaint.priority),
              ],
            ),
            const SizedBox(height: 8),
            VoteButton(
              complaintId: complaint.id,
              voteCount: complaint.voteCount,
              disabled: complaint.userId == FirebaseAuth.instance.currentUser?.uid,
              disabledReason: 'You cannot vote on your own complaint',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ComplaintDetailsScreen(complaintId: complaint.id)),
                  );
                },
                child: const Text('View Full Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinMarker(ComplaintCategory category) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Icon(category.icon, color: Colors.white, size: 16),
        ),
        CustomPaint(
          size: const Size(8, 6),
          painter: _TrianglePainter(category.color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showFilters)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', MapFilter.all),
                  const SizedBox(width: 8),
                  _filterChip('Unresolved', MapFilter.unresolved),
                  const SizedBox(width: 8),
                  _filterChip('Resolved', MapFilter.resolved),
                  const SizedBox(width: 8),
                  _filterChip('High Priority', MapFilter.highPriority),
                ],
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Complaint>>(
            stream: _allComplaintsStream(),
            builder: (context, snapshot) {
              final complaints = _applyFilter(snapshot.data ?? []);

              return FlutterMap(
                options: MapOptions(
                  initialCenter: kBhaktapurDistrictCenter,
                  initialZoom: 12,
                  interactionOptions: InteractionOptions(
                    flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ward_complaint_app',
                  ),
                  MarkerLayer(
                    markers: complaints
                        .where((c) => c.latitude != 0 && c.longitude != 0)
                        .map((complaint) {
                      final category = categoryById(complaint.categoryId);
                      return Marker(
                        point: LatLng(complaint.latitude, complaint.longitude),
                        width: 34,
                        height: 42,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: widget.interactive ? () => _showComplaintPreview(context, complaint) : null,
                          child: _pinMarker(category),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, MapFilter value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = value;
        });
      },
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}