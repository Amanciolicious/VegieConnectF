import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatService {
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  String buildConversationId({required String buyerId, required String supplierId}) {
    // Deterministic conversation id
    return 'buyer_${buyerId}_supplier_$supplierId';
  }

  Future<String> getOrCreateConversation({
    required String buyerId,
    required String supplierId,
    String? buyerName,
    String? supplierName,
  }) async {
    try {
      final conversationId = buildConversationId(buyerId: buyerId, supplierId: supplierId);
      final docRef = _firestore.collection('conversations').doc(conversationId);
      
      // Check connectivity before attempting Firestore operation
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        developer.log('No internet connection, using cached conversation ID');
        return conversationId;
      }
      
      final doc = await docRef.get();
      if (!doc.exists) {
        // Only buyers can initiate conversations
        await docRef.set({
          'conversationId': conversationId,
          'buyerId': buyerId,
          'supplierId': supplierId,
          'buyerName': buyerName ?? 'Unknown Customer',
          'supplierName': supplierName ?? 'Supplier',
          'initiatedBy': buyerId,
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'hiddenFor': <String>[],
          'isActive': true,
        });
        developer.log('Created new conversation: $conversationId');
      }
      return conversationId;
    } catch (e) {
      developer.log('Error creating conversation: $e');
      throw Exception('Failed to create conversation: $e');
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        )
        .snapshots()
        .handleError((error) {
          developer.log('Error streaming messages: $error');
          return const Stream.empty();
        });
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final batch = _firestore.batch();
      
      // Delete all messages in the conversation
      final messagesQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();
      
      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the conversation document
      batch.delete(_firestore.collection('conversations').doc(conversationId));
      
      await batch.commit();
      developer.log('Deleted conversation: $conversationId');
    } catch (e) {
      developer.log('Error deleting conversation: $e');
      throw Exception('Failed to delete conversation: $e');
    }
  }

  Future<void> hideConversation(String conversationId, String userId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'hiddenFor': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log('Hidden conversation $conversationId for user $userId');
    } catch (e) {
      developer.log('Error hiding conversation: $e');
      throw Exception('Failed to hide conversation: $e');
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) return;
    
    final message = {
      'senderId': senderId,
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };
    
    // Always save locally first for immediate UI feedback
    await appendLocalMessage(conversationId: conversationId, message: {
      'senderId': senderId,
      'text': text.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    try {
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        developer.log('No internet connection, message saved locally');
        await _queueOfflineMessage(conversationId, message);
        return;
      }
      
      final convRef = _firestore.collection('conversations').doc(conversationId);
      await convRef.collection('messages').add(message);
      await convRef.update({
        'lastMessage': text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      developer.log('Message sent successfully');
    } catch (e) {
      developer.log('Error sending message: $e');
      // Queue message for retry when connection is restored
      await _queueOfflineMessage(conversationId, message);
    }
  }
  
  Future<void> _queueOfflineMessage(String conversationId, Map<String, dynamic> message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueKey = 'offline_messages_$conversationId';
      final existing = prefs.getString(queueKey);
      List<dynamic> queue = [];
      if (existing != null) {
        queue = jsonDecode(existing) as List<dynamic>;
      }
      queue.add(message);
      await prefs.setString(queueKey, jsonEncode(queue));
      developer.log('Message queued for offline sending');
    } catch (e) {
      developer.log('Error queuing offline message: $e');
    }
  }
  
  Future<void> syncOfflineMessages(String conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueKey = 'offline_messages_$conversationId';
      final existing = prefs.getString(queueKey);
      if (existing == null) return;
      
      final queue = jsonDecode(existing) as List<dynamic>;
      if (queue.isEmpty) return;
      
      final convRef = _firestore.collection('conversations').doc(conversationId);
      for (final message in queue) {
        await convRef.collection('messages').add(message);
      }
      
      // Clear the queue after successful sync
      await prefs.remove(queueKey);
      developer.log('Synced ${queue.length} offline messages');
    } catch (e) {
      developer.log('Error syncing offline messages: $e');
    }
  }

  Future<void> appendLocalMessage({
    required String conversationId,
    required Map<String, dynamic> message,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _localKey(conversationId);
    final existing = prefs.getString(key);
    List<dynamic> messages = [];
    if (existing != null) {
      try {
        messages = jsonDecode(existing) as List<dynamic>;
      } catch (_) {}
    }
    messages.add(message);
    await prefs.setString(key, jsonEncode(messages));
  }

  Future<List<Map<String, dynamic>>> loadLocalMessages(String conversationId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _localKey(conversationId);
    final existing = prefs.getString(key);
    if (existing == null) return [];
    try {
      final decoded = jsonDecode(existing) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  String _localKey(String conversationId) => 'chat_messages_$conversationId';

  Future<void> setLocalMessages({
    required String conversationId,
    required List<Map<String, dynamic>> messages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey(conversationId), jsonEncode(messages));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamSupplierConversations(String supplierId) {
    return _firestore
        .collection('conversations')
        .where('supplierId', isEqualTo: supplierId)
        .orderBy('updatedAt', descending: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        )
        .snapshots()
        .handleError((error) {
          developer.log('Error streaming supplier conversations: $error');
          return const Stream.empty();
        });
  }

  Future<void> hideConversationForSupplier({required String conversationId, required String supplierId}) async {
    try {
      final ref = _firestore.collection('conversations').doc(conversationId);
      await ref.update({
        'hiddenFor': FieldValue.arrayUnion([supplierId]),
      });
      developer.log('Conversation hidden for supplier: $supplierId');
    } catch (e) {
      developer.log('Error hiding conversation: $e');
    }
  }

  Future<void> ensureBuyerOnlyInitiation({required String supplierId}) async {
    // Guard at UI level; this is a placeholder for possible server rules.
  }
  
  // Add method to get buyer conversations
  Stream<QuerySnapshot<Map<String, dynamic>>> streamBuyerConversations(String buyerId) {
    return _firestore
        .collection('conversations')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('updatedAt', descending: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        )
        .snapshots()
        .handleError((error) {
          developer.log('Error streaming buyer conversations: $error');
          return const Stream.empty();
        });
  }

  // Add method to hide conversation for buyer
  Future<void> hideConversationForBuyer({required String conversationId, required String buyerId}) async {
    try {
      final ref = _firestore.collection('conversations').doc(conversationId);
      await ref.update({
        'hiddenFor': FieldValue.arrayUnion([buyerId]),
      });
      developer.log('Conversation hidden for buyer: $buyerId');
    } catch (e) {
      developer.log('Error hiding conversation for buyer: $e');
    }
  }
  
  // Method to check and sync offline messages when connection is restored
  Future<void> checkAndSyncOfflineMessages() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) return;
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('offline_messages_'));
      
      for (final key in keys) {
        final conversationId = key.replaceFirst('offline_messages_', '');
        await syncOfflineMessages(conversationId);
      }
    } catch (e) {
      developer.log('Error checking offline messages: $e');
    }
  }
}


