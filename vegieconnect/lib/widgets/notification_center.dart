import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/notification_service.dart';
import '../theme.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationData> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenToNotifications();
  }

  void _loadNotifications() {
    _notifications = _notificationService.notificationHistory;
    setState(() {});
  }

  void _listenToNotifications() {
    _notificationService.notificationStream.listen((notification) {
      setState(() {
        _notifications.insert(0, notification);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white),
              onPressed: _showClearAllDialog,
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Neumorphic(
            style: AppNeumorphic.card,
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: AppColors.accentGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Notifications',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 300),
            child: SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNotificationCard(notification),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData notification) {
    return Neumorphic(
      style: AppNeumorphic.card,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        onLongPress: () => _showNotificationOptions(notification),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(notification.timestamp),
                          style: AppTextStyles.body.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        _buildNotificationBadge(notification.type),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'order_update':
        icon = Icons.shopping_bag;
        color = AppColors.primaryGreen;
        break;
      case 'chat':
        icon = Icons.chat;
        color = AppColors.accentGreen;
        break;
      case 'promotion':
        icon = Icons.local_offer;
        color = AppColors.accentYellow;
        break;
      case 'system':
        icon = Icons.info;
        color = AppColors.oliveGreen;
        break;
      default:
        icon = Icons.notifications;
        color = AppColors.primaryGreen;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  Widget _buildNotificationBadge(String type) {
    Color color;
    String text;

    switch (type) {
      case 'order_update':
        color = AppColors.primaryGreen;
        text = 'Order';
        break;
      case 'chat':
        color = AppColors.accentGreen;
        text = 'Chat';
        break;
      case 'promotion':
        color = AppColors.accentYellow;
        text = 'Promo';
        break;
      case 'system':
        color = AppColors.oliveGreen;
        text = 'System';
        break;
      default:
        color = AppColors.primaryGreen;
        text = 'Info';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _handleNotificationTap(NotificationData notification) {
    // Handle navigation based on notification type
    final type = notification.data['type'] ?? notification.type;
    final targetScreen = notification.data['screen'];

    switch (type) {
      case 'order_update':
        // Navigate to order details
        _showOrderDetails(notification.data['orderId']);
        break;
      case 'chat':
        // Navigate to chat
        _openChat(notification.data['chatId']);
        break;
      case 'promotion':
        // Navigate to promotion
        _showPromotion(notification.data['promotionId']);
        break;
      default:
        // Show notification details
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationOptions(NotificationData notification) {
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
            ListTile(
              leading: const Icon(Icons.info, color: AppColors.primaryGreen),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationDetails(notification);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.accentRed),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _deleteNotification(notification);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Text(
              'Time: ${_formatTime(notification.timestamp)}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrderDetails(String? orderId) {
    // TODO: Navigate to order details page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order details for: $orderId'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _openChat(String? chatId) {
    // TODO: Navigate to chat page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat: $chatId'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _showPromotion(String? promotionId) {
    // TODO: Navigate to promotion page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Promotion: $promotionId'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _deleteNotification(NotificationData notification) {
    setState(() {
      _notifications.remove(notification);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllNotifications();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    try {
      await _notificationService.clearNotificationHistory();
      setState(() {
        _notifications.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications cleared'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing notifications: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }
} 