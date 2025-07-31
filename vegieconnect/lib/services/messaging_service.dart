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
          'metadata': {},
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
          'metadata': {},
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
    if (user == null) {
      debugPrint('getUserChats: No authenticated user');
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) => ChatSummary.fromFirestore(doc))
                  .where((chat) => chat.participants.isNotEmpty) // Filter out invalid chats
                  .toList();
            } catch (e) {
              debugPrint('getUserChats: Error processing chat documents: $e');
              return <ChatSummary>[];
            }
          })
          .handleError((error) {
            debugPrint('getUserChats: Firestore error: $error');
            return <ChatSummary>[];
          });
    } catch (e) {
      debugPrint('getUserChats: Error setting up stream: $e');
      return Stream.value(<ChatSummary>[]);
    }
  }

  // Get supplier chats (for supplier dashboard)
  Stream<List<ChatSummary>> getSupplierChats() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('getSupplierChats: No authenticated user');
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .where('chatType', isEqualTo: 'supplier_buyer')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) => ChatSummary.fromFirestore(doc))
                  .where((chat) => chat.participants.isNotEmpty) // Filter out invalid chats
                  .toList();
            } catch (e) {
              debugPrint('getSupplierChats: Error processing chat documents: $e');
              return <ChatSummary>[];
            }
          })
          .handleError((error) {
            debugPrint('getSupplierChats: Firestore error: $error');
            return <ChatSummary>[];
          });
    } catch (e) {
      debugPrint('getSupplierChats: Error setting up stream: $e');
      return Stream.value(<ChatSummary>[]);
    }
  }

  // Get buyer chats (for buyer dashboard)
  Stream<List<ChatSummary>> getBuyerChats() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('getBuyerChats: No authenticated user');
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .where('chatType', isEqualTo: 'supplier_buyer')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) => ChatSummary.fromFirestore(doc))
                  .where((chat) => chat.participants.isNotEmpty) // Filter out invalid chats
                  .toList();
            } catch (e) {
              debugPrint('getBuyerChats: Error processing chat documents: $e');
              return <ChatSummary>[];
            }
          })
          .handleError((error) {
            debugPrint('getBuyerChats: Firestore error: $error');
            return <ChatSummary>[];
          });
    } catch (e) {
      debugPrint('getBuyerChats: Error setting up stream: $e');
      return Stream.value(<ChatSummary>[]);
    }
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

  // Enhanced method to get real customer-supplier chats
  Stream<List<ChatSummary>> getRealCustomerSupplierChats() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('getRealCustomerSupplierChats: No authenticated user');
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .where('chatType', isEqualTo: 'supplier_buyer')
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) => ChatSummary.fromFirestore(doc))
                  .where((chat) => chat.participants.isNotEmpty)
                  .toList();
            } catch (e) {
              debugPrint('getRealCustomerSupplierChats: Error processing chat documents: $e');
              return <ChatSummary>[];
            }
          })
          .handleError((error) {
            debugPrint('getRealCustomerSupplierChats: Firestore error: $error');
            return <ChatSummary>[];
          });
    } catch (e) {
      debugPrint('getRealCustomerSupplierChats: Error setting up stream: $e');
      return Stream.value(<ChatSummary>[]);
    }
  }

  // Enhanced method to get available customers for suppliers
  Stream<List<Map<String, dynamic>>> getAvailableCustomers() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'buyer')
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) => {
                    'id': doc.id,
                    'displayName': doc.data()['displayName'] ?? 'Unknown Customer',
                    'email': doc.data()['email'] ?? '',
                    'phone': doc.data()['phone'] ?? '',
                    'location': doc.data()['location'] ?? '',
                  })
                  .where((customer) => customer['id'] != user.uid)
                  .toList();
            } catch (e) {
              debugPrint('getAvailableCustomers: Error processing customer documents: $e');
              return <Map<String, dynamic>>[];
            }
          })
          .handleError((error) {
            debugPrint('getAvailableCustomers: Firestore error: $error');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('getAvailableCustomers: Error setting up stream: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  // Enhanced method to get available suppliers for customers
  Stream<List<Map<String, dynamic>>> getAvailableSuppliers() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    try {
      return _firestore
          .collection('users')
          .where('role', isEqualTo: 'supplier')
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) => {
                    'id': doc.id,
                    'displayName': doc.data()['displayName'] ?? 'Unknown Supplier',
                    'email': doc.data()['email'] ?? '',
                    'phone': doc.data()['phone'] ?? '',
                    'location': doc.data()['location'] ?? '',
                    'businessName': doc.data()['businessName'] ?? '',
                  })
                  .where((supplier) => supplier['id'] != user.uid)
                  .toList();
            } catch (e) {
              debugPrint('getAvailableSuppliers: Error processing supplier documents: $e');
              return <Map<String, dynamic>>[];
            }
          })
          .handleError((error) {
            debugPrint('getAvailableSuppliers: Firestore error: $error');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      debugPrint('getAvailableSuppliers: Error setting up stream: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  // Enhanced method to create chat with real user data
  Future<String> createChatWithUser(String otherUserId, {String? initialMessage}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Get user data for chat metadata
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
      
      if (!userDoc.exists || !otherUserDoc.exists) {
        throw Exception('User data not found');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final otherUserData = otherUserDoc.data() as Map<String, dynamic>;

      // Create chat with enhanced metadata
      final chatRef = _firestore.collection('chats').doc();
      await chatRef.set({
        'participants': [user.uid, otherUserId],
        'chatType': 'supplier_buyer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'typingUsers': {},
        'metadata': {
          'participantNames': {
            user.uid: userData['displayName'] ?? userData['email'] ?? 'Unknown',
            otherUserId: otherUserData['displayName'] ?? otherUserData['email'] ?? 'Unknown',
          },
          'participantRoles': {
            user.uid: userData['role'] ?? 'unknown',
            otherUserId: otherUserData['role'] ?? 'unknown',
          },
          'businessInfo': otherUserData['businessName'] != null ? {
            'businessName': otherUserData['businessName'],
            'location': otherUserData['location'],
          } : null,
        },
      });

      final chatId = chatRef.id;

      // Send initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await sendMessage(
          chatId: chatId,
          message: initialMessage,
        );
      }

      debugPrint('Real chat created successfully: $chatId');
      return chatId;
    } catch (e) {
      debugPrint('Error creating real chat: $e');
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

  // Get chat messages stream
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return getChatStream(chatId);
  }

  // Get typing indicator stream
  Stream<Map<String, bool>> getTypingIndicator(String chatId) {
    return getTypingStream(chatId);
  }

  // Set typing indicator
  Future<void> setTypingIndicator(String chatId, bool isTyping) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (isTyping) {
        await startTyping(chatId);
      } else {
        await stopTyping(chatId);
      }
    } catch (e) {
      debugPrint('Error setting typing indicator: $e');
    }
  }

  // Clear chat (delete all messages)
  Future<void> clearChat(String chatId) async {
    try {
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear cache
      _chatCache.remove(chatId);
      _chatControllers[chatId]?.add([]);

      debugPrint('Chat cleared successfully: $chatId');
    } catch (e) {
      debugPrint('Error clearing chat: $e');
      rethrow;
    }
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
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('ChatMessage.fromFirestore: Document data is null for ${doc.id}');
        return ChatMessage(
          id: doc.id,
          senderId: '',
          senderName: '',
          message: '',
          timestamp: DateTime.now(),
          metadata: {},
          status: MessageStatus.failed,
        );
      }
      
      return ChatMessage(
        id: doc.id,
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? '',
        message: data['message'] ?? '',
        imageUrl: data['imageUrl'],
        timestamp: data['timestamp'] != null 
            ? (data['timestamp'] is Timestamp 
                ? (data['timestamp'] as Timestamp).toDate() 
                : DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now())
            : DateTime.now(),
        metadata: data['metadata'] != null 
            ? Map<String, dynamic>.from(data['metadata']) 
            : {},
        status: MessageStatus.values.firstWhere(
          (e) => e.toString() == data['status'],
          orElse: () => MessageStatus.sent,
        ),
        readBy: data['readBy'] != null 
            ? List<String>.from(data['readBy']) 
            : [],
        readAt: data['readAt'] != null 
            ? (data['readAt'] is Timestamp 
                ? (data['readAt'] as Timestamp).toDate() 
                : DateTime.tryParse(data['readAt'].toString()))
            : null,
      );
    } catch (e) {
      debugPrint('ChatMessage.fromFirestore: Error parsing document ${doc.id}: $e');
      return ChatMessage(
        id: doc.id,
        senderId: '',
        senderName: '',
        message: '',
        timestamp: DateTime.now(),
        metadata: {},
        status: MessageStatus.failed,
      );
    }
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
    try {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('ChatSummary.fromFirestore: Document data is null for ${doc.id}');
        return ChatSummary(
          id: doc.id,
          participants: [],
        );
      }
      
      return ChatSummary(
        id: doc.id,
        participants: List<String>.from(data['participants'] ?? []),
        lastMessage: data['lastMessage'],
        lastMessageTime: data['lastMessageTime'] != null 
            ? (data['lastMessageTime'] is Timestamp 
                ? (data['lastMessageTime'] as Timestamp).toDate() 
                : DateTime.tryParse(data['lastMessageTime'].toString()) ?? DateTime.now())
            : null,
        lastSenderId: data['lastSenderId'],
        lastSenderName: data['lastSenderName'],
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] is Timestamp 
                ? (data['createdAt'] as Timestamp).toDate() 
                : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
            : null,
        updatedAt: data['updatedAt'] != null 
            ? (data['updatedAt'] is Timestamp 
                ? (data['updatedAt'] as Timestamp).toDate() 
                : DateTime.tryParse(data['updatedAt'].toString()) ?? DateTime.now())
            : null,
        metadata: data['metadata'] != null 
            ? Map<String, dynamic>.from(data['metadata']) 
            : null,
      );
    } catch (e) {
      debugPrint('ChatSummary.fromFirestore: Error parsing document ${doc.id}: $e');
      return ChatSummary(
        id: doc.id,
        participants: [],
      );
    }
  }
} 