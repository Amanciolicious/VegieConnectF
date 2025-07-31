import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../services/local_messaging_service.dart';
import '../theme.dart';

class LocalMessageBubble extends StatelessWidget {
  final LocalMessage message;
  final bool isOwnMessage;
  final VoidCallback? onLongPress;

  const LocalMessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          left: isOwnMessage ? 50 : 10,
          right: isOwnMessage ? 10 : 50,
          top: 5,
          bottom: 5,
        ),
        child: Row(
          mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isOwnMessage) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isOwnMessage ? AppColors.primaryGreen : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isOwnMessage)
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isOwnMessage ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    if (!isOwnMessage) const SizedBox(height: 4),
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isOwnMessage ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: isOwnMessage 
                                ? Colors.white.withOpacity(0.7) 
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (isOwnMessage) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 12,
                            color: message.isRead 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isOwnMessage) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                child: Text(
                  message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
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

class LocalChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String) onTextChanged;
  final bool isLoading;

  const LocalChatInput({
    super.key,
    required this.onSendMessage,
    required this.onTextChanged,
    this.isLoading = false,
  });

  @override
  State<LocalChatInput> createState() => _LocalChatInputState();
}

class _LocalChatInputState extends State<LocalChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _canSend = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {
      _canSend = text.trim().isNotEmpty;
    });
    widget.onTextChanged(text);
  }

  void _sendMessage() {
    if (_canSend && !widget.isLoading) {
      final message = _controller.text.trim();
      widget.onSendMessage(message);
      _controller.clear();
      setState(() {
        _canSend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Neumorphic(
              style: AppNeumorphic.inset.copyWith(
                boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(25)),
              ),
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: widget.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 12),
          NeumorphicButton(
            style: AppNeumorphic.button.copyWith(
              color: _canSend ? AppColors.primaryGreen : AppColors.textSecondary.withOpacity(0.3),
              boxShape: NeumorphicBoxShape.circle(),
            ),
            onPressed: _canSend && !widget.isLoading ? _sendMessage : null,
            child: Icon(
              Icons.send,
              color: _canSend ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class LocalTypingIndicator extends StatelessWidget {
  final Map<String, bool> typingUsers;
  final String currentUserId;

  const LocalTypingIndicator({
    super.key,
    required this.typingUsers,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final typingUserIds = typingUsers.entries
        .where((entry) => entry.value && entry.key != currentUserId)
        .map((entry) => entry.key)
        .toList();

    if (typingUserIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 20, top: 5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${typingUserIds.first} is typing...',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 