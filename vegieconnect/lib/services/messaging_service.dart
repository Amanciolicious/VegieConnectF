import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Added for jsonDecode and jsonEncode

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

  // Deleted chats tracking (per user)
  final Map<String, Set<String>> _deletedChats = {};

  // User data cache for better performance
  final Map<String, Map<String, dynamic>> _userCache = {};
  final int _maxUserCacheSize = 50;

  // Initialize messaging service
  Future<void> initialize() async {
    try {
      // Listen for user authentication changes
      _auth.authStateChanges().listen((User? user) {
        if (user == null) {
          _clearAllChats();
        } else {
          _loadDeletedChats(user.uid);
          _loadUserData(user.uid);
        }
      });
      
      debugPrint('MessagingService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing MessagingService: $e');
    }
  }

  // Load user data for better chat experience
  Future<void> _loadUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _userCache[userId] = userDoc.data()!;
        _manageUserCacheSize();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Manage user cache size
  void _manageUserCacheSize() {
    if (_userCache.length > _maxUserCacheSize) {
      final oldestUser = _userCache.keys.first;
      _userCache.remove(oldestUser);
    }
  }

  // Get user data with caching
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        _userCache[userId] = userDoc.data()!;
        _manageUserCacheSize();
        return _userCache[userId];
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return null;
  }

  // Load deleted chats for user
  Future<void> _loadDeletedChats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedChatsJson = prefs.getString('deleted_chats_$userId');
      if (deletedChatsJson != null) {
        final List<dynamic> deletedList = jsonDecode(deletedChatsJson);
        _deletedChats[userId] = Set<String>.from(deletedList);
      } else {
        _deletedChats[userId] = {};
      }
    } catch (e) {
      debugPrint('Error loading deleted chats: $e');
      _deletedChats[userId] = {};
    }
  }

  // Save deleted chats for user
  Future<void> _saveDeletedChats(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedList = _deletedChats[userId]?.toList() ?? [];
      await prefs.setString('deleted_chats_$userId', jsonEncode(deletedList));
    } catch (e) {
      debugPrint('Error saving deleted chats: $e');
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

  // Initialize chat stream with enhanced error handling
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
        try {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .where((msg) => 
                  msg.message.isNotEmpty && 
                  msg.senderId.isNotEmpty &&
                  msg.senderName.isNotEmpty)
              .toList();
          
          // Update cache
          _chatCache[chatId] = messages;
          _manageCacheSize();
          
          // Add to stream
          controller.add(messages);
        } catch (e) {
          debugPrint('Error processing chat messages for $chatId: $e');
          controller.addError(e);
        }
      },
      onError: (error) {
        debugPrint('Error in chat stream for $chatId: $error');
        controller.addError(error);
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
        try {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>;
            final typingUsers = Map<String, bool>.from(data['typingUsers'] ?? {});
            controller.add(typingUsers);
          } else {
            controller.add({});
          }
        } catch (e) {
          debugPrint('Error processing typing indicators for $chatId: $e');
          controller.addError(e);
        }
      },
      onError: (error) {
        debugPrint('Error in typing stream for $chatId: $error');
        controller.addError(error);
      },
    );

    _typingSubscriptions[chatId] = subscription;
  }

  // Send message with enhanced validation
  Future<void> sendMessage({
    required String chatId,
    required String message,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      if (chatId.isEmpty) throw Exception('Chat ID is empty');
      if (message.trim().isEmpty) throw Exception('Message is empty');

      // Get user data for better message metadata
      final userData = await getUserData(user.uid);
      final senderName = userData?['displayName'] ?? 
                        userData?['email'] ?? 
                        user.displayName ?? 
                        user.email ?? 
                        'Unknown';

      final chatMessage = ChatMessage(
        id: '', // Will be set by Firestore
        senderId: user.uid,
        senderName: senderName,
        message: message.trim(),
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
      if (user == null || chatId.isEmpty) return;

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
      if (user == null || chatId.isEmpty) return;

      await _firestore.collection('chats').doc(chatId).update({
        'typingUsers.${user.uid}': FieldValue.delete(),
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

  // Update chat metadata with enhanced information
  Future<void> _updateChatMetadata(String chatId, ChatMessage lastMessage) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get participant names for better chat display
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      Map<String, String> participantNames = {};
      
      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        participantNames = Map<String, String>.from(data['participantNames'] ?? {});
      }

      // Update participant names if not set
      if (!participantNames.containsKey(user.uid)) {
        final userData = await getUserData(user.uid);
        participantNames[user.uid] = userData?['displayName'] ?? 
                                    userData?['email'] ?? 
                                    user.displayName ?? 
                                    user.email ?? 
                                    'User';
      }

      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': lastMessage.message,
        'lastMessageTime': lastMessage.timestamp,
        'lastSenderId': lastMessage.senderId,
        'lastSenderName': lastMessage.senderName,
        'participantNames': participantNames,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating chat metadata: $e');
    }
  }

  // Create or get chat between users with enhanced metadata
  Future<String> createOrGetChat(String otherUserId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final chatId = _generateChatId(user.uid, otherUserId);

      // Get user data for better chat metadata
      final userData = await getUserData(user.uid);
      final otherUserData = await getUserData(otherUserId);

      final userName = userData?['displayName'] ?? 
                      userData?['email'] ?? 
                      user.displayName ?? 
                      user.email ?? 
                      'User';
      
      final otherUserName = otherUserData?['displayName'] ?? 
                           otherUserData?['email'] ?? 
                           'Other User';

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        // Create new chat with enhanced metadata
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [user.uid, otherUserId],
          'participantNames': {
            user.uid: userName,
            otherUserId: otherUserName,
          },
          'chatType': 'user_to_user',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'typingUsers': {},
          'metadata': {
            'participantNames': {
              user.uid: userName,
              otherUserId: otherUserName,
            },
            'chatType': 'user_to_user',
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          },
        });
      } else {
        // Update participant names if needed
        await _firestore.collection('chats').doc(chatId).update({
          'participantNames': {
            user.uid: userName,
            otherUserId: otherUserName,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return chatId;
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      rethrow;
    }
  }

  // Create chat with supplier with enhanced metadata
  Future<String> createChatWithSupplier(String supplierId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final chatId = _generateChatId(user.uid, supplierId);
      debugPrint('Generated chat ID: $chatId for user: ${user.uid} and supplier: $supplierId');

      // Get supplier details
      final supplierDoc = await _firestore.collection('users').doc(supplierId).get();
      final supplierData = supplierDoc.data();
      final supplierName = supplierData?['displayName'] ?? 
                          supplierData?['businessName'] ?? 
                          supplierData?['email'] ?? 
                          'Supplier';
      debugPrint('Supplier name resolved: $supplierName');

      // Get user details
      final userData = await getUserData(user.uid);
      final userName = userData?['displayName'] ?? 
                      userData?['email'] ?? 
                      user.displayName ?? 
                      user.email ?? 
                      'User';

      // Check if chat exists
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      
      if (!chatDoc.exists) {
        debugPrint('Creating new chat: $chatId');
        // Create new chat with proper metadata
        await _firestore.collection('chats').doc(chatId).set({
          'participants': [user.uid, supplierId],
          'participantNames': {
            user.uid: userName,
            supplierId: supplierName,
          },
          'chatType': 'supplier_buyer',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessage': '', // Initialize empty to ensure chat appears in list
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': user.uid,
          'lastSenderName': userName,
          'typingUsers': {},
          'metadata': {
            'participantNames': {
              user.uid: userName,
              supplierId: supplierName,
            },
            'chatType': 'supplier_buyer',
            'createdBy': user.uid,
            'createdAt': FieldValue.serverTimestamp(),
          },
        });
        debugPrint('New chat created successfully: $chatId');
      } else {
        debugPrint('Chat already exists: $chatId');
        // Update the chat metadata to ensure it's properly indexed
        await _firestore.collection('chats').doc(chatId).update({
          'updatedAt': FieldValue.serverTimestamp(),
          'participantNames': {
            user.uid: userName,
            supplierId: supplierName,
          },
        });
        debugPrint('Chat metadata updated successfully: $chatId');
      }

      debugPrint('Returning chat ID: $chatId');
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

  // Get user chats with enhanced filtering and metadata
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
              final deletedChats = _deletedChats[user.uid] ?? {};
              return snapshot.docs
                  .map((doc) => ChatSummary.fromFirestore(doc))
                  .where((chat) => 
                      chat.participants.isNotEmpty && 
                      chat.participants.length >= 2 &&
                      !deletedChats.contains(chat.id)) // Filter out deleted chats
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

  // Get supplier chats with enhanced filtering
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
              final deletedChats = _deletedChats[user.uid] ?? {};
              return snapshot.docs
                  .map((doc) => ChatSummary.fromFirestore(doc))
                  .where((chat) => 
                      chat.participants.isNotEmpty && 
                      chat.participants.length >= 2 &&
                      !deletedChats.contains(chat.id) &&
                      chat.lastMessage != null && // Only show chats with messages
                      chat.lastMessage!.isNotEmpty)
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

  // Get customer-supplier chats with enhanced metadata
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
              final deletedChats = _deletedChats[user.uid] ?? {};
              final chats = snapshot.docs
                  .map((doc) => ChatSummary.fromFirestore(doc))
                  .where((chat) => 
                      chat.participants.isNotEmpty && 
                      chat.participants.length >= 2 &&
                      !deletedChats.contains(chat.id) &&
                      chat.participants.contains(user.uid)) // Ensure user is actually a participant
                  .toList();
              
              debugPrint('Found ${chats.length} chats for user: ${user.uid}');
              return chats;
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

  // Get chat participants with names
  Future<Map<String, String>> getChatParticipants(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>;
        final participantNames = data['participantNames'] as Map<String, dynamic>?;
        if (participantNames != null) {
          return Map<String, String>.from(participantNames);
        }
      }
      return {};
    } catch (e) {
      debugPrint('Error getting chat participants: $e');
      return {};
    }
  }

  // Get chat title for display
  Future<String> getChatTitle(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Chat';

      final participants = await getChatParticipants(chatId);
      final otherParticipantId = participants.keys
          .firstWhere((id) => id != user.uid, orElse: () => '');

      if (otherParticipantId.isNotEmpty) {
        return participants[otherParticipantId] ?? 'User';
      }

      return 'Chat';
    } catch (e) {
      debugPrint('Error getting chat title: $e');
      return 'Chat';
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
                    'profileImage': doc.data()['profileImage'] ?? '',
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

  // Delete chat for current user (but keep for other participants)
  Future<void> deleteChat(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Add to deleted chats for this user
      if (!_deletedChats.containsKey(user.uid)) {
        _deletedChats[user.uid] = {};
      }
      _deletedChats[user.uid]!.add(chatId);
      
      // Save deleted chats
      await _saveDeletedChats(user.uid);
      
      debugPrint('Chat $chatId deleted for user ${user.uid}');
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      rethrow;
    }
  }

  // Mark messages as read with enhanced tracking
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update messages in Firestore
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: user.uid)
          .where('readBy', arrayContains: user.uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesQuery.docs) {
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

  // Delete entire conversation
  Future<void> deleteConversation(String chatId) async {
    try {
      // Delete all messages in the conversation
      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();
      
      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the chat document itself
      batch.delete(_firestore.collection('chats').doc(chatId));
      
      await batch.commit();
      
      // Clear cache and streams
      _chatCache.remove(chatId);
      _chatControllers[chatId]?.close();
      _chatControllers.remove(chatId);
      _chatSubscriptions[chatId]?.cancel();
      _chatSubscriptions.remove(chatId);
      
      debugPrint('Conversation deleted successfully: $chatId');
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
      rethrow;
    }
  }

  // Get unread message count with enhanced tracking
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
    for (final controller in _chatControllers.values) {
      controller.close();
    }
    for (final controller in _typingControllers.values) {
      controller.close();
    }
    for (final subscription in _chatSubscriptions.values) {
      subscription.cancel();
    }
    for (final subscription in _typingSubscriptions.values) {
      subscription.cancel();
    }
    
    _chatControllers.clear();
    _typingControllers.clear();
    _chatSubscriptions.clear();
    _typingSubscriptions.clear();
    _chatCache.clear();
    _userCache.clear();
  }

  // Dispose resources
  void dispose() {
    _clearAllChats();
  }

  // Get chat messages
  Stream<List<ChatMessage>> getChatMessages(String chatId) {
    return getChatStream(chatId);
  }

  // Get typing indicator
  Stream<Map<String, bool>> getTypingIndicator(String chatId) {
    return getTypingStream(chatId);
  }

  // Set typing indicator
  Future<void> setTypingIndicator(String chatId, bool isTyping) async {
    if (isTyping) {
      await startTyping(chatId);
    } else {
      await stopTyping(chatId);
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
      
      // Validate required fields
      final senderId = data['senderId']?.toString() ?? '';
      final senderName = data['senderName']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';
      
      // If any required field is empty, return a safe default
      if (senderId.isEmpty || senderName.isEmpty || message.isEmpty) {
        debugPrint('ChatMessage.fromFirestore: Missing required fields for ${doc.id}');
        return ChatMessage(
          id: doc.id,
          senderId: senderId.isEmpty ? 'unknown' : senderId,
          senderName: senderName.isEmpty ? 'Unknown User' : senderName,
          message: message.isEmpty ? 'Empty message' : message,
          timestamp: DateTime.now(),
          metadata: {},
          status: MessageStatus.failed,
        );
      }
      
      return ChatMessage(
        id: doc.id,
        senderId: senderId,
        senderName: senderName,
        message: message,
        imageUrl: data['imageUrl']?.toString(),
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
        senderId: 'unknown',
        senderName: 'Unknown User',
        message: 'Error loading message',
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
      
      // Validate participants array
      final participants = data['participants'];
      List<String> participantList = [];
      if (participants != null && participants is List) {
        participantList = participants
            .where((p) => p != null && p.toString().isNotEmpty)
            .map((p) => p.toString())
            .toList();
      }
      
      // If no valid participants, return safe default
      if (participantList.isEmpty) {
        debugPrint('ChatSummary.fromFirestore: No valid participants for ${doc.id}');
        return ChatSummary(
          id: doc.id,
          participants: [],
        );
      }
      
      return ChatSummary(
        id: doc.id,
        participants: participantList,
        lastMessage: data['lastMessage']?.toString(),
        lastMessageTime: data['lastMessageTime'] != null 
            ? (data['lastMessageTime'] is Timestamp 
                ? (data['lastMessageTime'] as Timestamp).toDate() 
                : DateTime.tryParse(data['lastMessageTime'].toString()) ?? DateTime.now())
            : null,
        lastSenderId: data['lastSenderId']?.toString(),
        lastSenderName: data['lastSenderName']?.toString(),
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