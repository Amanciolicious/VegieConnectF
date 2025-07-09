import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerProductsPage extends StatefulWidget {
  const BuyerProductsPage({super.key});

  @override
  State<BuyerProductsPage> createState() => _BuyerProductsPageState();
}

class _BuyerProductsPageState extends State<BuyerProductsPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Vegetable', 'Fruit', 'Other'];

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Browse Products'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Category: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val ?? 'All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _selectedCategory == 'All'
                    ? FirebaseFirestore.instance
                        .collection('products')
                        .where('isActive', isEqualTo: true)
                        .snapshots()
                    : FirebaseFirestore.instance
                        .collection('products')
                        .where('isActive', isEqualTo: true)
                        .where('category', isEqualTo: _selectedCategory)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }
                  final products = snapshot.data!.docs
                      .where((doc) {
                        final product = doc.data() as Map<String, dynamic>;
                        final name = (product['name'] ?? '').toString().trim();
                        final price = (product['price'] ?? 0);
                        final quantity = (product['quantity'] ?? 0);
                        return name.isNotEmpty && price > 0 && quantity > 0;
                      })
                      .toList();
                  if (products.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index].data() as Map<String, dynamic>;
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: (product['imageUrl'] != null && (product['imageUrl'] as String).isNotEmpty)
                                    ? Image.network(product['imageUrl'], width: 64, height: 64, fit: BoxFit.cover)
                                    : Icon(Icons.shopping_basket, size: 48, color: green),
                              ),
                              const SizedBox(height: 8),
                              Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('₱${product['price']?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFA7C957))),
                              const SizedBox(height: 4),
                              Text('Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              const Spacer(),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: green,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    minimumSize: const Size(36, 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You must be logged in to order.')),
                                      );
                                      return;
                                    }
                                    int quantity = 1;
                                    final maxQty = (product['quantity'] ?? 1) as int;
                                    final result = await showDialog<int>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Place Order'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('How many would you like to order?'),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove),
                                                    onPressed: quantity > 1
                                                        ? () {
                                                            quantity--;
                                                            (context as Element).markNeedsBuild();
                                                          }
                                                        : null,
                                                  ),
                                                  Text('$quantity', style: const TextStyle(fontSize: 18)),
                                                  IconButton(
                                                    icon: const Icon(Icons.add),
                                                    onPressed: quantity < maxQty
                                                        ? () {
                                                            quantity++;
                                                            (context as Element).markNeedsBuild();
                                                          }
                                                        : null,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, quantity),
                                              child: const Text('Order'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (result != null) {
                                      await FirebaseFirestore.instance.collection('orders').add({
                                        'buyerId': user.uid,
                                        'productId': products[index].id,
                                        'sellerId': product['sellerId'],
                                        'productName': product['name'],
                                        'quantity': result,
                                        'unit': product['unit'],
                                        'price': product['price'],
                                        'status': 'pending',
                                        'createdAt': FieldValue.serverTimestamp(),
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Order placed!')),
                                      );
                                    }
                                  },
                                  child: const Icon(Icons.add_shopping_cart, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 