import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/messaging_service.dart';
import '../services/chat_navigation_service.dart';
import '../theme.dart';
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
                onDelete: () => _showDeleteChatDialog(chat),
              );
            },
          );
        },
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
    final chatNavigationService = ChatNavigationService();
    chatNavigationService.openExistingChat(
      context,
      chat.id,
      _getChatTitle(chat),
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

    // Try to get user data for better display
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

  int _getUnreadCount(ChatSummary chat) {
    // TODO: Implement actual unread count logic
    // For now, return a random number for demonstration
    final currentUserId = _auth.currentUser?.uid;
    final isUnread = chat.lastSenderId != currentUserId && 
                     chat.lastMessageTime != null &&
                     chat.lastMessageTime!.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    
    return isUnread ? (chat.id.hashCode % 5) + 1 : 0;
  }

  void _showDeleteChatDialog(ChatSummary chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete your conversation with ${chat.lastSenderName ?? 'this user'}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteChat(chat);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(ChatSummary chat) async {
    try {
      await _messagingService.deleteChat(chat.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conversation removed from your chat list'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting conversation: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }
} 