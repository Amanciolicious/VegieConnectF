// ignore_for_file: deprecated_member_use

import 'favorite_page.dart';
import 'cart_page.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../authentication/login_page.dart';
import 'buyer_products_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vegieconnect/services/cloudinary_service.dart';
import 'package:vegieconnect/theme.dart';
import 'product_details_page.dart';
import 'buyer_order_history_page.dart';
import 'customer_messages_page.dart';
import 'farm_locations_page.dart';
import '../services/image_storage_service.dart';

// Chat and notification center removed

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

  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update Profile Picture', style: AppTextStyles.headline),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildImageOption(
                  icon: Icons.cloud_upload,
                  label: 'Upload via Cloudinary',
                  onTap: () async {
                    Navigator.pop(context);
                    if (kIsWeb) {
                      await _uploadViaCloudinaryWeb();
                    } else {
                      await _uploadViaCloudinaryMobile();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Neumorphic(
            style: AppNeumorphic.card.copyWith(
              color: AppColors.primaryGreen.withOpacity(0.1),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Icon(icon, size: 40, color: AppColors.primaryGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.body),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null && user != null) {
        // Reuse picker for mobile -> upload to Cloudinary instead of local storage
        await _uploadToCloudinaryFromPath(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> _uploadToCloudinaryFromPath(String path) async {
    if (user == null) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final url = await CloudinaryService.uploadFile(File(path));
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'avatarUrl': url});
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile picture: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> _uploadViaCloudinaryWeb() async {
    if (user == null) return;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final bytes = await ImageStorageService.pickImageFromWeb();
      if (bytes == null) {
        Navigator.pop(context);
        return;
      }
      final url = await CloudinaryService.uploadBytes(bytes, fileName: 'avatar_${user!.uid}.jpg');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'avatarUrl': url});
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile picture: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> _uploadViaCloudinaryMobile() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);
    if (image == null) return;
    await _uploadToCloudinaryFromPath(image.path);
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
                child: StreamBuilder<DocumentSnapshot>(
                  stream: user != null 
                    ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots()
                    : null,
                  builder: (context, snapshot) {
                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                    final avatarUrl = (userData?['avatarUrl'] ?? userData?['profileImageUrl']) as String?;
                    final displayName = userData?['name'] ?? user?.displayName ?? 'Vegie Lover';
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: _showProfileImageOptions,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                backgroundImage: avatarUrl != null 
                                  ? NetworkImage(avatarUrl) 
                                  : null,
                                child: avatarUrl == null 
                                  ? Icon(Icons.person, size: 40, color: AppColors.accentGreen)
                                  : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primaryGreen, width: 2),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          displayName,
                          style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'vegieuser@email.com',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },
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
              leading: const Icon(Icons.chat_bubble_outline, color: AppColors.accentGreen),
              title: const Text('Messages'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CustomerMessagesPage()),
                );
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

            // Chat removed

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
        actions: const [],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Optimized for Infinix Smart 8 (720x1612)
    final headerPadding = screenWidth * 0.04; // ~29px
    final verticalSpacing = screenHeight * 0.008; // ~13px
    final searchHeight = screenHeight * 0.055; // ~89px
    
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Neumorphic(
          style: AppNeumorphic.card.copyWith(
            color: AppColors.primaryGreen,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(0)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: headerPadding, vertical: verticalSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(), // Empty space to push notification to right
                    ),
                    Stack(
                      children: [
                        Icon(Icons.notifications_outlined, color: Colors.white, size: screenWidth * 0.06),
                        if (_notificationCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * 0.005),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                              ),
                              constraints: BoxConstraints(
                                minWidth: screenWidth * 0.04,
                                minHeight: screenWidth * 0.04,
                              ),
                              child: Text(
                                '$_notificationCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.025,
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
                SizedBox(height: verticalSpacing * 0.5),
                Text(
                  'Welcome, $_userName!',
                  style: AppTextStyles.headline.copyWith(
                    color: Colors.white,
                    fontSize: screenWidth * 0.055,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: verticalSpacing),
                SizedBox(
                  height: searchHeight,
                  child: Neumorphic(
                    style: AppNeumorphic.inset,
                    child: Row(
                      children: [
                        SizedBox(width: screenWidth * 0.03),
                        Icon(Icons.search, color: Colors.black38, size: screenWidth * 0.05),
                        SizedBox(width: screenWidth * 0.02),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: _onSearchSubmitted,
                            style: TextStyle(fontSize: screenWidth * 0.04),
                            decoration: InputDecoration(
                              hintText: 'Search Vegetables',
                              hintStyle: TextStyle(fontSize: screenWidth * 0.04),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                      ],
                    ),
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
          margin: EdgeInsets.symmetric(horizontal: headerPadding, vertical: verticalSpacing),
          padding: EdgeInsets.all(headerPadding),
          child: GestureDetector(
            onTap: _onPromoBannerTap,
            child: _isLoadingPromo
                ? const Center(child: CircularProgressIndicator())
                : _currentPromo == null
                    ? Row(
                        children: [
                          Icon(Icons.local_offer, color: AppColors.primaryGreen, size: screenWidth * 0.08),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Get 40% discount on your first order from app.',
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: screenHeight * 0.003),
                                Text(
                                  'Shop Now',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenWidth * 0.032,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.eco, color: AppColors.primaryGreen, size: screenWidth * 0.1),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(
                            _getPromoIcon(_currentPromo!['icon'] ?? 'local_offer'),
                            color: AppColors.primaryGreen,
                            size: screenWidth * 0.08,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentPromo!['title'] ?? 'Special Offer',
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: screenHeight * 0.003),
                                Text(
                                  _currentPromo!['subtitle'] ?? 'Shop Now',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenWidth * 0.032,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _getPromoIcon(_currentPromo!['icon'] ?? 'eco'),
                            color: AppColors.primaryGreen,
                            size: screenWidth * 0.1,
                          ),
                        ],
                      ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: headerPadding),
          child: Text(
            'Categories', 
            style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.045),
          ),
        ),
        SizedBox(height: verticalSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: headerPadding),
          child: _isLoadingCategories
              ? Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _categories.isEmpty
                  ? Center(child: Text('No categories available.', style: TextStyle(fontSize: screenWidth * 0.035)))
                  : SizedBox(
                      height: screenHeight * 0.12, // Fixed height to prevent overflow
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((category) {
                            return Padding(
                              padding: EdgeInsets.only(right: screenWidth * 0.04),
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
                                        radius: screenWidth * 0.065, // ~47px for 720px width
                                        child: Icon(
                                          _getCategoryIcon(category['icon'] ?? 'eco'),
                                          color: AppColors.primaryGreen,
                                          size: screenWidth * 0.065,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenHeight * 0.005),
                                    SizedBox(
                                      width: screenWidth * 0.16,
                                      child: Text(
                                        category['name'] ?? 'Category',
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: screenWidth * 0.03,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
        ),
        SizedBox(height: verticalSpacing * 2),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: headerPadding),
          child: Text(
            'Popular', 
            style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.045),
          ),
        ),
        SizedBox(height: verticalSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: headerPadding),
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
                return Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No popular products yet.', style: TextStyle(fontSize: screenWidth * 0.035)));
              }
              final products = snapshot.data!.docs;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: screenWidth * 0.04,
                crossAxisSpacing: screenWidth * 0.04,
                childAspectRatio: 0.85, // Better aspect ratio for product cards
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
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                  color: Colors.grey[100],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                  child: product['imageUrl'] != null && product['imageUrl'].isNotEmpty
                                      ? Image.network(
                                          product['imageUrl'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.eco,
                                                color: AppColors.primaryGreen,
                                                size: screenWidth * 0.08,
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.eco,
                                            color: AppColors.primaryGreen,
                                            size: screenWidth * 0.08,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.008),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    product['name'] ?? '',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₱${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.032,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.favorite, color: Colors.redAccent, size: screenWidth * 0.035),
                                          SizedBox(width: screenWidth * 0.005),
                                          Text(
                                            (product['popularity'] ?? 0).toString(),
                                            style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.028),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
        SizedBox(height: screenHeight * 0.04),
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