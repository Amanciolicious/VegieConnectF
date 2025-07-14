// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/product_image_widget.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productId;
  
  const ProductDetailsPage({
    super.key, 
    required this.product, 
    required this.productId,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int _qty = 1;
  bool _readMore = false;

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    final product = widget.product;
    final desc = product['description'] ?? 'No description available';
    final showReadMore = desc.length > 90;
    
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6EA),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 40, left: 16, right: 16),
                    padding: const EdgeInsets.only(top: 60, bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ProductImageWidget(
                            imagePath: product['imageUrl'] ?? '',
                            width: 200,
                            height: 200,
                            placeholder: Icon(Icons.shopping_basket, size: 100, color: green),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'] ?? 'Unknown Product', 
                                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.store, color: green, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    product['supplierName'] ?? 'Unknown Supplier',
                                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '₱${product['price']?.toStringAsFixed(2) ?? '0.00'}/${product['unit'] ?? 'unit'}', 
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: green)
                                  ),
                                  const Spacer(),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 20),
                                          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                                        ),
                                        Text('$_qty ${product['unit'] ?? 'unit'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 20),
                                          onPressed: () => setState(() => _qty++),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.inventory, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? 'unit'}',
                                    style: const TextStyle(fontSize: 15, color: Colors.blue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 6),
                              Text(
                                showReadMore && !_readMore ? '${desc.substring(0, 90)}...' : desc,
                                style: const TextStyle(fontSize: 16, color: Colors.black87),
                              ),
                              if (showReadMore && !_readMore)
                                GestureDetector(
                                  onTap: () => setState(() => _readMore = true),
                                  child: const Text('Read More', style: TextStyle(color: Color(0xFFA7C957), fontWeight: FontWeight.bold)),
                                ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Icon(Icons.category, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Category: ${product['category'] ?? 'Unknown'}',
                                    style: const TextStyle(fontSize: 15, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 56,
                    left: 32,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 56,
                    right: 32,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.favorite_border, color: Color(0xFFA7C957)),
                        onPressed: () {
                        
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to favorites!')),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text('Related Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where('isActive', isEqualTo: true)
                      .where('category', isEqualTo: product['category'])
                      .limit(4)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    
                    final relatedProducts = snapshot.data!.docs
                        .where((doc) => doc.id != widget.productId)
                        .take(4)
                        .toList();
                    
                    if (relatedProducts.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: relatedProducts.length,
                      itemBuilder: (context, index) {
                        final relatedProduct = relatedProducts[index].data() as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsPage(
                                product: relatedProduct,
                                productId: relatedProducts[index].id,
                              ),
                            ),
                          ),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: green.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ProductImageWidget(
                                  imagePath: relatedProduct['imageUrl'] ?? '',
                                  width: 40,
                                  height: 40,
                                  placeholder: Icon(Icons.shopping_basket, size: 24, color: green),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  relatedProduct['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 100),
            ],
          ),
          // Bottom bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Price', style: TextStyle(color: Colors.black54)),
                      Text(
                        '₱${((product['price'] ?? 0) * _qty).toStringAsFixed(2)}', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: green)
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You must be logged in to add to cart.')),
                          );
                          return;
                        }
                        try {
                          final cartRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('cart');
                          // Check if product already in cart
                          final existing = await cartRef
                              .where('productId', isEqualTo: widget.productId)
                              .limit(1)
                              .get();
                          if (existing.docs.isNotEmpty) {
                            // Update quantity
                            final doc = existing.docs.first;
                            await cartRef.doc(doc.id).update({
                              'quantity': (doc['quantity'] ?? 1) + _qty,
                            });
                          } else {
                            await cartRef.add({
                              'productId': widget.productId,
                              'sellerId': product['sellerId'],
                              'name': product['name'],
                              'imageUrl': product['imageUrl'],
                              'quantity': _qty,
                              'unit': product['unit'],
                              'price': product['price'],
                              'supplierName': product['supplierName'],
                            });
                          }
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart!')),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error adding to cart: $e')),
                          );
                        }
                      },
                      child: const Text('Add to Cart', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 