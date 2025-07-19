// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/product_image_widget.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

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
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    final product = widget.product;
    final desc = product['description'] ?? 'No description available';
    final showReadMore = desc.length > 90;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: Text('Product Details', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              Neumorphic(
                style: AppNeumorphic.card.copyWith(
                  boxShape: NeumorphicBoxShape.roundRect(cardRadius),
                ),
                margin: EdgeInsets.only(top: screenWidth * 0.08, left: screenWidth * 0.04, right: screenWidth * 0.04),
                padding: EdgeInsets.only(top: screenWidth * 0.15, bottom: screenWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ProductImageWidget(
                        imagePath: product['imageUrl'] ?? '',
                        width: screenWidth * 0.5,
                        height: screenWidth * 0.5,
                        placeholder: Icon(Icons.shopping_basket, size: screenWidth * 0.18, color: AppColors.primaryGreen),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['name'] ?? 'Unknown Product', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.06)),
                          SizedBox(height: screenWidth * 0.015),
                          Row(
                            children: [
                              Icon(Icons.store, color: AppColors.primaryGreen, size: screenWidth * 0.05),
                              SizedBox(width: screenWidth * 0.02),
                              Text(product['supplierName'] ?? 'Unknown Supplier', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04, color: AppColors.textSecondary)),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Row(
                            children: [
                              Text('\u20b1${product['price']?.toStringAsFixed(2) ?? '0.00'}/${product['unit'] ?? 'unit'}', style: AppTextStyles.price.copyWith(fontSize: screenWidth * 0.055)),
                              const Spacer(),
                              // Only show quantity selector for customers (not suppliers)
                              if (user == null || product['sellerId'] != user?.uid)
                                Neumorphic(
                                  style: AppNeumorphic.inset.copyWith(
                                    color: AppColors.primaryGreen.withOpacity(0.12),
                                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(screenWidth * 0.07)),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove, size: screenWidth * 0.06),
                                        onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                                      ),
                                      Text('$_qty ${product['unit'] ?? 'unit'}', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
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
                              Text('Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? 'unit'}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04, color: Colors.blue)),
                            ],
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Text('Product Details', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05)),
                          SizedBox(height: screenWidth * 0.01),
                          Text(showReadMore && !_readMore ? '${desc.substring(0, 90)}...' : desc, style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.042)),
                          if (showReadMore && !_readMore)
                            GestureDetector(
                              onTap: () => setState(() => _readMore = true),
                              child: Text('Read More', style: AppTextStyles.body.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
                            ),
                          SizedBox(height: screenWidth * 0.03),
                          Row(
                            children: [
                              Icon(Icons.category, color: Colors.orange, size: screenWidth * 0.05),
                              SizedBox(width: screenWidth * 0.02),
                              Text('Category: ${product['category'] ?? 'Unknown'}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04, color: Colors.orange)),
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
                child: Text('Related Products', style: AppTextStyles.headline.copyWith(fontSize: 18)),
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
                          child: Neumorphic(
                            style: AppNeumorphic.card.copyWith(color: AppColors.primaryGreen.withOpacity(0.10)),
                            margin: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 100,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ProductImageWidget(
                                    imagePath: relatedProduct['imageUrl'] ?? '',
                                    width: 40,
                                    height: 40,
                                    placeholder: Icon(Icons.shopping_basket, size: 24, color: AppColors.primaryGreen),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    relatedProduct['name'] ?? '',
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
          // Bottom bar - Only show for customers (not suppliers)
          if (user == null || product['sellerId'] != user?.uid)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Neumorphic(
                style: AppNeumorphic.card.copyWith(
                  boxShape: NeumorphicBoxShape.roundRect(BorderRadius.only(
                    topLeft: cardRadius.topLeft,
                    topRight: cardRadius.topRight,
                  )),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.04),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Price', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: screenWidth * 0.035)),
                          Text('\u20b1${(product['price'] * _qty).toStringAsFixed(2)}', style: AppTextStyles.price.copyWith(fontSize: screenWidth * 0.055)),
                        ],
                      ),
                      const Spacer(),
                      NeumorphicButton(
                        style: AppNeumorphic.button.copyWith(
                          color: AppColors.primaryGreen,
                          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(18)),
                        ),
                        onPressed: () async {
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('You must be logged in to add to cart.')),
                            );
                            return;
                          }
                          try {
                            final cartRef = FirebaseFirestore.instance
                                .collection('users')
                                .doc(user?.uid)
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
                        child: Text('Add to Cart', style: AppTextStyles.button.copyWith(fontSize: screenWidth * 0.045)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 