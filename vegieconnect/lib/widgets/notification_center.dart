import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  final MessagingService _messagingService = MessagingService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _messagingService.initialize();
    _notificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _messagingService.getUnreadMessageCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        
        if (unreadCount == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () => _showNotifications(),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.accentRed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: AppTextStyles.headline,
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<NotificationData>>(
                stream: _notificationService.getNotificationHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return const Center(
                      child: Text('No notifications'),
                    );
                  }

                  return ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accentGreen,
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(notification.title),
                        subtitle: Text(notification.body),
                        trailing: Text(
                          _formatTime(notification.timestamp),
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => _handleNotificationTap(notification),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'chat':
        return Icons.chat;
      case 'order_update':
        return Icons.shopping_cart;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _handleNotificationTap(NotificationData notification) {
    // Handle navigation based on notification type
    switch (notification.type) {
      case 'chat':
        // Navigate to chat
        break;
      case 'order_update':
        // Navigate to order details
        break;
      default:
        // Default action
        break;
    }
  }
} 