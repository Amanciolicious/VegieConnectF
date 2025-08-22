import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class ChatDebugService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug customer-supplier chat connection
  static Future<void> debugChatConnection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log('❌ No authenticated user');
      return;
    }

    developer.log('🔍 Debugging chat connection for user: ${user.uid}');

    try {
      // Check if user has conversations as buyer
      final buyerConversations = await _firestore
          .collection('conversations')
          .where('buyerId', isEqualTo: user.uid)
          .get();
      
      developer.log('📝 Found ${buyerConversations.docs.length} conversations as buyer');
      
      // Check if user has conversations as supplier
      final supplierConversations = await _firestore
          .collection('conversations')
          .where('supplierId', isEqualTo: user.uid)
          .get();
      
      developer.log('🏪 Found ${supplierConversations.docs.length} conversations as supplier');

      // List all conversations for debugging
      for (final doc in buyerConversations.docs) {
        final data = doc.data();
        developer.log('Buyer conversation: ${doc.id}');
        developer.log('  - Supplier: ${data['supplierName']} (${data['supplierId']})');
        developer.log('  - Last message: ${data['lastMessage']}');
        developer.log('  - Updated: ${data['updatedAt']}');
      }

      for (final doc in supplierConversations.docs) {
        final data = doc.data();
        developer.log('Supplier conversation: ${doc.id}');
        developer.log('  - Buyer: ${data['buyerName']} (${data['buyerId']})');
        developer.log('  - Last message: ${data['lastMessage']}');
        developer.log('  - Updated: ${data['updatedAt']}');
        developer.log('  - Hidden for: ${data['hiddenFor']}');
      }

      // Test creating a conversation
      await _testConversationCreation();

    } catch (e) {
      developer.log('❌ Error debugging chat: $e');
    }
  }

  static Future<void> _testConversationCreation() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create a test conversation
      const testSupplierId = 'test_supplier_debug';
      const testSupplierName = 'Debug Supplier';
      
      final conversationId = 'buyer_${user.uid}_supplier_$testSupplierId';
      
      await _firestore.collection('conversations').doc(conversationId).set({
        'conversationId': conversationId,
        'buyerId': user.uid,
        'supplierId': testSupplierId,
        'buyerName': user.displayName ?? 'Test Buyer',
        'supplierName': testSupplierName,
        'initiatedBy': user.uid,
        'lastMessage': 'Debug test message',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'hiddenFor': <String>[],
      });

      developer.log('✅ Test conversation created: $conversationId');

      // Add a test message
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'text': 'Debug test message from customer',
        'timestamp': FieldValue.serverTimestamp(),
      });

      developer.log('✅ Test message added');

    } catch (e) {
      developer.log('❌ Error creating test conversation: $e');
    }
  }

  /// Clean up test data
  static Future<void> cleanupTestData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final testConversations = await _firestore
          .collection('conversations')
          .where('supplierName', isEqualTo: 'Debug Supplier')
          .get();

      for (final doc in testConversations.docs) {
        await doc.reference.delete();
      }

      developer.log('🧹 Test data cleaned up');
    } catch (e) {
      developer.log('❌ Error cleaning up: $e');
    }
  }
}
