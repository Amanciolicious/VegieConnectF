// ignore_for_file: deprecated_member_use

import 'favorite_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication/login_page.dart';
import 'settings_page.dart';
import 'buyer_products_page.dart';
import 'buyer_order_history_page.dart';
import 'farm_locations_page.dart';
import 'package:vegieconnect/theme.dart'; // Correct import for AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added for Firestore
import 'product_details_page.dart'; // Added for ProductDetailsPage

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
                    Text('Vegie Lover', style: AppTextStyles.headline.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    const Text('vegieuser@email.com', style: TextStyle(color: Colors.white70)),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: AppColors.accentGreen),
              title: const Text('Orders'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Orders'),
                    content: const Text('Order history coming soon!'),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.accentGreen),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
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

class _HomeTab extends StatelessWidget {
  const _HomeTab();

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
                    const Text(
                      'Your Location',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const Spacer(),
                    Icon(Icons.notifications_none, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome, Vegie Lover!',
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
          child: Row(
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Categories', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Neumorphic(
                      style: AppNeumorphic.card.copyWith(color: AppColors.accentGreen.withOpacity(0.15)),
                      child: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 32,
                        child: Icon(Icons.eco, color: AppColors.primaryGreen, size: 32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Veggies', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Spacer(flex: 3),
            ],
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