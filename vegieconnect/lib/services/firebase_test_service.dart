import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseTestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Test Firebase connection and permissions
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Check if user is authenticated
      final user = _auth.currentUser;
      results['user_authenticated'] = user != null;
      results['user_id'] = user?.uid;
      results['user_email'] = user?.email;
      
      if (user == null) {
        results['error'] = 'User not authenticated';
        return results;
      }

      // Test 2: Test reading user document
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        results['user_document_exists'] = userDoc.exists;
        results['user_data'] = userDoc.data();
      } catch (e) {
        results['user_document_error'] = e.toString();
      }

      // Test 3: Test reading products collection
      try {
        final productsQuery = await _firestore.collection('products').limit(1).get();
        results['products_readable'] = true;
        results['products_count'] = productsQuery.docs.length;
      } catch (e) {
        results['products_read_error'] = e.toString();
      }

      // Test 4: Test writing to user's cart collection
      try {
        final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');
        final testDoc = await cartRef.add({
          'test': true,
          'timestamp': FieldValue.serverTimestamp(),
        });
        results['cart_writable'] = true;
        results['test_doc_id'] = testDoc.id;
        
        // Clean up test document
        await testDoc.delete();
        results['test_cleanup_successful'] = true;
      } catch (e) {
        results['cart_write_error'] = e.toString();
      }

      // Test 5: Test updating user document
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastTested': FieldValue.serverTimestamp(),
        });
        results['user_update_successful'] = true;
      } catch (e) {
        results['user_update_error'] = e.toString();
      }

    } catch (e) {
      results['general_error'] = e.toString();
    }

    debugPrint('Firebase Test Results: $results');
    return results;
  }

  // Test specific cart operations
  static Future<Map<String, dynamic>> testCartOperations() async {
    final results = <String, dynamic>{};
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        results['error'] = 'User not authenticated';
        return results;
      }

      final cartRef = _firestore.collection('users').doc(user.uid).collection('cart');

      // Test adding item to cart
      try {
        final testItem = {
          'productId': 'test_product_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Test Product',
          'price': 10.0,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        };

        final docRef = await cartRef.add(testItem);
        results['add_to_cart_successful'] = true;
        results['test_doc_id'] = docRef.id;

        // Test reading cart items
        final cartItems = await cartRef.get();
        results['cart_read_successful'] = true;
        results['cart_items_count'] = cartItems.docs.length;

        // Test updating cart item
        await cartRef.doc(docRef.id).update({
          'quantity': 2,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        results['update_cart_successful'] = true;

        // Test deleting cart item
        await cartRef.doc(docRef.id).delete();
        results['delete_cart_successful'] = true;

      } catch (e) {
        results['cart_operation_error'] = e.toString();
      }

    } catch (e) {
      results['general_error'] = e.toString();
    }

    debugPrint('Cart Test Results: $results');
    return results;
  }

  // Get Firebase security rules status
  static Future<Map<String, dynamic>> getSecurityRulesStatus() async {
    final results = <String, dynamic>{};
    
    try {
      final user = _auth.currentUser;
      results['user_authenticated'] = user != null;
      
      if (user != null) {
        // Test different collections to see which ones are accessible
        final collections = ['users', 'products', 'chats'];
        
        for (final collection in collections) {
          try {
            final query = await _firestore.collection(collection).limit(1).get();
            results['${collection}_readable'] = true;
            results['${collection}_count'] = query.docs.length;
          } catch (e) {
            results['${collection}_read_error'] = e.toString();
          }
        }
      }
    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }
} 