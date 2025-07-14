import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  User? get user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get _cartRef =>
      FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('cart');

  Future<void> _updateQuantity(String docId, int newQty) async {
    if (newQty > 0) {
      await _cartRef.doc(docId).update({'quantity': newQty});
    } else {
      await _cartRef.doc(docId).delete();
    }
  }

  Future<void> _removeItem(String docId) async {
    await _cartRef.doc(docId).delete();
  }

  double _calculateTotal(List<QueryDocumentSnapshot<Map<String, dynamic>>> items) {
    double total = 0;
    for (final doc in items) {
      final data = doc.data();
      total += (data['price'] ?? 0) * (data['quantity'] ?? 1);
    }
    return total;
  }

  bool _isProcessing = false;

  Future<void> _checkout(List<QueryDocumentSnapshot<Map<String, dynamic>>> cartItems) async {
    if (cartItems.isEmpty || _isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final ordersRef = FirebaseFirestore.instance.collection('orders');
      for (final doc in cartItems) {
        final data = doc.data();
        batch.set(ordersRef.doc(), {
          'buyerId': user!.uid,
          'productId': data['productId'],
          'sellerId': data['sellerId'],
          'productName': data['name'],
          'quantity': data['quantity'],
          'unit': data['unit'],
          'price': data['price'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.delete(_cartRef.doc(doc.id));
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed for all cart items!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Cart'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _cartRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cartItems = snapshot.data?.docs ?? [];
          if (cartItems.isEmpty) {
            return const Center(
              child: Text('Your cart is empty.', style: TextStyle(color: Colors.black54, fontSize: 18)),
            );
          }
          final total = _calculateTotal(cartItems);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, i) {
                    final item = cartItems[i].data();
                    return ListTile(
                      leading: Icon(Icons.eco, color: green),
                      title: Text(item['name'] ?? ''),
                      subtitle: Text('₱${item['price']} x ${item['quantity']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () => _updateQuantity(cartItems[i].id, (item['quantity'] ?? 1) - 1),
                          ),
                          Text('${item['quantity']}'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => _updateQuantity(cartItems[i].id, (item['quantity'] ?? 1) + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _removeItem(cartItems[i].id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isProcessing || cartItems.isEmpty
                            ? null
                            : () => _checkout(cartItems),
                        child: const Text('Checkout', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 