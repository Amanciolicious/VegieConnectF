// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/product_image_widget.dart';
import 'product_details_page.dart';

class BuyerProductsPage extends StatefulWidget {
  final String? supplierId;
  const BuyerProductsPage({super.key, this.supplierId});

  static Route routeForSupplier(String supplierId) =>
      MaterialPageRoute(builder: (_) => BuyerProductsPage(supplierId: supplierId));

  @override
  State<BuyerProductsPage> createState() => _BuyerProductsPageState();
}

class _BuyerProductsPageState extends State<BuyerProductsPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Vegetable', 'Fruit', 'Other'];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final green = const Color(0xFFA7C957);
    final bg = const Color(0xFFF6F6F6);
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    final neumorphicShadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: Offset(screenWidth * 0.015, screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
      BoxShadow(
        color: Colors.white,
        offset: Offset(-screenWidth * 0.015, -screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
    ];
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: green,
        title: Text(
          widget.supplierId != null ? 'Supplier Products' : 'Browse Products',
          style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
        child: Column(
          children: [
            Row(
              children: [
                Text('Category:', style: TextStyle(fontSize: screenWidth * 0.045)),
                SizedBox(width: screenWidth * 0.02),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: TextStyle(fontSize: screenWidth * 0.045))))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val ?? 'All'),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildProductQuery(),
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.04,
                      mainAxisSpacing: screenWidth * 0.04,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index].data() as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsPage(
                                product: product,
                                productId: products[index].id,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: cardRadius,
                            boxShadow: neumorphicShadow,
                          ),
                          margin: EdgeInsets.symmetric(vertical: screenWidth * 0.01, horizontal: screenWidth * 0.01),
                          padding: EdgeInsets.all(screenWidth * 0.035),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: ProductImageWidget(
                                  imagePath: product['imageUrl'] ?? '',
                                  width: screenWidth * 0.22,
                                  height: screenWidth * 0.22,
                                  placeholder: Icon(Icons.shopping_basket, size: screenWidth * 0.13, color: green),
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.025),
                              Text(product['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                              SizedBox(height: screenWidth * 0.01),
                              Text('₱${product['price']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.042, color: green)),
                              SizedBox(height: screenWidth * 0.01),
                              Text('Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? ''}', style: TextStyle(fontSize: screenWidth * 0.032, color: Colors.grey)),
                              const Spacer(),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFA500), // Orange accent
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
                                    minimumSize: Size(screenWidth * 0.09, screenWidth * 0.09),
                                    padding: EdgeInsets.zero,
                                  ),
                                  onPressed: () async {
                                    final user = FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You must be logged in to add to cart.')),
                                      );
                                      return;
                                    }
                                    int quantity = 1;
                                    final maxQty = (product['quantity'] ?? 1) as int;
                                    final result = await showDialog<int>(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Add to Cart'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('How many would you like to add to cart?'),
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
                                              child: const Text('Add'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (result != null) {
                                      final cartRef = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(user.uid)
                                          .collection('cart');
                                      // Check if product already in cart
                                      final existing = await cartRef
                                          .where('productId', isEqualTo: products[index].id)
                                          .limit(1)
                                          .get();
                                      if (existing.docs.isNotEmpty) {
                                        // Update quantity
                                        final doc = existing.docs.first;
                                        await cartRef.doc(doc.id).update({
                                          'quantity': (doc['quantity'] ?? 1) + result,
                                        });
                                      } else {
                                        await cartRef.add({
                                          'productId': products[index].id,
                                          'sellerId': product['sellerId'],
                                          'name': product['name'],
                                          'imageUrl': product['imageUrl'],
                                          'quantity': result,
                                          'unit': product['unit'],
                                          'price': product['price'],
                                          'supplierName': product['supplierName'],
                                        });
                                      }
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Added to cart!')),
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

  Stream<QuerySnapshot> _buildProductQuery() {
    final base = FirebaseFirestore.instance.collection('products').where('isActive', isEqualTo: true);
    if (widget.supplierId != null) {
      if (_selectedCategory == 'All') {
        return base.where('sellerId', isEqualTo: widget.supplierId).snapshots();
      } else {
        return base
            .where('sellerId', isEqualTo: widget.supplierId)
            .where('category', isEqualTo: _selectedCategory)
            .snapshots();
      }
    } else {
      if (_selectedCategory == 'All') {
        return base.snapshots();
      } else {
        return base.where('category', isEqualTo: _selectedCategory).snapshots();
      }
    }
  }
} 