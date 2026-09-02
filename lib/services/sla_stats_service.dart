import '../models/complaint.dart';

class SlaStats {
  final Duration? averageResolutionTime;
  final Duration? fastestResolutionTime;
  final Complaint? longestUnresolvedComplaint;
  final int overdueCount;

  SlaStats({
    required this.averageResolutionTime,
    required this.fastestResolutionTime,
    required this.longestUnresolvedComplaint,
    required this.overdueCount,
  });

  factory SlaStats.fromComplaints(List<Complaint> complaints) {
    final resolvedWithTimes = complaints.where((c) =>
    c.createdAt != null && c.resolvedAt != null).toList();

    Duration? average;
    Duration? fastest;

    if (resolvedWithTimes.isNotEmpty) {
      final durations = resolvedWithTimes
          .map((c) => c.resolvedAt!.difference(c.createdAt!))
          .toList();

      final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
      average = Duration(milliseconds: totalMs ~/ durations.length);

      durations.sort((a, b) => a.compareTo(b));
      fastest = durations.first;
    }

    final unresolved = complaints.where((c) =>
    c.status != 'resolved' && c.status != 'closed' &&
        c.status != 'rejected' && c.status != 'duplicate' &&
        c.createdAt != null).toList();

    Complaint? longestUnresolved;
    if (unresolved.isNotEmpty) {
      unresolved.sort((a, b) => a.createdAt!.compareTo(b.createdAt!));
      longestUnresolved = unresolved.first;
    }

    final overdueCount = complaints.where((c) {
      if (c.deadline == null) return false;
      if (c.status == 'resolved' || c.status == 'closed') return false;
      return DateTime.now().isAfter(c.deadline!);
    }).length;

    return SlaStats(
      averageResolutionTime: average,
      fastestResolutionTime: fastest,
      longestUnresolvedComplaint: longestUnresolved,
      overdueCount: overdueCount,
    );
  }

  /// Formats a Duration as a readable string like "3 days 4 hours"
  /// or "5 hours" for shorter durations.
  static String formatDuration(Duration? duration) {
    if (duration == null) return 'N/A';
    if (duration.inDays >= 1) {
      final hours = duration.inHours % 24;
      return hours > 0 ? '${duration.inDays}d ${hours}h' : '${duration.inDays}d';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours}h';
    }
    return '${duration.inMinutes}m';
  }
}