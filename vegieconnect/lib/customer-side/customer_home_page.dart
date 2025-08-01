// ignore_for_file: deprecated_member_use

import 'favorite_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication/login_page.dart';
import 'buyer_products_page.dart';
import 'buyer_order_history_page.dart';
import 'farm_locations_page.dart';


import 'package:vegieconnect/theme.dart'; // Correct import for AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'product_details_page.dart'; // Added for ProductDetailsPage
import '../widgets/notification_center.dart';
// Added for ChatPage
// Added for TextEditingController
import 'chat_list_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User? get user => FirebaseAuth.instance.currentUser;

  static final List<Widget> _pages = [
    _HomeTab(),
    FavoritePage(),
    CartPage(),
    ProfilePage(),
    BuyerProductsPage(), // Added for Browse tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Neumorphic(
              style: AppNeumorphic.card.copyWith(
                color: AppColors.primaryGreen,
                boxShape: NeumorphicBoxShape.roundRect(const BorderRadius.only(
                  topRight: Radius.circular(32),
                  bottomRight: Radius.circular(0),
                )),
              ),
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.eco, size: 40, color: AppColors.accentGreen),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'Vegie Lover',
                      style: AppTextStyles.headline.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'vegieuser@email.com',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: AppColors.accentGreen),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border, color: AppColors.accentGreen),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined, color: AppColors.accentGreen),
              title: const Text('Cart'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppColors.accentGreen),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.store, color: AppColors.accentGreen),
              title: const Text('Browse Products'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BuyerProductsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.accentGreen),
              title: const Text('Order History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BuyerOrderHistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_pin, color: AppColors.accentGreen),
              title: const Text('Supplier Locations'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FarmLocationsPage()),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: AppColors.accentGreen),
              title: const Text('My Chats'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatListPage()),
                );
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('VegieConnect', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          const NotificationCenter(),
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .collection('cart')
                .snapshots()
            : null,
        builder: (context, snapshot) {
          int cartCount = 0;
          if (snapshot.hasData) {
            cartCount = snapshot.data!.docs.length;
          }
          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
            elevation: Theme.of(context).bottomNavigationBarTheme.elevation,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              const BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorite'),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.shopping_cart_outlined),
                    if (cartCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.badgeRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Cart',
              ),
              const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
              const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Browse'),
            ],
          );
        },
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final TextEditingController _searchController = TextEditingController();
  String _userName = 'Vegie Lover';
  String _userEmail = 'vegieuser@email.com';
  String _userLocation = 'Your Location';
  int _notificationCount = 0;
  List<Map<String, dynamic>> _categories = [];
  bool _isLoadingCategories = true;
  Map<String, dynamic>? _currentPromo;
  bool _isLoadingPromo = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCategories();
    _loadNotificationCount();
    _loadCurrentPromo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          setState(() {
            _userName = userData['name'] ?? 'Vegie Lover';
            _userEmail = userData['email'] ?? user.email ?? 'vegieuser@email.com';
            _userLocation = userData['location'] ?? 'Your Location';
          });
        }
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      setState(() {
        _categories = categoriesSnapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList();
        _isLoadingCategories = false;
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadNotificationCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final notificationsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get();

        setState(() {
          _notificationCount = notificationsSnapshot.docs.length;
        });
      } catch (e) {
        debugPrint('Error loading notifications: $e');
      }
    }
  }

  Future<void> _loadCurrentPromo() async {
    try {
      final promoDoc = await FirebaseFirestore.instance
          .collection('promotions')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (promoDoc.docs.isNotEmpty) {
        setState(() {
          _currentPromo = promoDoc.docs.first.data();
          _isLoadingPromo = false;
        });
      } else {
        setState(() {
          _isLoadingPromo = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading current promo: $e');
      setState(() {
        _isLoadingPromo = false;
      });
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BuyerProductsPage(searchQuery: query.trim()),
        ),
      );
    }
  }

  void _onCategoryTap(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerProductsPage(categoryFilter: category['name']),
      ),
    );
  }

  void _onNotificationTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationCenter(),
      ),
    );
  }

  void _onPromoBannerTap() {
    // Navigate to products with promo filter
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerProductsPage(promoFilter: true),
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'eco':
        return Icons.eco;
      case 'local_offer':
        return Icons.local_offer;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'person':
        return Icons.person;
      case 'store':
        return Icons.store;
      case 'history':
        return Icons.history;
      case 'notifications':
        return Icons.notifications;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'chat':
        return Icons.chat;
      case 'location_on':
        return Icons.location_on;
      default:
        return Icons.category;
    }
  }

  IconData _getPromoIcon(String iconName) {
    switch (iconName) {
      case 'local_offer':
        return Icons.local_offer;
      case 'eco':
        return Icons.eco;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'person':
        return Icons.person;
      case 'store':
        return Icons.store;
      case 'history':
        return Icons.history;
      case 'notifications':
        return Icons.notifications;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'chat':
        return Icons.chat;
      case 'location_on':
        return Icons.location_on;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Neumorphic(
          style: AppNeumorphic.card.copyWith(
            color: AppColors.primaryGreen,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(0)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _userLocation,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const Spacer(),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.white),
                          onPressed: _onNotificationTap,
                        ),
                        if (_notificationCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$_notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome, $_userName!',
                  style: AppTextStyles.headline.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Neumorphic(
                  style: AppNeumorphic.inset,
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search, color: Colors.black38),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: _onSearchSubmitted,
                          decoration: InputDecoration(
                            hintText: 'Search Vegetables',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Neumorphic(
          style: AppNeumorphic.card.copyWith(
            color: AppColors.primaryGreen.withOpacity(0.15),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          padding: const EdgeInsets.all(18),
          child: GestureDetector(
            onTap: _onPromoBannerTap,
            child: _isLoadingPromo
                ? const Center(child: CircularProgressIndicator())
                : _currentPromo == null
                    ? Row(
                        children: [
                          Icon(Icons.local_offer, color: AppColors.primaryGreen, size: 40),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Get 40% discount on your first order from app.',
                                    style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Shop Now', style: AppTextStyles.body.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          Icon(Icons.eco, color: AppColors.primaryGreen, size: 48),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            _getPromoIcon(_currentPromo!['icon'] ?? 'local_offer'),
                            color: AppColors.primaryGreen,
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPromo!['title'] ?? 'Special Offer',
                                  style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _currentPromo!['subtitle'] ?? 'Shop Now',
                                  style: AppTextStyles.body.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _getPromoIcon(_currentPromo!['icon'] ?? 'eco'),
                            color: AppColors.primaryGreen,
                            size: 48,
                          ),
                        ],
                      ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Categories', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _isLoadingCategories
              ? const Center(child: CircularProgressIndicator())
              : _categories.isEmpty
                  ? const Center(child: Text('No categories available.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () => _onCategoryTap(category),
                              child: Column(
                                children: [
                                  Neumorphic(
                                    style: AppNeumorphic.card.copyWith(
                                      color: AppColors.accentGreen.withOpacity(0.15),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      radius: 32,
                                      child: Icon(
                                        _getCategoryIcon(category['icon'] ?? 'eco'),
                                        color: AppColors.primaryGreen,
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category['name'] ?? 'Category',
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Popular', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('isActive', isEqualTo: true)
                .where('isVerified', isEqualTo: true)
                .orderBy('popularity', descending: true)
                .limit(4)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No popular products yet.'));
              }
              final products = snapshot.data!.docs;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: products.map((doc) {
                  final product = doc.data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(
                            product: product,
                            productId: doc.id,
                          ),
                        ),
                      );
                    },
                    child: Neumorphic(
                      style: AppNeumorphic.card.copyWith(color: AppColors.primaryGreen.withOpacity(0.10)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.eco, color: AppColors.primaryGreen, size: 48),
                          const SizedBox(height: 10),
                          Text(product['name'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 4),
                              Text((product['popularity'] ?? 0).toString(), style: AppTextStyles.body.copyWith(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _VeggieCard extends StatelessWidget {
  final String name;
  final IconData image;
  const _VeggieCard({required this.name, required this.image});

  @override
  Widget build(BuildContext context) {
    return Neumorphic(
      style: AppNeumorphic.card.copyWith(color: AppColors.primaryGreen.withOpacity(0.10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(image, color: AppColors.primaryGreen, size: 48),
          const SizedBox(height: 10),
          Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Icon(Icons.favorite_border, color: Colors.black26),
        ],
      ),
    );
  }
} 