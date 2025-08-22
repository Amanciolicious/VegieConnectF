import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

/// Service to trigger automatic Firestore composite index creation
/// Run these queries in your app to see the required indexes in Firebase Console
class FirestoreIndexTrigger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Trigger all composite index requirements
  static Future<void> triggerAllIndexes() async {
    developer.log('🔥 Triggering Firestore composite index creation...');
    
    try {
      await _triggerConversationIndexes();
      await _triggerChatIndexes();
      await _triggerProductIndexes();
      await _triggerOrderIndexes();
      await _triggerMessageIndexes();
      
      developer.log('✅ All index triggers completed. Check Firebase Console for required indexes.');
    } catch (e) {
      developer.log('❌ Error triggering indexes: $e');
    }
  }

  /// Trigger conversation-related indexes
  static Future<void> _triggerConversationIndexes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Index: conversations - buyerId (ASC) + updatedAt (DESC)
      await _firestore
          .collection('conversations')
          .where('buyerId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      // Index: conversations - supplierId (ASC) + updatedAt (DESC)
      await _firestore
          .collection('conversations')
          .where('supplierId', isEqualTo: user.uid)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      // Index: conversations - hiddenFor (ARRAY_CONTAINS) + updatedAt (DESC)
      await _firestore
          .collection('conversations')
          .where('hiddenFor', arrayContains: user.uid)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      developer.log('📝 Conversation indexes triggered');
    } catch (e) {
      developer.log('Conversation index trigger: $e');
    }
  }

  /// Trigger message-related indexes
  static Future<void> _triggerMessageIndexes() async {
    try {
      // Index: messages - timestamp (ASC) - for subcollection queries
      await _firestore
          .collectionGroup('messages')
          .orderBy('timestamp', descending: false)
          .limit(1)
          .get();

      // Index: messages - timestamp (DESC) - for subcollection queries
      await _firestore
          .collectionGroup('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // Index: messages - senderId (ASC) + timestamp (DESC)
      await _firestore
          .collectionGroup('messages')
          .where('senderId', isEqualTo: 'dummy')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      developer.log('💬 Message indexes triggered');
    } catch (e) {
      developer.log('Message index trigger: $e');
    }
  }

  /// Trigger chat-related indexes (legacy)
  static Future<void> _triggerChatIndexes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Index: chats - participants (ARRAY_CONTAINS) + updatedAt (DESC)
      await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      // Index: chats - participants (ARRAY_CONTAINS) + chatType (ASC) + updatedAt (DESC)
      await _firestore
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .where('chatType', isEqualTo: 'direct')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      developer.log('💭 Chat indexes triggered');
    } catch (e) {
      developer.log('Chat index trigger: $e');
    }
  }

  /// Trigger product-related indexes
  static Future<void> _triggerProductIndexes() async {
    try {
      // Index: products - isActive (ASC) + isVerified (ASC) + popularity (DESC)
      await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .orderBy('popularity', descending: true)
          .limit(1)
          .get();

      // Index: products - sellerId (ASC) + createdAt (DESC)
      await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: 'dummy')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      // Index: products - category (ASC) + isActive (ASC) + popularity (DESC)
      await _firestore
          .collection('products')
          .where('category', isEqualTo: 'vegetables')
          .where('isActive', isEqualTo: true)
          .orderBy('popularity', descending: true)
          .limit(1)
          .get();

      // Index: products - sellerId (ASC) + isActive (ASC) + category (ASC)
      await _firestore
          .collection('products')
          .where('sellerId', isEqualTo: 'dummy')
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: 'vegetables')
          .limit(1)
          .get();

      developer.log('🥬 Product indexes triggered');
    } catch (e) {
      developer.log('Product index trigger: $e');
    }
  }

  /// Trigger order-related indexes
  static Future<void> _triggerOrderIndexes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Index: orders - buyerId (ASC) + createdAt (DESC)
      await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      // Index: orders - sellerId (ASC) + status (ASC) + createdAt (DESC)
      await _firestore
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      // Index: orders - buyerId (ASC) + status (ASC) + updatedAt (DESC)
      await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      developer.log('📦 Order indexes triggered');
    } catch (e) {
      developer.log('Order index trigger: $e');
    }
  }

  /// Trigger notification indexes
  static Future<void> _triggerNotificationIndexes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Index: notifications - userId (ASC) + isRead (ASC) + createdAt (DESC)
      await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      developer.log('🔔 Notification indexes triggered');
    } catch (e) {
      developer.log('Notification index trigger: $e');
    }
  }
}
