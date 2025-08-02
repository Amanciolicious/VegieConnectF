import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/messaging_service.dart';
import '../services/chat_navigation_service.dart';
import '../widgets/chat_widgets.dart';
import '../theme.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required supplierId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search functionality
              _showSearchDialog();
            },
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
                    'No Messages Yet',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chat with suppliers by clicking the chat button on their products',
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
      return participantNames[otherParticipantId] ?? chat.lastSenderName ?? 'Supplier';
    }

    return chat.lastSenderName ?? 'Supplier';
  }



  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Chats'),
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
    return chat.lastMessageTime != null && 
           DateTime.now().difference(chat.lastMessageTime!).inHours < 24 
           ? (chat.id.hashCode % 5) + 1 
           : 0;
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