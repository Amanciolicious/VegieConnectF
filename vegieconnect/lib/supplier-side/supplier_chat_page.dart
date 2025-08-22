import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/services/chat_service.dart';
import 'package:vegieconnect/theme.dart';

class SupplierChatPage extends StatefulWidget {
  final String conversationId;
  final String buyerId;
  final String buyerName;
  const SupplierChatPage({super.key, required this.conversationId, required this.buyerId, required this.buyerName});

  @override
  State<SupplierChatPage> createState() => _SupplierChatPageState();
}

class _SupplierChatPageState extends State<SupplierChatPage> {
  final _controller = TextEditingController();
  final ChatService _chatService = ChatService();
  final user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _localMessages = [];

  @override
  void initState() {
    super.initState();
    _initLocal();
    // Sync offline messages when page loads
    _chatService.checkAndSyncOfflineMessages();
  }

  Future<void> _initLocal() async {
    try {
      final cached = await _chatService.loadLocalMessages(widget.conversationId);
      setState(() => _localMessages = cached);
    } catch (e) {
      print('Error loading local messages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Optimized for Infinix Smart 8 (720x1612)
    final padding = screenWidth * 0.04; // ~29px
    final messagePadding = screenWidth * 0.03; // ~22px
    final borderRadius = screenWidth * 0.03; // ~22px
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          'Chat with ${widget.buyerName}', 
          style: AppTextStyles.headline.copyWith(
            color: Colors.white, 
            fontSize: screenWidth * 0.045,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 2,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _chatService.streamMessages(widget.conversationId),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final List<Map<String, dynamic>> merged = [..._localMessages];
                if (docs.isNotEmpty) {
                  final fsMessages = docs.map((d) {
                    final m = d.data();
                    return {
                      'senderId': m['senderId'],
                      'text': m['text'],
                      'timestamp': (m['timestamp'] as Timestamp?)?.toDate().toIso8601String() ?? DateTime.now().toIso8601String(),
                    };
                  }).toList();
                  _chatService.setLocalMessages(conversationId: widget.conversationId, messages: fsMessages);
                  merged
                    ..clear()
                    ..addAll(fsMessages);
                }
                return ListView.builder(
                  padding: EdgeInsets.all(padding),
                  itemCount: merged.length,
                  itemBuilder: (context, index) {
                    final data = merged[index];
                    final isMine = data['senderId'] == user?.uid;
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                        padding: EdgeInsets.symmetric(
                          horizontal: messagePadding, 
                          vertical: screenHeight * 0.008,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? AppColors.primaryGreen : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(color: isMine ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(screenWidth),
        ],
      ),
    );
  }

  Widget _buildInputBar(double screenWidth) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, 
          vertical: screenHeight * 0.01,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Neumorphic(
                style: AppNeumorphic.inset,
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.012,
                    ),
                    hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                  ),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            NeumorphicButton(
              style: AppNeumorphic.button.copyWith(color: AppColors.primaryGreen),
              onPressed: () async {
                if (_controller.text.trim().isEmpty) return;
                await _chatService.sendMessage(
                  conversationId: widget.conversationId,
                  senderId: user!.uid,
                  text: _controller.text,
                );
                _controller.clear();
              },
              child: const Icon(Icons.send, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }
}


