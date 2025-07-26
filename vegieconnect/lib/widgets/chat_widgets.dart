import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/messaging_service.dart';
import '../theme.dart';

// Chat bubble widget
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isOwnMessage;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 300),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isOwnMessage) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accentGreen,
                    child: Text(
                      message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: GestureDetector(
                    onLongPress: onLongPress,
                    child: Neumorphic(
                      style: AppNeumorphic.card.copyWith(
                        color: isOwnMessage ? AppColors.primaryGreen : AppColors.card,
                        depth: isOwnMessage ? 3 : 2,
                      ),
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isOwnMessage) ...[
                              Text(
                                message.senderName,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (message.imageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: message.imageUrl!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: AppColors.shadowLight,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: AppColors.shadowLight,
                                    child: const Icon(Icons.error),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              message.message,
                              style: AppTextStyles.body.copyWith(
                                color: isOwnMessage ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(message.timestamp),
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 11,
                                    color: isOwnMessage ? Colors.white70 : AppColors.textSecondary,
                                  ),
                                ),
                                if (isOwnMessage) ...[
                                  const SizedBox(width: 4),
                                  _buildMessageStatus(message.status),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isOwnMessage) const SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageStatus(MessageStatus status) {
    IconData icon;
    Color color;
    
    switch (status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.grey;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.grey;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = AppColors.accentGreen;
        break;
      case MessageStatus.failed:
        icon = Icons.error;
        color = AppColors.accentRed;
        break;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }

  String _formatTime(DateTime time) {
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
}

// Message input widget
class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String)? onSendImage;
  final Function(String)? onTextChanged;
  final bool isLoading;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.onSendImage,
    this.onTextChanged,
    this.isLoading = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _controller.text.isNotEmpty;
    });
    
    // Notify parent about text changes for typing indicators
    widget.onTextChanged?.call(_controller.text);
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    
    widget.onSendMessage(text.trim());
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (widget.onSendImage != null) ...[
              NeumorphicButton(
                onPressed: widget.isLoading ? null : () {
                  // TODO: Implement image picker
                  widget.onSendImage?.call('image_url');
                },
                style: AppNeumorphic.button.copyWith(
                  color: AppColors.accentGreen,
                ),
                child: const Icon(
                  Icons.attach_file,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Neumorphic(
                style: AppNeumorphic.inset,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: !widget.isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _handleSubmitted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            NeumorphicButton(
              onPressed: _isComposing && !widget.isLoading ? () {
                _handleSubmitted(_controller.text);
              } : null,
              style: AppNeumorphic.button.copyWith(
                color: _isComposing && !widget.isLoading 
                    ? AppColors.primaryGreen 
                    : AppColors.shadowLight,
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat list item widget
class ChatListItem extends StatelessWidget {
  final ChatSummary chat;
  final VoidCallback onTap;
  final bool isSelected;

  const ChatListItem({
    super.key,
    required this.chat,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 300),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Neumorphic(
            style: AppNeumorphic.card.copyWith(
              color: isSelected ? AppColors.primaryGreen.withOpacity(0.1) : AppColors.card,
            ),
            child: ListTile(
              onTap: onTap,
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentGreen,
                child: Text(
                  _getChatTitle()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                _getChatTitle(),
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (chat.lastMessage != null) ...[
                    Text(
                      chat.lastMessage!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      if (chat.lastSenderName != null) ...[
                        Text(
                          '${chat.lastSenderName}: ',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      if (chat.lastMessageTime != null) ...[
                        Text(
                          _formatTime(chat.lastMessageTime!),
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: _buildUnreadBadge(),
            ),
          ),
        ),
      ),
    );
  }

  String _getChatTitle() {
    // TODO: Implement proper chat title logic based on participants
    return chat.lastSenderName ?? 'Chat';
  }

  Widget _buildUnreadBadge() {
    // TODO: Implement unread message count
    return Container();
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

// Typing indicator widget
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accentGreen,
            child: const Text(
              '?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Neumorphic(
            style: AppNeumorphic.card,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(0),
                  const SizedBox(width: 4),
                  _buildDot(1),
                  const SizedBox(width: 4),
                  _buildDot(2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final delay = index * 0.2;
        final opacity = _animation.value > delay && _animation.value < delay + 0.4
            ? 1.0
            : 0.3;
        
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 

// Star rating widget
class StarRating extends StatelessWidget {
  final int rating;
  final int maxRating;
  final void Function(int)? onRatingChanged;
  final double size;
  final Color color;
  final Color unfilledColor;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.onRatingChanged,
    this.size = 28,
    this.color = Colors.orange,
    this.unfilledColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final isFilled = index < rating;
        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged!(index + 1) : null,
          child: Icon(
            Icons.star,
            color: isFilled ? color : unfilledColor,
            size: size,
          ),
        );
      }),
    );
  }
} 