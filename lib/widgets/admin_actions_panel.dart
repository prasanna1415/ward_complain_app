import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../constants/departments.dart';
import '../constants/categories.dart';
import '../services/admin_action_service.dart';

class AdminActionsPanel extends StatefulWidget {
  final Complaint complaint;
  const AdminActionsPanel({super.key, required this.complaint});

  @override
  State<AdminActionsPanel> createState() => _AdminActionsPanelState();
}

class _AdminActionsPanelState extends State<AdminActionsPanel> {
  bool _isProcessing = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isProcessing = true;
    });
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint updated.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _promptReasonAndRun(String title, Future<void> Function(String reason) action) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason (visible to citizen)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      await _run(() => action(controller.text.trim()));
    }
  }

  Future<void> _promptAssign() async {
    String? selectedDepartment;
    final category = categoryById(widget.complaint.categoryId);
    final defaultDeadline = (widget.complaint.createdAt ?? DateTime.now())
        .add(Duration(days: category.defaultSlaDays));
    DateTime selectedDeadline = defaultDeadline;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Complaint'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedDepartment,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: kDepartments
                      .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d, overflow: TextOverflow.ellipsis),
                  ))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDepartment = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Deadline: ${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDeadline,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 180)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDeadline = picked;
                          });
                        }
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
                Text(
                  'Suggested based on ${category.name} (${category.defaultSlaDays}-day target)',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: selectedDepartment == null ? null : () => Navigator.pop(context, true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedDepartment != null) {
      await _run(() => AdminActionService.assign(
        complaintId: widget.complaint.id,
        department: selectedDepartment!,
        deadline: selectedDeadline,
      ));
    }
  }

  Future<void> _promptResolve() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'What was done to fix this?'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: resolution photo upload will be added in a later phase.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirmed == true) {
      await _run(() => AdminActionService.resolve(
        complaintId: widget.complaint.id,
        resolutionDescription: controller.text.trim(),
      ));
    }
  }

  Future<void> _editAdminComment() async {
    final controller = TextEditingController(text: widget.complaint.adminComment ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Internal/public note about this complaint'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (confirmed == true) {
      await _run(() => AdminActionService.updateAdminComment(widget.complaint.id, controller.text.trim()));
    }
  }

  List<Widget> _actionsForStatus(String status) {
    switch (status) {
      case 'submitted':
        return [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _run(() => AdminActionService.markUnderReview(widget.complaint.id)),
            icon: const Icon(Icons.rate_review, size: 18),
            label: const Text('Mark Under Review'),
          ),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _promptReasonAndRun('Reject Complaint', (r) => AdminActionService.reject(widget.complaint.id, r)),
            icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
            label: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _promptReasonAndRun('Mark as Duplicate', (r) => AdminActionService.markDuplicate(widget.complaint.id, r)),
            icon: const Icon(Icons.content_copy, size: 18),
            label: const Text('Mark Duplicate'),
          ),
        ];
      case 'under_review':
        return [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _run(() => AdminActionService.verify(widget.complaint.id)),
            icon: const Icon(Icons.verified, size: 18),
            label: const Text('Verify'),
          ),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _promptReasonAndRun('Reject Complaint', (r) => AdminActionService.reject(widget.complaint.id, r)),
            icon: const Icon(Icons.cancel, size: 18, color: Colors.red),
            label: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _promptReasonAndRun('Mark as Duplicate', (r) => AdminActionService.markDuplicate(widget.complaint.id, r)),
            icon: const Icon(Icons.content_copy, size: 18),
            label: const Text('Mark Duplicate'),
          ),
        ];
      case 'verified':
        return [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _promptAssign,
            icon: const Icon(Icons.assignment_ind, size: 18),
            label: const Text('Assign to Department'),
          ),
        ];
      case 'assigned':
        return [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _run(() => AdminActionService.startProgress(widget.complaint.id)),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Start Progress'),
          ),
        ];
      case 'in_progress':
        return [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _promptResolve,
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Mark Resolved'),
          ),
        ];
      case 'resolved':
        return [
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _run(() => AdminActionService.close(widget.complaint.id)),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Close Complaint'),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actionsForStatus(widget.complaint.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings, size: 18, color: Colors.indigo),
              const SizedBox(width: 6),
              const Text('Admin Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              if (_isProcessing) ...[
                const SizedBox(width: 10),
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (actions.isEmpty)
            const Text('No further actions available for this status.', style: TextStyle(fontSize: 12, color: Colors.grey))
          else
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _isProcessing ? null : _editAdminComment,
            icon: const Icon(Icons.edit_note, size: 18),
            label: const Text('Add/Edit Admin Note'),
          ),
        ],
      ),
    );
  }
}