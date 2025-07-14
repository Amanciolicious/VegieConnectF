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
    final product = widget.product;
    final desc = product['description'] ?? 'No description available';
    final showReadMore = desc.length > 90;
    
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        title: Text('Product Details', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                margin: EdgeInsets.only(top: screenWidth * 0.08, left: screenWidth * 0.04, right: screenWidth * 0.04),
                padding: EdgeInsets.only(top: screenWidth * 0.15, bottom: screenWidth * 0.06),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: cardRadius,
                  boxShadow: neumorphicShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ProductImageWidget(
                        imagePath: product['imageUrl'] ?? '',
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.5,
                        placeholder: Icon(Icons.shopping_basket, size: screenWidth * 0.18, color: green),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'] ?? 'Unknown Product', style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold)),
                          SizedBox(height: screenWidth * 0.015),
                          Row(
                            children: [
                              Icon(Icons.store, color: green, size: screenWidth * 0.05),
                              SizedBox(width: screenWidth * 0.02),
                              Text(product['supplierName'] ?? 'Unknown Supplier', style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey)),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Row(
                            children: [
                              Text('₱${product['price']?.toStringAsFixed(2) ?? '0.00'}/${product['unit'] ?? 'unit'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.055, color: green)),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.07),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.remove, size: screenWidth * 0.06),
                                      onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                                    ),
                                    Text('$_qty ${product['unit'] ?? 'unit'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                                    IconButton(
                                      icon: Icon(Icons.add, size: screenWidth * 0.06),
                                      onPressed: () => setState(() => _qty++),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Row(
                            children: [
                              Icon(Icons.inventory, color: Colors.blue, size: screenWidth * 0.05),
                              SizedBox(width: screenWidth * 0.02),
                              Text('Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? 'unit'}', style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.blue)),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05)),
                          SizedBox(height: screenWidth * 0.01),
                          Text(showReadMore && !_readMore ? '${desc.substring(0, 90)}...' : desc, style: TextStyle(fontSize: screenWidth * 0.042, color: Colors.black87)),
                          if (showReadMore && !_readMore)
                            GestureDetector(
                              onTap: () => setState(() => _readMore = true),
                              child: Text('Read More', style: TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
                            ),
                          SizedBox(height: screenWidth * 0.03),
                          Row(
                            children: [
                              Icon(Icons.category, color: Colors.orange, size: screenWidth * 0.05),
                              SizedBox(width: screenWidth * 0.02),
                              Text('Category: ${product['category'] ?? 'Unknown'}', style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.orange)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.07),
                  topRight: Radius.circular(screenWidth * 0.07),
                ),
                boxShadow: neumorphicShadow,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Price', style: TextStyle(color: Colors.black54, fontSize: screenWidth * 0.04)),
                      Text('₱${((product['price'] ?? 0) * _qty).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.055, color: green)),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: screenWidth * 0.13,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA500), // Orange accent
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
                        elevation: 2,
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