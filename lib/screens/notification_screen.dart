import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasklink/models/notification_model.dart';
import 'package:tasklink/services/auth_service.dart';
import 'package:tasklink/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications when screen loads
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

    if (authService.currentUser != null) {
      await notificationService.fetchNotifications(authService.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    final notifications = notificationService.notifications;
    final isLoading = notificationService.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () {
                final authService = Provider.of<AuthService>(context, listen: false);
                if (authService.currentUser != null) {
                  notificationService.markAllAsRead(authService.currentUser!.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All notifications marked as read')),
                  );
                }
              },
            ),
        ],
      ),
      body: _buildBody(context, notifications, isLoading),
    );
  }

  Widget _buildBody(BuildContext context, List<NotificationModel> notifications, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'You\'ll be notified about application updates and matches',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (notification.status == 'Unread') {
      Provider.of<NotificationService>(context, listen: false)
          .markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case 'application':
      // Navigate to application details
      // Navigator.push(...);
        break;
      case 'status_update':
      // Navigate to job application
      // Navigator.push(...);
        break;
      case 'job_match':
      // Navigate to job details
      // Navigator.push(...);
        break;
      case 'message':
      // Navigate to messages
      // Navigator.push(...);
        break;
    }

    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opened: ${notification.message}')),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getNotificationColor(notification.type).withOpacity(0.1),
        child: Icon(
          IconData(
            _getIconData(notification.iconName),
            fontFamily: 'MaterialIcons',
          ),
          color: _getNotificationColor(notification.type),
        ),
      ),
      title: Text(
        notification.message,
        style: TextStyle(
          fontWeight: notification.status == 'Unread' ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(notification.formattedTime),
      trailing: notification.status == 'Unread'
          ? Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'application':
        return Colors.blue;
      case 'status_update':
        return Colors.green;
      case 'job_match':
        return Colors.purple;
      case 'message':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  int _getIconData(String iconName) {
    // Convert icon string names to MaterialIcons codepoints
    switch (iconName) {
      case 'description':
        return Icons.description.codePoint;
      case 'update':
        return Icons.update.codePoint;
      case 'work':
        return Icons.work.codePoint;
      case 'mail':
        return Icons.mail.codePoint;
      default:
        return Icons.notifications.codePoint;
    }
  }
}