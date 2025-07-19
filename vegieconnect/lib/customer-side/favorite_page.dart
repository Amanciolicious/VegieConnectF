import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/product_image_widget.dart';
import 'product_details_page.dart';
import 'package:vegieconnect/theme.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('My Favorites', style: AppTextStyles.headline.copyWith(color: Colors.white)),
        elevation: 0,
      ),
      body: user == null
          ? Center(
              child: Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.08),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: screenWidth * 0.15,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        'Please log in to view favorites',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.06,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildEmptyFavorites(screenWidth);
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final favorites = List<String>.from(userData['favorites'] ?? []);

                if (favorites.isEmpty) {
                  return _buildEmptyFavorites(screenWidth);
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('products')
                      .where(FieldPath.documentId, whereIn: favorites)
                      .where('isVerified', isEqualTo: true)
                      .snapshots(),
                  builder: (context, productsSnapshot) {
                    if (productsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!productsSnapshot.hasData || productsSnapshot.data!.docs.isEmpty) {
                      return _buildEmptyFavorites(screenWidth);
                    }

                    final products = productsSnapshot.data!.docs;
                    return Padding(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Favorite Products',
                            style: AppTextStyles.headline.copyWith(
                              fontSize: screenWidth * 0.06,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.03),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: screenWidth * 0.04,
                                mainAxisSpacing: screenWidth * 0.04,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index].data() as Map<String, dynamic>;
                                final productId = products[index].id;
                                return _buildFavoriteProductCard(screenWidth, product, productId);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyFavorites(double screenWidth) {
    return Center(
      child: Neumorphic(
        style: AppNeumorphic.card,
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: screenWidth * 0.15,
                color: AppColors.primaryGreen,
              ),
              SizedBox(height: screenWidth * 0.04),
              Text(
                'No Favorites Yet',
                style: AppTextStyles.headline.copyWith(
                  fontSize: screenWidth * 0.06,
                  color: AppColors.primaryGreen,
                ),
              ),
              SizedBox(height: screenWidth * 0.02),
              Text(
                'Start adding products to your favorites to see them here',
                style: AppTextStyles.body.copyWith(
                  fontSize: screenWidth * 0.04,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteProductCard(double screenWidth, Map<String, dynamic> product, String productId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(
              product: product,
              productId: productId,
            ),
          ),
        );
      },
      child: Stack(
        children: [
          Neumorphic(
                style: AppNeumorphic.card,
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
                    placeholder: Icon(Icons.shopping_basket, size: screenWidth * 0.13, color: AppColors.primaryGreen),
                  ),
                ),
                SizedBox(height: screenWidth * 0.025),
                Text(
                  product['name'] ?? '',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.045,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: screenWidth * 0.01),
                Text(
                  '\u20b1${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                  style: AppTextStyles.price.copyWith(fontSize: screenWidth * 0.042),
                ),
                SizedBox(height: screenWidth * 0.01),
                Text(
                  'Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? ''}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: screenWidth * 0.032,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: screenWidth * 0.05,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Remove from favorites button
          Positioned(
            top: 8,
            right: 8,
            child: NeumorphicButton(
              style: AppNeumorphic.button.copyWith(
                color: Colors.red,
                boxShape: NeumorphicBoxShape.circle(),
              ),
              onPressed: () => _removeFromFavorites(productId),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.015),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: screenWidth * 0.04,
                ),
              ),
            ),
          ),
        ],
            ),
    );
  }

  Future<void> _removeFromFavorites(String productId) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final userData = await userDoc.get();
      final favorites = List<String>.from(userData.data()?['favorites'] ?? []);
      
      if (favorites.contains(productId)) {
        favorites.remove(productId);
        await userDoc.update({'favorites': favorites});
        
        // Update product popularity
        await _updateProductPopularity(productId, -1);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove from favorites: $e')),
      );
    }
  }

  Future<void> _updateProductPopularity(String productId, int change) async {
    try {
      final productRef = FirebaseFirestore.instance.collection('products').doc(productId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final productDoc = await transaction.get(productRef);
        if (productDoc.exists) {
          final currentPopularity = productDoc.data()?['popularity'] ?? 0;
          transaction.update(productRef, {'popularity': currentPopularity + change});
        }
      });
    } catch (e) {
      debugPrint('Failed to update product popularity: $e');
    }
  }
} 