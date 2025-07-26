import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controllers for real-time messaging
  final Map<String, StreamController<List<ChatMessage>>> _chatControllers = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _chatSubscriptions = {};
  
  // Typing indicators
  final Map<String, StreamController<Map<String, bool>>> _typingControllers = {};
  final Map<String, StreamSubscription<DocumentSnapshot>> _typingSubscriptions = {};

  // Chat cache for performance
  final Map<String, List<ChatMessage>> _chatCache = {};
  final int _maxCacheSize = 100;

  // Initialize messaging service
  Future<void> initialize() async {
    try {
      // Listen for user authentication changes
      _auth.authStateChanges().listen((User? user) {
        if (user == null) {
          _clearAllChats();
        }
      });
      
      debugPrint('MessagingService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing MessagingService: $e');
    }
  }

  // Get or create chat stream
  Stream<List<ChatMessage>> getChatStream(String chatId) {
    if (!_chatControllers.containsKey(chatId)) {
      _initializeChatStream(chatId);
    }
    return _chatControllers[chatId]!.stream;
  }

  // Get typing indicators stream
  Stream<Map<String, bool>> getTypingStream(String chatId) {
    if (!_typingControllers.containsKey(chatId)) {
      _initializeTypingStream(chatId);
    }
    return _typingControllers[chatId]!.stream;
  }

  // Initialize chat stream
  void _initializeChatStream(String chatId) {
    final controller = StreamController<List<ChatMessage>>.broadcast();
    _chatControllers[chatId] = controller;

    // Load cached messages first
    if (_chatCache.containsKey(chatId)) {
      controller.add(_chatCache[chatId]!);
    }

    // Listen to Firestore for real-time updates
    final subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snapshot) {
        final messages = snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .toList();
        
        // Update cache
        _chatCache[chatId] = messages;
        _manageCacheSize();
        
        // Add to stream
        controller.add(messages);
      },
      onError: (error) {
        debugPrint('Error in chat stream for $chatId: $error');
      },
    );

    _chatSubscriptions[chatId] = subscription;
  }

  // Initialize typing indicators stream
  void _initializeTypingStream(String chatId) {
    final controller = StreamController<Map<String, bool>>.broadcast();
    _typingControllers[chatId] = controller;

    final subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final typingUsers = Map<String, bool>.from(data['typingUsers'] ?? {});
          controller.add(typingUsers);
        }
      },
      onError: (error) {
        debugPrint('Error in typing stream for $chatId: $error');
      },
    );

    _typingSubscriptions[chatId] = subscription;
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final chatMessage = ChatMessage(
        id: '', // Will be set by Firestore
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'Unknown',
        message: message,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
        status: MessageStatus.sending,
      );

      // Optimistically add to local cache
      _addMessageToCache(chatId, chatMessage);

      // Send to Firestore
      final docRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(chatMessage.toFirestore());

      // Update message with Firestore ID and status
      final sentMessage = chatMessage.copyWith(
        id: docRef.id,
        status: MessageStatus.sent,
      );

      // Update cache with sent message
      _updateMessageInCache(chatId, sentMessage);

      // Update chat metadata
      await _updateChatMetadata(chatId, sentMessage);

      // Stop typing indicator
      await stopTyping(chatId);

      debugPrint('Message sent successfully: ${docRef.id}');
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Update message status to failed
      final failedMessage = ChatMessage(
        id: '',
        senderId: _auth.currentUser?.uid ?? '',
        senderName: _auth.currentUser?.displayName ?? 'Unknown',
        message: message,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
        status: MessageStatus.failed,
      );
      _addMessageToCache(chatId, failedMessage);
      rethrow;
    }
  }

  // Start typing indicator
  Future<void> startTyping(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('chats').doc(chatId).set({
        'typingUsers': {
          user.uid: true,
        },
        'lastTypingUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error starting typing: $e');
    }
  }

  // Stop typing indicator
  Future<void> stopTyping(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('chats').doc(chatId).update({
        'typingUsers.$user.uid': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('Error stopping typing: $e');
    }
  }

  // Add message to cache
  void _addMessageToCache(String chatId, ChatMessage message) {
    if (!_chatCache.containsKey(chatId)) {
      _chatCache[chatId] = [];
    }
    _chatCache[chatId]!.insert(0, message);
    _manageCacheSize();
    
    // Notify stream
    if (_chatControllers.containsKey(chatId)) {
      _chatControllers[chatId]!.add(_chatCache[chatId]!);
    }
  }

  // Update message in cache
  void _updateMessageInCache(String chatId, ChatMessage updatedMessage) {
    if (_chatCache.containsKey(chatId)) {
      final index = _chatCache[chatId]!.indexWhere((msg) => msg.id == updatedMessage.id);
      if (index != -1) {
        _chatCache[chatId]![index] = updatedMessage;
        _chatControllers[chatId]?.add(_chatCache[chatId]!);
      }
    }
  }

  // Update chat metadata
  Future<void> _updateChatMetadata(String chatId, ChatMessage lastMessage) async {
    try {
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': lastMessage.message,
        'lastMessageTime': lastMessage.timestamp,
        'lastSenderId': lastMessage.senderId,
        'lastSenderName': lastMessage.senderName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating chat metadata: $e');
    }
  }

  // Create or get chat between users
  Future<String> createOrGetChat(String otherUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final chatId = _generateChatId(user.uid, otherUserId);

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Create new chat
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [user.uid, otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'typingUsers': {},
        });
      }

      return chatId;
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      rethrow;
    }
  }

  // Create chat with supplier
  Future<String> createChatWithSupplier(String supplierId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final chatId = _generateChatId(user.uid, supplierId);

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Get supplier details
        final supplierDoc = await _firestore.collection('users').doc(supplierId).get();
        final supplierData = supplierDoc.data();
        final supplierName = supplierData?['displayName'] ?? supplierData?['email'] ?? 'Supplier';

        // Create new chat
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [user.uid, supplierId],
          'participantNames': {
            user.uid: user.displayName ?? user.email ?? 'User',
            supplierId: supplierName,
          },
          'chatType': 'supplier_buyer',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'typingUsers': {},
        });
      }

      return chatId;
    } catch (e) {
      debugPrint('Error creating chat with supplier: $e');
      rethrow;
    }
  }

  // Generate chat ID
  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Get user chats
  Stream<List<ChatSummary>> getUserChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSummary.fromFirestore(doc))
            .toList());
  }

  // Get supplier chats (for supplier dashboard)
  Stream<List<ChatSummary>> getSupplierChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .where('chatType', isEqualTo: 'supplier_buyer')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSummary.fromFirestore(doc))
            .toList());
  }

  // Get buyer chats (for buyer dashboard)
  Stream<List<ChatSummary>> getBuyerChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .where('chatType', isEqualTo: 'supplier_buyer')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatSummary.fromFirestore(doc))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      
      final unreadMessages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: user.uid)
          .where('readBy', arrayContains: user.uid)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([user.uid]),
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Remove from cache
      if (_chatCache.containsKey(chatId)) {
        _chatCache[chatId]!.removeWhere((msg) => msg.id == messageId);
        _chatControllers[chatId]?.add(_chatCache[chatId]!);
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          int totalUnread = 0;
          for (final chatDoc in snapshot.docs) {
            final unreadMessages = await _firestore
                .collection('chats')
                .doc(chatDoc.id)
                .collection('messages')
                .where('senderId', isNotEqualTo: user.uid)
                .where('readBy', arrayContains: user.uid)
                .get();
            totalUnread += unreadMessages.docs.length;
          }
          return totalUnread;
        });
  }

  // Manage cache size
  void _manageCacheSize() {
    if (_chatCache.length > _maxCacheSize) {
      final oldestChat = _chatCache.keys.first;
      _chatCache.remove(oldestChat);
    }
  }

  // Clear all chats
  void _clearAllChats() {
    for (final subscription in _chatSubscriptions.values) {
      subscription.cancel();
    }
    _chatSubscriptions.clear();
    
    for (final controller in _chatControllers.values) {
      controller.close();
    }
    _chatControllers.clear();
    
    for (final subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    _typingSubscriptions.clear();
    
    for (final controller in _typingControllers.values) {
      controller.close();
    }
    _typingControllers.clear();
    
    _chatCache.clear();
  }

  // Dispose resources
  void dispose() {
    _clearAllChats();
  }
}

// Chat message model
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final MessageStatus status;
  final List<String> readBy;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    required this.metadata,
    required this.status,
    this.readBy = const [],
    this.readAt,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? message,
    String? imageUrl,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    MessageStatus? status,
    List<String>? readBy,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      readBy: readBy ?? this.readBy,
      readAt: readAt ?? this.readAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'metadata': metadata,
      'status': status.toString(),
      'readBy': readBy,
      'readAt': readAt,
    };
  }

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      readBy: List<String>.from(data['readBy'] ?? []),
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
    );
  }
}

// Message status enum
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

// Chat summary model
class ChatSummary {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final String? lastSenderName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  ChatSummary({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastSenderId,
    this.lastSenderName,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastSenderId': lastSenderId,
      'lastSenderName': lastSenderName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'metadata': metadata,
    };
  }

  factory ChatSummary.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSummary(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null 
          ? (data['lastMessageTime'] as Timestamp).toDate() 
          : null,
      lastSenderId: data['lastSenderId'],
      lastSenderName: data['lastSenderName'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata']) 
          : null,
    );
  }
} 