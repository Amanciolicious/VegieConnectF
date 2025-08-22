import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/services/chat_service.dart';
import 'package:vegieconnect/theme.dart';
import 'buyer_chat_page.dart';

class CustomerMessagesPage extends StatefulWidget {
  const CustomerMessagesPage({super.key});

  @override
  State<CustomerMessagesPage> createState() => _CustomerMessagesPageState();
}

class _CustomerMessagesPageState extends State<CustomerMessagesPage> {
  final ChatService _chatService = ChatService();
  final Set<String> _selectedConversations = {};
  bool _isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Please log in to view messages',
            style: TextStyle(fontSize: screenWidth * 0.04),
          ),
        ),
      );
    }

    // Optimized for Infinix Smart 8 (720x1612)
    final padding = screenWidth * 0.04; // ~29px

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          _isSelectionMode ? '${_selectedConversations.length} selected' : 'My Messages',
          style: AppTextStyles.headline.copyWith(
            color: Colors.white,
            fontSize: screenWidth * 0.045,
          ),
        ),
        elevation: 2,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(Icons.delete, color: Colors.white, size: screenWidth * 0.05),
              onPressed: _deleteSelectedConversations,
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: screenWidth * 0.05),
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedConversations.clear();
                });
              },
            ),
          ],
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _chatService.streamBuyerConversations(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryGreen),
                  SizedBox(height: 16),
                  Text('Loading conversations...', style: AppTextStyles.subtitle),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.accentRed),
                  SizedBox(height: 16),
                  Text('Error loading messages', style: AppTextStyles.subtitle),
                  SizedBox(height: 8),
                  Text('${snapshot.error}', style: AppTextStyles.caption),
                ],
              ),
            );
          }

          final allConversations = snapshot.data?.docs ?? [];
          
          // Filter conversations on client side
          final conversations = allConversations.where((doc) {
            final data = doc.data();
            final isActive = data['isActive'] ?? true;
            final hiddenFor = List<String>.from(data['hiddenFor'] ?? []);
            return isActive && !hiddenFor.contains(user.uid);
          }).toList();
          
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.accentGreen),
                  SizedBox(height: 24),
                  Text('No conversations yet', style: AppTextStyles.headline),
                  SizedBox(height: 12),
                  Text(
                    'Start chatting with suppliers by\nvisiting product pages',
                    style: AppTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(padding),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index].data();
              final conversationId = conversations[index].id;
              final supplierName = conv['supplierName'] ?? 'Unknown Supplier';
              final lastMessage = conv['lastMessage'] ?? '';
              final lastMessageTime = conv['lastMessageTime'] as Timestamp?;
              final isSelected = _selectedConversations.contains(conversationId);

              return Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                child: Neumorphic(
                  style: AppNeumorphic.card.copyWith(
                    color: isSelected ? AppColors.accentGreen.withOpacity(0.3) : AppColors.card,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(padding),
                    leading: CircleAvatar(
                      radius: screenWidth * 0.05,
                      backgroundColor: AppColors.primaryGreen,
                      child: Text(
                        supplierName.isNotEmpty ? supplierName[0].toUpperCase() : 'S',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                    title: Text(
                      supplierName,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.04,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          lastMessage.isEmpty ? 'No messages yet' : lastMessage,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: screenWidth * 0.035,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (lastMessageTime != null) ...[
                          SizedBox(height: screenHeight * 0.003),
                          Text(
                            _formatTime(lastMessageTime.toDate()),
                            style: AppTextStyles.caption.copyWith(
                              fontSize: screenWidth * 0.03,
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: _isSelectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (value) => _toggleSelection(conversationId),
                            activeColor: AppColors.primaryGreen,
                          )
                        : PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'delete') {
                                await _deleteConversation(conversationId);
                              } else if (value == 'hide') {
                                await _hideConversation(conversationId);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'hide',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility_off, size: screenWidth * 0.04),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text('Hide', style: TextStyle(fontSize: screenWidth * 0.035)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red, size: screenWidth * 0.04),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text('Delete', style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.035)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                    onTap: () {
                      if (_selectedConversations.isNotEmpty) {
                        _toggleSelection(conversationId);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BuyerChatPage(
                              supplierId: conv['supplierId'],
                              supplierName: supplierName,
                            ),
                          ),
                        );
                      }
                    },
                    onLongPress: () => _toggleSelection(conversationId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleSelection(String conversationId) {
    setState(() {
      if (_selectedConversations.contains(conversationId)) {
        _selectedConversations.remove(conversationId);
        if (_selectedConversations.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedConversations.add(conversationId);
      }
    });
  }

  Future<void> _deleteSelectedConversations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete Conversations', style: AppTextStyles.subtitle),
        content: Text(
          'Are you sure you want to delete ${_selectedConversations.length} conversation(s)?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: AppTextStyles.body.copyWith(color: AppColors.accentRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final conversationId in _selectedConversations) {
          await _chatService.hideConversationForBuyer(
            conversationId: conversationId,
            buyerId: user.uid,
          );
        }
        setState(() {
          _isSelectionMode = false;
          _selectedConversations.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversations deleted'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting conversations: $e'),
            backgroundColor: AppColors.accentRed,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _deleteConversation(String conversationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Conversation'),
        content: Text('Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ChatService().deleteConversation(conversationId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversation deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete conversation: $e')),
        );
      }
    }
  }

  Future<void> _hideConversation(String conversationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await ChatService().hideConversation(conversationId, user.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversation hidden')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to hide conversation: $e')),
      );
    }
  }
}
