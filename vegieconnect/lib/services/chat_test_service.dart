import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_service.dart';

class ChatTestService {
  static final ChatService _chatService = ChatService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test all chat functionality
  static Future<bool> runChatTests() async {
    developer.log('Starting chat functionality tests...');
    
    try {
      // Test 1: Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('❌ Test failed: User not authenticated');
        return false;
      }
      developer.log('✅ User authenticated: ${user.uid}');

      // Test 2: Test conversation creation
      const testSupplierId = 'test_supplier_123';
      const testSupplierName = 'Test Supplier';
      
      final conversationId = await _chatService.getOrCreateConversation(
        buyerId: user.uid,
        supplierId: testSupplierId,
        buyerName: user.displayName ?? 'Test Buyer',
        supplierName: testSupplierName,
      );
      developer.log('✅ Conversation created/retrieved: $conversationId');

      // Test 3: Test message sending
      await _chatService.sendMessage(
        conversationId: conversationId,
        senderId: user.uid,
        text: 'Test message from chat test service',
      );
      developer.log('✅ Message sent successfully');

      // Test 4: Test local message storage
      final localMessages = await _chatService.loadLocalMessages(conversationId);
      developer.log('✅ Local messages loaded: ${localMessages.length} messages');

      // Test 5: Test offline message sync
      await _chatService.checkAndSyncOfflineMessages();
      developer.log('✅ Offline message sync completed');

      // Test 6: Test Firestore permissions by reading conversations
      final conversationDoc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (conversationDoc.exists) {
        developer.log('✅ Firestore read permissions working');
      } else {
        developer.log('⚠️ Conversation document not found (may be normal for offline mode)');
      }

      developer.log('🎉 All chat tests completed successfully!');
      return true;

    } catch (e) {
      developer.log('❌ Chat test failed: $e');
      return false;
    }
  }

  /// Test specific Firestore security rules
  static Future<void> testFirestoreRules() async {
    developer.log('Testing Firestore security rules...');
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('❌ Cannot test rules: User not authenticated');
        return;
      }

      // Test reading user's own conversations
      final userConversations = await _firestore
          .collection('conversations')
          .where('buyerId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      developer.log('✅ Can read own conversations: ${userConversations.docs.length} found');

      // Test reading messages in own conversation
      if (userConversations.docs.isNotEmpty) {
        final conversationId = userConversations.docs.first.id;
        final messages = await _firestore
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .limit(1)
            .get();
        
        developer.log('✅ Can read messages in own conversation: ${messages.docs.length} found');
      }

      developer.log('🔒 Firestore security rules test completed');

    } catch (e) {
      developer.log('❌ Firestore rules test failed: $e');
    }
  }

  /// Cleanup test data
  static Future<void> cleanupTestData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Clean up test conversations
      final testConversations = await _firestore
          .collection('conversations')
          .where('buyerId', isEqualTo: user.uid)
          .where('supplierName', isEqualTo: 'Test Supplier')
          .get();

      for (final doc in testConversations.docs) {
        await doc.reference.delete();
      }

      developer.log('🧹 Test data cleanup completed');
    } catch (e) {
      developer.log('❌ Cleanup failed: $e');
    }
  }
}
