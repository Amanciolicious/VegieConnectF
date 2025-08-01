import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/messaging_service.dart';
import '../services/notification_service.dart';
import '../widgets/chat_widgets.dart' show ChatBubble, MessageInput, TypingIndicator;
import '../theme.dart';
import 'dart:async'; // Added for Timer and StreamSubscription
import 'package:flutter/services.dart'; // Added for clipboard

class ChatConversationPage extends StatefulWidget {
  final String chatId;
  final String chatTitle;

  const ChatConversationPage({
    super.key,
    required this.chatId,
    required this.chatTitle,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final MessagingService _messagingService = MessagingService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;
  bool _isTyping = false;
  Map<String, bool> _typingUsers = {};
  List<ChatMessage> _messages = [];
  Timer? _typingTimer;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _typingSubscription;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _typingTimer?.cancel();
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    // Only set typing indicator if still mounted
    if (mounted) {
      _messagingService.setTypingIndicator(widget.chatId, false);
    }
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      // Mark messages as read
      await _messagingService.markMessagesAsRead(widget.chatId);

      // Listen to messages
      _messagesSubscription = _messagingService.getChatMessages(widget.chatId).listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages.where((msg) => 
              msg.message.isNotEmpty && 
              msg.senderName.isNotEmpty && 
              msg.senderId.isNotEmpty
            ).toList();
          });
          
          // Auto-scroll to bottom for new messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients && _messages.isNotEmpty) {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });

      // Listen to typing indicators
      _typingSubscription = _messagingService.getTypingIndicator(widget.chatId).listen((typingUsers) {
        if (mounted) {
          setState(() {
            _typingUsers = typingUsers;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || !mounted) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await _messagingService.sendMessage(
        chatId: widget.chatId,
        message: message.trim(),
      );

      // Clear input
      _messageController.clear();
      
      // Stop typing indicator
      if (mounted) {
        _setTypingIndicator(false);
      }
      
      // Show notification to other user
      final currentUser = _auth.currentUser;
      if (currentUser != null && mounted) {
        _notificationService.sendChatNotification(
          senderName: currentUser.displayName ?? currentUser.email ?? 'Unknown',
          message: message.trim(),
          chatId: widget.chatId,
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setTypingIndicator(bool isTyping) {
    _messagingService.setTypingIndicator(widget.chatId, isTyping);
  }

  void _onMessageChanged(String text) {
    if (_typingTimer != null) {
      _typingTimer!.cancel();
    }

    if (text.isNotEmpty && !_isTyping && mounted) {
      _setTypingIndicator(true);
      _isTyping = true;
    }

    _typingTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_isTyping && mounted) {
        _setTypingIndicator(false);
        _isTyping = false;
      }
    });
  }

  void _showMessageOptions(ChatMessage message) {
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
              leading: const Icon(Icons.copy, color: AppColors.primaryGreen),
              title: const Text('Copy Message'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message.message);
              },
            ),
            if (message.senderId == _auth.currentUser?.uid)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.accentRed),
                title: const Text('Delete Message'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _copyMessage(String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    try {
      await _messagingService.deleteMessage(widget.chatId, message.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message deleted'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting message: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatTitle,
              style: const TextStyle(color: Colors.white),
            ),
            if (_isOtherUserTyping())
              Text(
                'typing...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showChatOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
          MessageInput(
            onSendMessage: _sendMessage,
            isLoading: _isLoading,
            onTextChanged: _onMessageChanged,
          ),
        ],
      ),
    );
  }

  bool _isOtherUserTyping() {
    final currentUserId = _auth.currentUser?.uid;
    return _typingUsers.entries.any((entry) => 
        entry.key != currentUserId && entry.value);
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
                    'Start a Conversation',
                    style: AppTextStyles.headline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a message to begin chatting',
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

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.accentGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isOwnMessage = message.senderId == _auth.currentUser?.uid;

        return AnimationConfiguration.staggeredList(
          position: index,
          duration: const Duration(milliseconds: 300),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: ChatBubble(
                message: message,
                isOwnMessage: isOwnMessage,
                onLongPress: () => _showMessageOptions(message),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChatOptions() {
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
              leading: const Icon(Icons.search, color: AppColors.primaryGreen),
              title: const Text('Search Messages'),
              onTap: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: AppColors.primaryGreen),
              title: const Text('Mute Notifications'),
              onTap: () {
                Navigator.pop(context);
                _toggleNotifications();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.accentRed),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                _showClearChatDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: AppColors.accentRed),
              title: const Text('Delete Conversation'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConversationDialog();
              },
            ),
          ],
        ),
      ),
    );
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

  void _toggleNotifications() {
    // TODO: Implement notification toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings updated'),
        backgroundColor: AppColors.primaryGreen,
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    try {
      await _messagingService.clearChat(widget.chatId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat cleared'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing chat: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  void _showDeleteConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this entire conversation? This action cannot be undone and will remove all messages permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteConversation();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation() async {
    try {
      await _messagingService.deleteConversation(widget.chatId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation deleted'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        
        // Navigate back to chat list
        Navigator.of(context).pop();
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