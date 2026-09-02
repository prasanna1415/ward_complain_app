import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'complaint_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.myNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No notifications yet.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: notification.read ? null : Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                child: ListTile(
                  leading: Icon(
                    notification.read ? Icons.notifications_none : Icons.notifications_active,
                    color: notification.read ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    notification.message,
                    style: TextStyle(fontWeight: notification.read ? FontWeight.normal : FontWeight.bold),
                  ),
                  subtitle: Text(_timeAgo(notification.createdAt), style: const TextStyle(fontSize: 11)),
                  onTap: () async {
                    if (!notification.read) {
                      await NotificationService.markAsRead(notification.id);
                    }
                    if (notification.relatedComplaintId != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintDetailsScreen(complaintId: notification.relatedComplaintId!),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}