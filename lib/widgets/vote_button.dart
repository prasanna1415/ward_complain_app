import 'package:flutter/material.dart';
import '../services/vote_service.dart';

class VoteButton extends StatefulWidget {
  final String complaintId;
  final int voteCount;
  final bool disabled;
  final String disabledReason;

  const VoteButton({
    super.key,
    required this.complaintId,
    required this.voteCount,
    this.disabled = false,
    this.disabledReason = '',
  });

  @override
  State<VoteButton> createState() => _VoteButtonState();
}

class _VoteButtonState extends State<VoteButton> {
  bool _isSubmitting = false;

  Future<void> _handleTap() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await VoteService.toggleVote(widget.complaintId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update your vote. Please try again.')),
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
    if (widget.disabled) {
      return Tooltip(
        message: widget.disabledReason,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.thumb_up_outlined, size: 18),
          label: Text('${widget.voteCount} votes'),
        ),
      );
    }

    return StreamBuilder<bool>(
      stream: VoteService.hasVotedStream(widget.complaintId),
      builder: (context, snapshot) {
        final hasVoted = snapshot.data ?? false;
        final primaryColor = Theme.of(context).colorScheme.primary;

        return OutlinedButton.icon(
          onPressed: _isSubmitting ? null : _handleTap,
          style: OutlinedButton.styleFrom(
            backgroundColor: hasVoted ? primaryColor.withValues(alpha: 0.12) : null,
            side: BorderSide(color: hasVoted ? primaryColor : Colors.grey.shade400),
          ),
          icon: _isSubmitting
              ? SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
          )
              : Icon(
            hasVoted ? Icons.thumb_up : Icons.thumb_up_outlined,
            size: 18,
            color: hasVoted ? primaryColor : Colors.grey.shade700,
          ),
          label: Text(
            hasVoted ? 'Supported (${widget.voteCount})' : 'Support (${widget.voteCount})',
            style: TextStyle(color: hasVoted ? primaryColor : Colors.grey.shade700),
          ),
        );
      },
    );
  }
}