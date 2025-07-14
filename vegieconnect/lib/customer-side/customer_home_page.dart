// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'favorite_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication/login_page.dart';
import 'settings_page.dart';
import 'buyer_products_page.dart';
import 'buyer_order_history_page.dart';
import 'farm_locations_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final green = const Color(0xFFA7C957);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F6F6),
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
            DrawerHeader(
              decoration: BoxDecoration(
                color: green,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(32),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.eco, size: 40, color: Color(0xFFA7C957)),
                  ),
                  SizedBox(height: 12),
                  Text('Vegie Lover', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('vegieuser@email.com', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Color(0xFFA7C957)),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite_border, color: Color(0xFFA7C957)),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined, color: Color(0xFFA7C957)),
              title: const Text('Cart'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Color(0xFFA7C957)),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Color(0xFFA7C957)),
              title: const Text('Browse Products'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BuyerProductsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFFA7C957)),
              title: const Text('Order History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => BuyerOrderHistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_pin, color: Color(0xFFA7C957)),
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
              leading: const Icon(Icons.receipt_long, color: Color(0xFFA7C957)),
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
              leading: const Icon(Icons.settings, color: Color(0xFFA7C957)),
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
        backgroundColor: green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('VegieConnect', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: green,
        unselectedItemColor: Colors.black38,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Favorite'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Cart'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Browse'), // Added Browse tab
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    final darkGreen = const Color(0xFF6CA04A);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Container(
          color: green,
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
              const Text(
                'Welcome, Vegie Lover!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
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
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: green.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(Icons.local_offer, color: green, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Get 40% discount on your first order from app.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 6),
                    Text('Shop Now', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Icon(Icons.eco, color: darkGreen, size: 48),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text('Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: green.withOpacity(0.15),
                      radius: 32,
                      child: Icon(Icons.eco, color: green, size: 32),
                    ),
                    const SizedBox(height: 8),
                    const Text('Veggies', style: TextStyle(fontWeight: FontWeight.w500)),
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
          child: const Text('Popular', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _VeggieCard(name: 'Carrot', image: Icons.emoji_nature),
              _VeggieCard(name: 'Broccoli', image: Icons.grass),
              _VeggieCard(name: 'Tomato', image: Icons.local_florist),
              _VeggieCard(name: 'Cabbage', image: Icons.spa),
            ],
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
    final green = const Color(0xFFA7C957);
    return Container(
      decoration: BoxDecoration(
        color: green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(image, color: green, size: 48),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Icon(Icons.favorite_border, color: Colors.black26),
        ],
      ),
    );
  }
} 