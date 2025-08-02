import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/messaging_service.dart';
import '../services/chat_navigation_service.dart';
import '../theme.dart';
import 'chat_widgets.dart';

class UnifiedChatWidget extends StatefulWidget {
  final String userRole; // 'supplier' or 'buyer'
  final String? supplierId; // Only needed for buyer to start new chat
  final String? supplierName; // Only needed for buyer to start new chat

  const UnifiedChatWidget({
    super.key,
    required this.userRole,
    this.supplierId,
    this.supplierName,
  });

  @override
  State<UnifiedChatWidget> createState() => _UnifiedChatWidgetState();
}

class _UnifiedChatWidgetState extends State<UnifiedChatWidget> {
  final MessagingService _messagingService = MessagingService();
  final ChatNavigationService _chatNavigationService = ChatNavigationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        title: Text(
          widget.userRole == 'supplier' ? 'Customer Messages' : 'Messages',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (widget.userRole == 'buyer') ...[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _showSearchDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _showNewChatDialog(),
            ),
          ],
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
    final isSupplier = widget.userRole == 'supplier';
    final title = isSupplier ? 'No Customer Messages Yet' : 'No Messages Yet';
    final subtitle = isSupplier 
        ? 'When customers message you about your products, they will appear here'
        : 'Chat with suppliers by clicking the chat button on their products';

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
                    title,
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (!isSupplier) ...[
                    const SizedBox(height: 16),
                    NeumorphicButton(
                      onPressed: () => _showNewChatDialog(),
                      style: AppNeumorphic.button.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                      child: const Text(
                        'Start New Chat',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(ChatSummary chat) {
    final chatTitle = _getChatTitle(chat);
    _chatNavigationService.openExistingChat(
      context,
      chat.id,
      chatTitle,
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
      final otherName = participantNames[otherParticipantId];
      if (otherName != null) {
        return otherName;
      }
    }

    return chat.lastSenderName ?? (widget.userRole == 'supplier' ? 'Customer' : 'Supplier');
  }

  int _getUnreadCount(ChatSummary chat) {
    // TODO: Implement actual unread count logic
    final currentUserId = _auth.currentUser?.uid;
    final isUnread = chat.lastSenderId != currentUserId && 
                     chat.lastMessageTime != null &&
                     chat.lastMessageTime!.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    
    return isUnread ? (chat.id.hashCode % 5) + 1 : 0;
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

  void _showNewChatDialog() {
    if (widget.userRole == 'buyer') {
      _showSupplierSelectionDialog();
    }
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
                return Center(
                  child: Text('Error loading suppliers: ${snapshot.error}'),
                );
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
                        (supplier['displayName'] as String).isNotEmpty 
                            ? supplier['displayName'][0].toUpperCase()
                            : 'S',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(supplier['displayName'] ?? 'Unknown Supplier'),
                    subtitle: Text(supplier['businessName'] ?? supplier['email'] ?? ''),
                    onTap: () {
                      Navigator.pop(context);
                      _startChatWithSupplier(
                        supplier['id'],
                        supplier['displayName'] ?? 'Supplier',
                      );
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

  void _startChatWithSupplier(String supplierId, String supplierName) {
    _chatNavigationService.startChatWithSupplierById(
      context,
      supplierId,
      supplierName,
    );
  }

  void _showDeleteChatDialog(ChatSummary chat) {
    final chatTitle = _getChatTitle(chat);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete your conversation with $chatTitle? This action cannot be undone.'),
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation removed from your chat list'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting conversation: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }
} 