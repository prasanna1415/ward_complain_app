import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback.dart';
import '../services/feedback_service.dart';

class FeedbackSection extends StatefulWidget {
  final String complaintId;
  final String complaintOwnerId;
  final bool isAdmin;

  const FeedbackSection({
    super.key,
    required this.complaintId,
    required this.complaintOwnerId,
    this.isAdmin = false,
  });

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FeedbackService.submitFeedback(
        complaintId: widget.complaintId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit feedback. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == widget.complaintOwnerId;

    return StreamBuilder<ComplaintFeedback?>(
      stream: FeedbackService.feedbackForComplaintStream(
        widget.complaintId,
      ),
      builder: (context, snapshot) {
        final existingFeedback = snapshot.data;

        // ---------------------------------------------------------
        // FEEDBACK ALREADY EXISTS
        // Everyone can see it:
        // - Complaint owner
        // - Admin
        // - Other citizens
        // ---------------------------------------------------------
        if (existingFeedback != null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.amber.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isAdmin
                      ? 'Citizen Feedback'
                      : isOwner
                      ? 'Your Feedback'
                      : 'Citizen Feedback',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: List.generate(
                    5,
                        (i) => Icon(
                      i < existingFeedback.rating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${existingFeedback.rating}/5',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                if (existingFeedback.comment != null &&
                    existingFeedback.comment!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    existingFeedback.comment!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
            ),
          );
        }

        // ---------------------------------------------------------
        // NO FEEDBACK EXISTS
        // ---------------------------------------------------------

        // Admin sees that no feedback has been submitted.
        if (widget.isAdmin) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: const Text(
              'No feedback submitted yet.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          );
        }

        // Other citizens see nothing until the owner submits feedback.
        if (!isOwner) {
          return const SizedBox.shrink();
        }

        // ---------------------------------------------------------
        // COMPLAINT OWNER + NO FEEDBACK
        // Show the rating form.
        // ---------------------------------------------------------
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.amber.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How satisfied are you with the resolution?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Rate your experience with how this complaint was handled.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: List.generate(
                  5,
                      (i) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedRating = i + 1;
                        });
                      },
                      icon: Icon(
                        i < _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber.shade700,
                        size: 28,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Optional comments...',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Submit Feedback'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}