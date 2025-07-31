import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_messaging_service.dart';
import '../theme.dart';
import 'chat_conversation_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final LocalMessagingService _messagingService = LocalMessagingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<LocalChatSummary>>(
        stream: _messagingService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
              ),
            );
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
                            'No Chats Yet',
                            style: AppTextStyles.headline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with a supplier to see your chats here',
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final currentUserId = _auth.currentUser?.uid;
              final otherParticipantId = chat.participants
                  .firstWhere((id) => id != currentUserId, orElse: () => '');
              final otherParticipantName = chat.participantNames[otherParticipantId] ?? 'Unknown';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Neumorphic(
                  style: AppNeumorphic.card,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                      child: Text(
                        otherParticipantName.isNotEmpty 
                            ? otherParticipantName[0].toUpperCase() 
                            : 'S',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      otherParticipantName,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (chat.lastMessage != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            chat.lastMessage!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(chat.lastMessageTime),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    trailing: chat.unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.accentRed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatConversationPage(
                            chatId: chat.id,
                            chatTitle: otherParticipantName,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
} 