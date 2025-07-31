// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/product_image_widget.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
// Import the ChatPage
import 'chat_conversation_page.dart'; // Import the ChatConversationPage
import 'package:vegieconnect/services/local_messaging_service.dart'; // Import the MessagingService

class BuyerProductsPage extends StatefulWidget {
  final String? supplierId;
  final String? searchQuery;
  final String? categoryFilter;
  final bool? promoFilter;
  
  const BuyerProductsPage({
    super.key, 
    this.supplierId,
    this.searchQuery,
    this.categoryFilter,
    this.promoFilter,
  });

  static Route routeForSupplier(String supplierId) =>
      MaterialPageRoute(builder: (_) => BuyerProductsPage(supplierId: supplierId));

  @override
  State<BuyerProductsPage> createState() => _BuyerProductsPageState();
}

class _BuyerProductsPageState extends State<BuyerProductsPage> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Vegetable', 'Fruit', 'Other'];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize search query if provided
    if (widget.searchQuery != null) {
      _searchQuery = widget.searchQuery!;
      _searchController.text = widget.searchQuery!;
    }
    
    // Initialize category filter if provided
    if (widget.categoryFilter != null) {
      _selectedCategory = widget.categoryFilter!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          _getAppBarTitle(),
          style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
        child: Column(
          children: [
            // Search bar
            Neumorphic(
              style: AppNeumorphic.inset,
              margin: EdgeInsets.only(bottom: screenWidth * 0.03),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.black38),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...', border: InputBorder.none,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child: Icon(Icons.close, color: Colors.black26),
                    ),
                ],
              ),
            ),
            // Category chips row
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, idx) => SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  IconData? icon;
                  switch (cat) {
                    case 'Vegetable': icon = Icons.eco; break;
                    case 'Fruit': icon = Icons.local_florist; break;
                    case 'Other': icon = Icons.category; break;
                    default: icon = Icons.apps;
                  }
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.primaryGreen),
                        SizedBox(width: 6),
                        Text(cat, style: AppTextStyles.body.copyWith(color: isSelected ? Colors.white : AppColors.primaryGreen)),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    elevation: isSelected ? 2 : 0,
                    shadowColor: Colors.black12,
                  );
                },
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildProductQuery(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 50, color: Colors.red),
                          SizedBox(height: 16),
                          Text('Error loading products', style: AppTextStyles.body.copyWith(color: Colors.red)),
                          SizedBox(height: 8),
                          Text('${snapshot.error}', style: AppTextStyles.body.copyWith(fontSize: 12)),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No products found.', style: AppTextStyles.body));
                  }
                  final products = snapshot.data!.docs
                      .where((doc) {
                        final product = doc.data() as Map<String, dynamic>;
                        final name = (product['name'] ?? '').toString().trim();
                        final price = (product['price'] ?? 0);
                        final quantity = (product['quantity'] ?? 0);
                        final status = product['status'] ?? 'pending';
                        final isApproved = status == 'approved';
                        final isPending = status == 'pending';
                        final contentFlagged = product['contentFlagged'] ?? false;
                        final requiresManualReview = product['requiresManualReview'] ?? false;
                        
                        // Show approved products or pending products that are not flagged
                        final isEligible = isApproved || (isPending && !contentFlagged && !requiresManualReview);
                        
                        // Filter by search query
                        final matchesSearch = _searchQuery.isEmpty || name.toLowerCase().contains(_searchQuery);
                        return name.isNotEmpty && price > 0 && quantity > 0 && matchesSearch && isEligible;
                      })
                      .toList()
                      ..sort((a, b) {
                        final aPopularity = (a.data() as Map<String, dynamic>)['popularity'] ?? 0;
                        final bPopularity = (b.data() as Map<String, dynamic>)['popularity'] ?? 0;
                        return bPopularity.compareTo(aPopularity); // Descending order
                      });
                  if (products.isEmpty) {
                    return Center(child: Text('No products found.', style: AppTextStyles.body));
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
                      final productId = products[index].id;
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                contentPadding: EdgeInsets.all(screenWidth * 0.04),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: ProductImageWidget(
                                        imagePath: product['imageUrl'] ?? '',
                                        width: screenWidth * 0.3,
                                        height: screenWidth * 0.3,
                                        placeholder: Icon(Icons.shopping_basket, size: screenWidth * 0.13, color: AppColors.primaryGreen),
                                      ),
                                    ),
                                    SizedBox(height: screenWidth * 0.03),
                                    Text(product['name'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.055)),
                                    SizedBox(height: screenWidth * 0.01),
                                    Text('Supplier: ${product['supplierName'] ?? ''}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
                                    SizedBox(height: screenWidth * 0.01),
                                    NeumorphicButton(
                                      style: AppNeumorphic.button.copyWith(
                                        color: Colors.blue,
                                        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
                                      ),
                                      onPressed: () async {
                                        Navigator.pop(context); // Close dialog
                                        try {
                                          final messagingService = LocalMessagingService();
                                          final chatId = await messagingService.createChatWithSupplier(product['sellerId']);
                                          if (!mounted) return;
                                          
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatConversationPage(
                                                chatId: chatId,
                                                chatTitle: product['supplierName'] ?? 'Supplier',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error starting chat: $e'),
                                              backgroundColor: AppColors.accentRed,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.015),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.chat, color: Colors.white, size: 16),
                                            SizedBox(width: 6),
                                            Text('Chat', style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenWidth * 0.01),
                                    Text('\u20b1${product['price']?.toStringAsFixed(2) ?? '0.00'}', style: AppTextStyles.price.copyWith(fontSize: screenWidth * 0.045)),
                                    SizedBox(height: screenWidth * 0.01),
                                    Text('Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? ''}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.035, color: AppColors.textSecondary)),
                                    
                                    // Status indicator for pending auto-approval
                                    if (product['status'] == 'pending' && !(product['contentFlagged'] ?? false))
                                      Padding(
                                        padding: EdgeInsets.only(top: screenWidth * 0.02),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(screenWidth * 0.01),
                                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.schedule, color: Colors.orange, size: screenWidth * 0.03),
                                              SizedBox(width: screenWidth * 0.01),
                                              Text(
                                                'Auto-approval in progress',
                                                style: AppTextStyles.body.copyWith(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    
                                    // Status indicator for newly approved products (within last 24 hours)
                                    if (product['status'] == 'approved' && product['approvalMethod'] == 'manual' && 
                                        product['approvedAt'] != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: screenWidth * 0.02),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(screenWidth * 0.01),
                                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified, color: Colors.green, size: screenWidth * 0.03),
                                              SizedBox(width: screenWidth * 0.01),
                                              Text(
                                                'Recently approved',
                                                style: AppTextStyles.body.copyWith(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    
                                    SizedBox(height: screenWidth * 0.02),
                                    ElevatedButton(
                                      onPressed: () async {
                                        int quantity = 1;
                                        final maxQty = (product['quantity'] ?? 1) as int;
                                        final result = await showDialog<int>(
                                          context: context,
                                          builder: (context) {
                                            return StatefulBuilder(
                                              builder: (context, setDialogState) {
                                                return AlertDialog(
                                                  title: const Text('Add to Cart'),
                                                  content: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text('How many would you like to add to cart?'),
                                                      const SizedBox(height: 12),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          IconButton(
                                                            icon: const Icon(Icons.remove),
                                                            onPressed: quantity > 1
                                                                ? () {
                                                                    quantity--;
                                                                    setDialogState(() {});
                                                                  }
                                                                : null,
                                                          ),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                            decoration: BoxDecoration(
                                                              border: Border.all(color: Colors.grey),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              '$quantity',
                                                              style: const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                          IconButton(
                                                            icon: const Icon(Icons.add),
                                                            onPressed: quantity < maxQty
                                                                ? () {
                                                                    quantity++;
                                                                    setDialogState(() {});
                                                                  }
                                                                : null,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Available: $maxQty ${product['unit'] ?? 'units'}',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
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
                                          },
                                        );
                                        if (result != null) {
                                          await _addToCart(productId, product, result);
                                        }
                                      },
                                      child: Text('Add to Cart'),
                                    ),
                                  ],
                                ),
                              );
                            },
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
                                  Text(product['name'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                                  SizedBox(height: screenWidth * 0.01),
                                  Text('\u20b1${product['price']?.toStringAsFixed(2) ?? '0.00'}', style: AppTextStyles.price.copyWith(fontSize: screenWidth * 0.042)),
                                  SizedBox(height: screenWidth * 0.01),
                                  Text('Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? ''}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.032, color: AppColors.textSecondary)),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      StreamBuilder<QuerySnapshot>(
                                        stream: user != null 
                                            ? FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user!.uid)
                                                .collection('cart')
                                                .where('productId', isEqualTo: productId)
                                                .snapshots()
                                            : null,
                                        builder: (context, cartSnapshot) {
                                          final isInCart = cartSnapshot.hasData && cartSnapshot.data!.docs.isNotEmpty;
                                          return isInCart
                                              ? Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primaryGreen.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text('In Basket', style: AppTextStyles.body.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.032)),
                                                )
                                              : const SizedBox.shrink();
                                        },
                                      ),
                                      if ((product['popularity'] ?? 0) > 5)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text('Popular', style: AppTextStyles.body.copyWith(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.032)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Favorite button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: user != null 
                                    ? FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user!.uid)
                                        .snapshots()
                                    : null,
                                builder: (context, snapshot) {
                                  final isFavorite = snapshot.hasData && 
                                      snapshot.data!.exists &&
                                      (snapshot.data!.data() as Map<String, dynamic>)['favorites'] != null &&
                                      (snapshot.data!.data() as Map<String, dynamic>)['favorites'].contains(productId);
                                
                                  return NeumorphicButton(
                                    style: AppNeumorphic.button.copyWith(
                                      color: isFavorite ? Colors.red : Colors.white,
                                      boxShape: NeumorphicBoxShape.circle(),
                                    ),
                                    onPressed: () => _toggleFavorite(productId),
                                    child: Padding(
                                      padding: EdgeInsets.all(screenWidth * 0.015),
                                      child: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.white : Colors.red,
                                        size: screenWidth * 0.04,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Add to cart button
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: NeumorphicButton(
                                style: AppNeumorphic.button.copyWith(
                                  color: AppColors.primaryGreen,
                                  boxShape: NeumorphicBoxShape.circle(),
                                ),
                                onPressed: () async {
                                  if (user == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('You must be logged in to add to cart.')),
                                    );
                                    return;
                                  }
                                  final maxQty = (product['quantity'] ?? 1) as int;
                                  int quantity = 1; // Move quantity outside the builder
                                  final result = await showDialog<int>(
                                    context: context,
                                    builder: (context) {
                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return AlertDialog(
                                            title: const Text('Add to Cart'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('How many would you like to add to cart?'),
                                                const SizedBox(height: 12),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.remove),
                                                      onPressed: quantity > 1
                                                          ? () {
                                                              quantity--;
                                                              setDialogState(() {});
                                                            }
                                                          : null,
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(color: Colors.grey),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        '$quantity',
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.add),
                                                      onPressed: quantity < maxQty
                                                          ? () {
                                                              quantity++;
                                                              setDialogState(() {});
                                                            }
                                                          : null,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Available: $maxQty ${product['unit'] ?? 'units'}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
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
                                    },
                                  );
                                  if (result != null) {
                                    await _addToCart(productId, product, result);
                                  }
                                },
                                child: Icon(Icons.add, color: Colors.white, size: 20),
                              ),
                            ),
                          ],
                        ));
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

  String _getAppBarTitle() {
    if (widget.supplierId != null) {
      return 'Supplier Products';
    } else {
      return 'Browse Products';
    }
  }

  Stream<QuerySnapshot> _buildProductQuery() {
    Query base = FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('status', whereIn: ['approved', 'pending']); // Show approved and pending products
    
    // Apply promo filter if specified
    if (widget.promoFilter == true) {
      base = base.where('hasPromo', isEqualTo: true);
    }
    
    // Apply supplier filter if specified
    if (widget.supplierId != null) {
      base = base.where('sellerId', isEqualTo: widget.supplierId);
    }
    
    // Apply category filter
    if (_selectedCategory != 'All') {
      base = base.where('category', isEqualTo: _selectedCategory);
    }
    
    return base.snapshots();
  }

  Future<void> _addToCart(String productId, Map<String, dynamic> product, int quantity) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add to cart.')),
      );
      return;
    }
    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('cart');
    // Check if product already in cart
    final existing = await cartRef
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      // Update quantity
      final doc = existing.docs.first;
      await cartRef.doc(doc.id).update({
        'quantity': (doc['quantity'] ?? 1) + quantity,
      });
    } else {
      await cartRef.add({
        'productId': productId,
        'sellerId': product['sellerId'],
        'name': product['name'],
        'imageUrl': product['imageUrl'],
        'quantity': quantity,
        'unit': product['unit'],
        'price': product['price'],
        'supplierName': product['supplierName'],
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart!')),
    );
  }

  Future<void> _toggleFavorite(String productId) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add favorites.')),
      );
      return;
    }

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final userData = await userDoc.get();
      final favorites = List<String>.from(userData.data()?['favorites'] ?? []);
      
      if (favorites.contains(productId)) {
        // Remove from favorites
        favorites.remove(productId);
        await userDoc.update({'favorites': favorites});
        await _updateProductPopularity(productId, -1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites')),
        );
      } else {
        // Add to favorites
        favorites.add(productId);
        await userDoc.update({'favorites': favorites});
        await _updateProductPopularity(productId, 1);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to favorites')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update favorites: $e')),
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

