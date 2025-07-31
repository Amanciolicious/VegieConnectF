import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LocalMessagingService {
  static final LocalMessagingService _instance = LocalMessagingService._internal();
  factory LocalMessagingService() => _instance;
  LocalMessagingService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // In-memory storage for real-time messaging
  final Map<String, List<LocalMessage>> _messageCache = {};
  final Map<String, StreamController<List<LocalMessage>>> _chatControllers = {};
  final Map<String, StreamController<Map<String, bool>>> _typingControllers = {};
  
  // Chat summaries for UI
  final Map<String, LocalChatSummary> _chatSummaries = {};
  
  // Typing indicators
  final Map<String, Map<String, bool>> _typingUsers = {};
  
  // Initialize the service
  Future<void> initialize() async {
    try {
      // Load existing chats from local storage
      await _loadChatsFromStorage();
      
      // Listen for user authentication changes
      _auth.authStateChanges().listen((User? user) {
        if (user == null) {
          _clearAllChats();
        }
      });
      
      debugPrint('LocalMessagingService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LocalMessagingService: $e');
    }
  }

  // Initialize the service if not already initialized
  Future<void> _ensureInitialized() async {
    if (_chatSummaries.isEmpty) {
      await initialize();
    }
  }

  // Create or get existing chat with supplier
  Future<String> createChatWithSupplier(String supplierId) async {
    try {
      await _ensureInitialized();
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final chatId = _generateChatId(user.uid, supplierId);
      
      // Check if chat already exists
      if (!_chatSummaries.containsKey(chatId)) {
        // Create new chat summary
        _chatSummaries[chatId] = LocalChatSummary(
          id: chatId,
          participants: [user.uid, supplierId],
          participantNames: {
            user.uid: user.displayName ?? user.email ?? 'User',
            supplierId: 'Supplier', // You can fetch this from your user data
          },
          chatType: 'supplier_buyer',
          lastMessage: null,
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
        );
        
        // Initialize message cache
        _messageCache[chatId] = [];
        
        // Save to local storage
        await _saveChatsToStorage();
      }

      return chatId;
    } catch (e) {
      debugPrint('Error creating chat with supplier: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> sendMessage(String chatId, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final localMessage = LocalMessage(
        id: _generateMessageId(),
        chatId: chatId,
        senderId: user.uid,
        senderName: user.displayName ?? user.email ?? 'User',
        content: message,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Add to cache
      if (!_messageCache.containsKey(chatId)) {
        _messageCache[chatId] = [];
      }
      _messageCache[chatId]!.insert(0, localMessage);

      // Update chat summary
      if (_chatSummaries.containsKey(chatId)) {
        _chatSummaries[chatId]!.lastMessage = message;
        _chatSummaries[chatId]!.lastMessageTime = DateTime.now();
        _chatSummaries[chatId]!.unreadCount++;
      }

      // Notify listeners
      _notifyChatUpdate(chatId);
      
      // Save to local storage
      await _saveMessagesToStorage(chatId);
      await _saveChatsToStorage();

      debugPrint('Message sent: $message');
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Get chat stream
  Stream<List<LocalMessage>> getChatStream(String chatId) {
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

  // Get user chats
  Stream<List<LocalChatSummary>> getUserChats() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return Stream.periodic(const Duration(seconds: 1), (_) async {
      await _ensureInitialized();
      return _chatSummaries.values
          .where((chat) => chat.participants.contains(user.uid))
          .toList()
        ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    }).asyncMap((future) => future);
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      if (_messageCache.containsKey(chatId)) {
        final user = _auth.currentUser;
        if (user == null) return;

        for (var message in _messageCache[chatId]!) {
          if (message.senderId != user.uid && !message.isRead) {
            message.isRead = true;
          }
        }

        // Update chat summary
        if (_chatSummaries.containsKey(chatId)) {
          _chatSummaries[chatId]!.unreadCount = 0;
        }

        // Save to storage
        await _saveMessagesToStorage(chatId);
        await _saveChatsToStorage();
        
        // Notify listeners
        _notifyChatUpdate(chatId);
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Set typing indicator
  Future<void> setTypingIndicator(String chatId, bool isTyping) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (!_typingUsers.containsKey(chatId)) {
        _typingUsers[chatId] = {};
      }
      _typingUsers[chatId]![user.uid] = isTyping;

      // Notify typing listeners
      if (_typingControllers.containsKey(chatId)) {
        _typingControllers[chatId]!.add(_typingUsers[chatId]!);
      }
    } catch (e) {
      debugPrint('Error setting typing indicator: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      if (_messageCache.containsKey(chatId)) {
        _messageCache[chatId]!.removeWhere((message) => message.id == messageId);
        
        // Update chat summary if needed
        if (_chatSummaries.containsKey(chatId) && _messageCache[chatId]!.isNotEmpty) {
          final lastMessage = _messageCache[chatId]!.first;
          _chatSummaries[chatId]!.lastMessage = lastMessage.content;
          _chatSummaries[chatId]!.lastMessageTime = lastMessage.timestamp;
        } else if (_chatSummaries.containsKey(chatId)) {
          _chatSummaries[chatId]!.lastMessage = null;
          _chatSummaries[chatId]!.lastMessageTime = DateTime.now();
        }

        // Notify listeners
        _notifyChatUpdate(chatId);
        
        // Save to storage
        await _saveMessagesToStorage(chatId);
        await _saveChatsToStorage();
      }
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Clear all messages in a chat
  Future<void> clearChat(String chatId) async {
    try {
      if (_messageCache.containsKey(chatId)) {
        _messageCache[chatId]!.clear();
        
        // Update chat summary
        if (_chatSummaries.containsKey(chatId)) {
          _chatSummaries[chatId]!.lastMessage = null;
          _chatSummaries[chatId]!.lastMessageTime = DateTime.now();
          _chatSummaries[chatId]!.unreadCount = 0;
        }

        // Notify listeners
        _notifyChatUpdate(chatId);
        
        // Save to storage
        await _saveMessagesToStorage(chatId);
        await _saveChatsToStorage();
      }
    } catch (e) {
      debugPrint('Error clearing chat: $e');
      rethrow;
    }
  }

  // Initialize chat stream
  void _initializeChatStream(String chatId) {
    final controller = StreamController<List<LocalMessage>>.broadcast();
    _chatControllers[chatId] = controller;

    // Load cached messages
    if (_messageCache.containsKey(chatId)) {
      controller.add(_messageCache[chatId]!);
    }
  }

  // Initialize typing stream
  void _initializeTypingStream(String chatId) {
    final controller = StreamController<Map<String, bool>>.broadcast();
    _typingControllers[chatId] = controller;

    if (_typingUsers.containsKey(chatId)) {
      controller.add(_typingUsers[chatId]!);
    }
  }

  // Notify chat update
  void _notifyChatUpdate(String chatId) {
    if (_chatControllers.containsKey(chatId)) {
      _chatControllers[chatId]!.add(_messageCache[chatId] ?? []);
    }
  }

  // Generate chat ID
  String _generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Generate message ID
  String _generateMessageId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Load chats from storage
  Future<void> _loadChatsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = prefs.getString('local_chats');
      
      if (chatsJson != null) {
        final List<dynamic> chatsList = json.decode(chatsJson);
        for (var chatJson in chatsList) {
          final chat = LocalChatSummary.fromJson(chatJson);
          _chatSummaries[chat.id] = chat;
        }
      }
    } catch (e) {
      debugPrint('Error loading chats from storage: $e');
    }
  }

  // Save chats to storage
  Future<void> _saveChatsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsList = _chatSummaries.values.map((chat) => chat.toJson()).toList();
      await prefs.setString('local_chats', json.encode(chatsList));
    } catch (e) {
      debugPrint('Error saving chats to storage: $e');
    }
  }

  // Load messages from storage
  Future<void> _loadMessagesFromStorage(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('local_messages_$chatId');
      
      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        _messageCache[chatId] = messagesList
            .map((msgJson) => LocalMessage.fromJson(msgJson))
            .toList();
      }
    } catch (e) {
      debugPrint('Error loading messages from storage: $e');
    }
  }

  // Save messages to storage
  Future<void> _saveMessagesToStorage(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_messageCache.containsKey(chatId)) {
        final messagesList = _messageCache[chatId]!.map((msg) => msg.toJson()).toList();
        await prefs.setString('local_messages_$chatId', json.encode(messagesList));
      }
    } catch (e) {
      debugPrint('Error saving messages to storage: $e');
    }
  }

  // Clear all chats (when user logs out)
  void _clearAllChats() {
    _messageCache.clear();
    _chatSummaries.clear();
    _typingUsers.clear();
    
    for (var controller in _chatControllers.values) {
      controller.close();
    }
    _chatControllers.clear();
    
    for (var controller in _typingControllers.values) {
      controller.close();
    }
    _typingControllers.clear();
  }

  // Dispose resources
  void dispose() {
    _clearAllChats();
  }
}

// Data Models
class LocalMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime timestamp;
  bool isRead;

  LocalMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory LocalMessage.fromJson(Map<String, dynamic> json) {
    return LocalMessage(
      id: json['id'],
      chatId: json['chatId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }
}

class LocalChatSummary {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String chatType;
  String? lastMessage;
  DateTime lastMessageTime;
  int unreadCount;

  LocalChatSummary({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.chatType,
    this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'chatType': chatType,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
    };
  }

  factory LocalChatSummary.fromJson(Map<String, dynamic> json) {
    return LocalChatSummary(
      id: json['id'],
      participants: List<String>.from(json['participants']),
      participantNames: Map<String, String>.from(json['participantNames']),
      chatType: json['chatType'],
      lastMessage: json['lastMessage'],
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
} 