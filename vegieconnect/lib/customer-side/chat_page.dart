import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/messaging_service.dart';
import '../widgets/chat_widgets.dart';
import '../theme.dart';
import 'chat_conversation_page.dart';

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
                    'No Messages Yet',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a conversation with suppliers or other users',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  NeumorphicButton(
                    onPressed: () => _showNewChatDialog(),
                    style: AppNeumorphic.button,
                    child: const Text('Start Chat'),
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

    // For now, return a simple title. In a real app, you'd fetch user details
    return chat.lastSenderName ?? 'User';
  }

  void _showNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: const Text('Select a supplier to start chatting with:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSupplierSelectionDialog();
            },
            child: const Text('Select Supplier'),
          ),
        ],
      ),
    );
  }

  void _showSupplierSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Supplier'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messagingService.getAvailableSuppliers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading suppliers'));
              }

              final suppliers = snapshot.data ?? [];

              if (suppliers.isEmpty) {
                return const Center(
                  child: Text('No suppliers available'),
                );
              }

              return ListView.builder(
                itemCount: suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = suppliers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.accentGreen,
                      child: Text(
                        (supplier['displayName'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(supplier['displayName'] ?? 'Unknown Supplier'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(supplier['email'] ?? ''),
                        if (supplier['businessName'] != null && supplier['businessName'].isNotEmpty)
                          Text(
                            '🏪 ${supplier['businessName']}',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (supplier['location'] != null && supplier['location'].isNotEmpty)
                          Text(
                            '📍 ${supplier['location']}',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _startChatWithSupplier(supplier['id']);
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

  void _startChatWithSupplier(String supplierId) async {
    try {
      final chatId = await _messagingService.createChatWithUser(
        supplierId,
        initialMessage: 'Hello! I\'m interested in your fresh vegetables. Do you have any available today?',
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
} 