import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/messaging_service.dart';
import '../theme.dart';
import '../customer-side/chat_conversation_page.dart';
import '../widgets/chat_widgets.dart';

class SupplierChatPage extends StatefulWidget {
  const SupplierChatPage({super.key});

  @override
  State<SupplierChatPage> createState() => _SupplierChatPageState();
}

class _SupplierChatPageState extends State<SupplierChatPage> {
  final MessagingService _messagingService = MessagingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _messagingService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NeumorphicAppBar(
        title: const Text('Customer Messages'),
        actions: [
          NeumorphicButton(
            onPressed: _showSearchDialog,
            style: AppNeumorphic.button,
            child: const Icon(Icons.search, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatSummary>>(
        stream: _messagingService.getRealCustomerSupplierChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.accentRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading chats',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatListItem(
                chat: chat,
                onTap: () => _openChat(chat),
                unreadCount: _getUnreadCount(chat),
              );
            },
          );
        },
      ),
      floatingActionButton: NeumorphicFloatingActionButton(
        onPressed: () => _showNewChatDialog(),
        style: AppNeumorphic.button.copyWith(
          color: AppColors.primaryGreen,
        ),
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
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
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: AppColors.accentGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Customer Messages Yet',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When customers message you about your products, they will appear here',
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



  void _openChat(ChatSummary chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatConversationPage(
          chatId: chat.id,
          chatTitle: _getChatTitle(chat),
        ),
      ),
    );
  }

  String _getChatTitle(ChatSummary chat) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return 'Chat';

    // Get the other participant's name
    final otherParticipantId = chat.participants
        .firstWhere((id) => id != currentUserId, orElse: () => '');

    if (otherParticipantId.isEmpty) return 'Chat';

    // Try to get participant names from chat metadata
    if (chat.metadata != null && chat.metadata!['participantNames'] != null) {
      final participantNames = Map<String, dynamic>.from(chat.metadata!['participantNames']);
      return participantNames[otherParticipantId] ?? 'Customer';
    }

    return chat.lastSenderName ?? 'Customer';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Messages'),
        content: const Text('Search functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  int _getUnreadCount(ChatSummary chat) {
    // TODO: Implement actual unread count logic
    // For now, return a random number for demonstration
    final currentUserId = _auth.currentUser?.uid;
    final isUnread = chat.lastSenderId != currentUserId && 
                     chat.lastMessageTime != null &&
                     chat.lastMessageTime!.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    
    return isUnread ? (chat.id.hashCode % 5) + 1 : 0;
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: const Text('Select a customer to start chatting with:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCustomerSelectionDialog();
            },
            child: const Text('Select Customer'),
          ),
        ],
      ),
    );
  }

  void _showCustomerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagingService.getAvailableCustomers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading customers'));
              }

              final customers = snapshot.data ?? [];

              if (customers.isEmpty) {
                return const Center(
                  child: Text('No customers available'),
                );
              }

              return ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentGreen,
                      child: Text(
                        (customer['displayName'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(customer['displayName'] ?? 'Unknown Customer'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer['email'] ?? ''),
                        if (customer['location'] != null && customer['location'].isNotEmpty)
                          Text(
                            '📍 ${customer['location']}',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _startChatWithCustomer(customer['id']);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _startChatWithCustomer(String customerId) async {
    try {
      final chatId = await _messagingService.createChatWithUser(
        customerId,
        initialMessage: 'Hello! I\'m a supplier and I\'m here to help you with your vegetable needs.',
      );
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatConversationPage(
            chatId: chatId,
            chatTitle: 'New Chat',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting chat: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }
} 