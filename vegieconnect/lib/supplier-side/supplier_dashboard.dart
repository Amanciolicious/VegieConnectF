// ignore_for_file: deprecated_member_use, empty_catches, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/supplier-side/add_product_page.dart';
import 'package:vegieconnect/supplier-side/farm_map_page.dart' show SupplierLocationPage;
import 'package:vegieconnect/supplier-side/supplier_location_management_page.dart';
import 'package:vegieconnect/supplier-side/supplier_orders_page.dart';
import '../authentication/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vegieconnect/services/image_storage_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vegieconnect/services/cloudinary_service.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'supplier_chat_list_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  int _selectedIndex = 0;
  String? _localProfileImagePath;

  @override
  void initState() {
    super.initState();
    _loadLocalProfileImage();
  }

  Future<void> _loadLocalProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final localPath = await ImageStorageService.getProfileImage(user.uid);
      if (localPath != null) {
        setState(() {
          _localProfileImagePath = localPath;
        });
      }
    }
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
                  label: 'Cloudinary',
                  onTap: _uploadViaCloudinary,
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
      
      if (image != null && FirebaseAuth.instance.currentUser != null) {
        // Upload picked file to Cloudinary (mobile/desktop)
        await _uploadToCloudinaryAndSave(file: File(image.path));
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

  Future<void> _uploadViaCloudinary() async {
    Navigator.pop(context);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      if (kIsWeb) {
        // Pick bytes on web
        final Uint8List? bytes = await ImageStorageService.pickImageFromWeb();
        if (bytes == null) return;
        await _uploadToCloudinaryAndSave(bytes: bytes);
      } else {
        // Pick from gallery on mobile as default
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 75,
        );
        if (image != null) {
          await _uploadToCloudinaryAndSave(file: File(image.path));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cloudinary upload failed: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  Future<void> _uploadToCloudinaryAndSave({File? file, Uint8List? bytes}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String imageUrl;
      if (kIsWeb) {
        if (bytes == null) throw ArgumentError('bytes must not be null on web');
        imageUrl = await CloudinaryService.uploadBytes(bytes, folder: 'vegieconnect/avatars/${user.uid}');
      } else {
        if (file == null) throw ArgumentError('file must not be null on mobile');
        imageUrl = await CloudinaryService.uploadFile(file, folder: 'vegieconnect/avatars/${user.uid}');
      }

      // Save URL to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'avatarUrl': imageUrl},
        SetOptions(merge: true),
      );

      setState(() {
        // Clear local path to force using network image
        _localProfileImagePath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated successfully!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  ImageProvider? _getSupplierProfileImage(Map<String, dynamic>? userData) {
    // Priority: Cloudinary avatarUrl > legacy profileImageUrl > local image
    final avatarUrl = userData?['avatarUrl'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return NetworkImage(avatarUrl);
    }

    final profileImageUrl = userData?['profileImageUrl'] as String?;
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return NetworkImage(profileImageUrl);
    }

    if (_localProfileImagePath != null) {
      final file = ImageStorageService.loadImageFromPath(_localProfileImagePath!);
      if (file != null) {
        return FileImage(file);
      }
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Supplier Dashboard',
          style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055),
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Neumorphic(
              style: AppNeumorphic.card.copyWith(
                color: AppColors.primaryGreen,
                boxShape: NeumorphicBoxShape.roundRect(const BorderRadius.only(
                  topRight: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                )),
              ),
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseAuth.instance.currentUser != null 
                    ? FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots()
                    : null,
                  builder: (context, snapshot) {
                    final userData = snapshot.data?.data() as Map<String, dynamic>?;
                    final profileImageUrl = userData?['profileImageUrl'] as String?;
                    final displayName = userData?['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'Supplier';
                    final email = FirebaseAuth.instance.currentUser?.email ?? 'supplier@email.com';
                    
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
                                backgroundImage: _getSupplierProfileImage(userData),
                                child: _getSupplierProfileImage(userData) == null 
                                  ? Icon(Icons.store, size: 40, color: AppColors.accentGreen)
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
                          email,
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
              leading: const Icon(Icons.dashboard),
              title: Text('Overview', style: AppTextStyles.body),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: Text('Manage Products', style: AppTextStyles.body),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text('Stock Management', style: AppTextStyles.body),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: Text('Orders Management', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupplierOrdersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('Profile', style: AppTextStyles.body),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_pin),
              title: Text('Supplier Location', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupplierLocationPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text('Manage Location', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupplierLocationManagementPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.message),
              title: Text('Messages', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SupplierChatListPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text('Logout', style: AppTextStyles.body),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
           
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOverviewTab(screenWidth, cardRadius),
          _buildProductsTab(),
          _buildStockManagementTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(double screenWidth, BorderRadius cardRadius) {
    final user = FirebaseAuth.instance.currentUser;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Optimized for Infinix Smart 8 (720x1612)
    final padding = screenWidth * 0.04; // ~29px
    final cardHeight = screenHeight * 0.12; // ~194px
    final spacing = screenWidth * 0.03; // ~22px
    
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Overview',
            style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05),
          ),
          SizedBox(height: spacing),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.6, // Adjusted for better fit
            children: [
              // Total Products
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('sellerId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildStatCard(screenWidth, cardRadius, 'Total Products', '$count', Icons.inventory, Colors.blue);
                },
              ),
              // Active Orders
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('sellerId', isEqualTo: user.uid)
                    .where('status', isNotEqualTo: 'completed')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildStatCard(screenWidth, cardRadius, 'Active Orders', '$count', Icons.shopping_cart, Colors.green);
                },
              ),
              // Revenue
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('sellerId', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'completed')
                    .snapshots(),
                builder: (context, snapshot) {
                  double revenue = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      revenue += (data['totalPrice'] ?? 0).toDouble();
                    }
                  }
                  return _buildStatCard(screenWidth, cardRadius, 'Revenue', '₱${revenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green);
                },
              ),
              // Total Orders
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('sellerId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildStatCard(screenWidth, cardRadius, 'Total Orders', '$count', Icons.receipt_long, Colors.orange);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(double screenWidth, BorderRadius cardRadius, String title, String value, IconData icon, Color color) {
    return Neumorphic(
      style: AppNeumorphic.card,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: screenWidth * 0.06),
                const Spacer(),
                Icon(Icons.trending_up, color: color, size: screenWidth * 0.04),
              ],
            ),
            const Spacer(),
            Text(
              title, 
              style: AppTextStyles.body.copyWith(
                fontSize: screenWidth * 0.035,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              value, 
              style: AppTextStyles.headline.copyWith(
                fontSize: screenWidth * 0.05,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildProductsTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = screenWidth * 0.04;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Products',
                  style: TextStyle(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddProductPage()),
                  );
                },
                icon: Icon(Icons.add, size: screenWidth * 0.04),
                label: Text(
                  'Add',
                  style: TextStyle(fontSize: screenWidth * 0.032),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.008,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildProductList(),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No products yet',
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          );
        }
        
        final products = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data() as Map<String, dynamic>;
            final docId = products[index].id;
            
            return Container(
              margin: EdgeInsets.only(bottom: screenHeight * 0.01),
              child: Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? 'Product',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              'Price: ₱${product['price'] ?? 0}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            Text(
                              'Stock: ${product['quantity'] ?? 0}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenHeight * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(product['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            ),
                            child: Text(
                              (product['status'] ?? 'pending').toString().toUpperCase(),
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(product['status']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _buildStockManagementTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Management',
            style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.06),
          ),
          SizedBox(height: screenHeight * 0.02),
          _buildStockOverview(),
          SizedBox(height: screenHeight * 0.02),
          _buildStockList(),
        ],
      ),
    );
  }

  Widget _buildStockOverview() {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading data',
              style: AppTextStyles.body.copyWith(color: Colors.red),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        int totalProducts = snapshot.data!.docs.length;
        int lowStockProducts = 0;
        int outOfStockProducts = 0;
        double totalValue = 0;
        
        for (var doc in snapshot.data!.docs) {
          final product = doc.data() as Map<String, dynamic>;
          final quantity = product['quantity'] ?? 0;
          final price = product['price'] ?? 0;
          
          if (quantity <= 0) {
            outOfStockProducts++;
          } else if (quantity <= 5) {
            lowStockProducts++;
          }
          
          totalValue += quantity * price;
        }
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: screenWidth * 0.04,
          mainAxisSpacing: screenWidth * 0.04,
          childAspectRatio: 1.6,
          children: [
            _buildStatCard(screenWidth, BorderRadius.circular(screenWidth * 0.05), 'Total Products', '$totalProducts', Icons.inventory, Colors.blue),
            _buildStatCard(screenWidth, BorderRadius.circular(screenWidth * 0.05), 'Low Stock', '$lowStockProducts', Icons.warning, Colors.orange),
            _buildStatCard(screenWidth, BorderRadius.circular(screenWidth * 0.05), 'Out of Stock', '$outOfStockProducts', Icons.remove_shopping_cart, Colors.red),
            _buildStatCard(screenWidth, BorderRadius.circular(screenWidth * 0.05), 'Total Value', '₱${totalValue.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
          ],
        );
      },
    );
  }

  Widget _buildStockList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return Center(child: Text('Not logged in.', style: TextStyle(fontSize: screenWidth * 0.04)));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('quantity')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(fontSize: screenWidth * 0.035)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No products yet.', style: TextStyle(fontSize: screenWidth * 0.04)));
        }
        
        final products = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data() as Map<String, dynamic>;
            final docId = products[index].id;
            final quantity = product['quantity'] ?? 0;
            final price = product['price'] ?? 0;
            
            Color stockColor;
            if (quantity <= 0) {
              stockColor = Colors.red;
            } else if (quantity <= 5) {
              stockColor = Colors.orange;
            } else {
              stockColor = Colors.green;
            }
            
            return Container(
              margin: EdgeInsets.only(bottom: screenWidth * 0.03),
              child: Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'] ?? 'Unknown Product',
                              style: AppTextStyles.headline.copyWith(
                                fontSize: screenWidth * 0.045,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.01),
                            Text(
                              '₱${price.toStringAsFixed(2)}',
                              style: AppTextStyles.price.copyWith(
                                fontSize: screenWidth * 0.04,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.01),
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: screenWidth * 0.04,
                                  color: stockColor,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  '$quantity ${product['unit'] ?? ''}',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: screenWidth * 0.035,
                                    color: stockColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          NeumorphicButton(
                            style: AppNeumorphic.button.copyWith(
                              color: AppColors.primaryGreen,
                            ),
                            onPressed: () => _updateStock(docId, quantity + 1),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.02),
                              child: Icon(Icons.add, color: Colors.white, size: screenWidth * 0.05),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          NeumorphicButton(
                            style: AppNeumorphic.button.copyWith(
                              color: Colors.red,
                            ),
                            onPressed: () => _updateStock(docId, quantity > 0 ? quantity - 1 : 0),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.02),
                              child: Icon(Icons.remove, color: Colors.white, size: screenWidth * 0.05),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateStock(String productId, int newQuantity) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update({'quantity': newQuantity});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock updated to $newQuantity')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update stock: $e')),
      );
    }
  }

  Widget _buildProfileTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = FirebaseAuth.instance.currentUser;
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No profile data found.'));
        }
        
        final data = snapshot.data!.data() as Map<String, dynamic>;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.06),
              ),
              SizedBox(height: screenWidth * 0.05),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: screenWidth * 0.125,
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                      child: Icon(
                        Icons.store,
                        size: screenWidth * 0.125,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    Text(
                      data['name'] ?? '',
                      style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05),
                    ),
                    Text(
                      data['email'] ?? '',
                      style: AppTextStyles.body.copyWith(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Role: ${data['role'] ?? ''}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('products')
                              .where('sellerId', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                            return _buildProfileStat(screenWidth, 'Products', '$count');
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('orders')
                              .where('sellerId', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                            return _buildProfileStat(screenWidth, 'Orders', '$count');
                          },
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('supplier_ratings')
                              .where('sellerId', isEqualTo: user.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            double avg = 0;
                            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                              double sum = 0;
                              for (var doc in snapshot.data!.docs) {
                                sum += (doc['rating'] ?? 0) is int
                                  ? (doc['rating'] ?? 0).toDouble()
                                  : (doc['rating'] ?? 0);
                              }
                              avg = sum / snapshot.data!.docs.length;
                            }
                            return _buildProfileStat(screenWidth, 'Rating', avg > 0 ? avg.toStringAsFixed(1) : 'N/A');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileStat(double screenWidth, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey),
        ),
      ],
    );
  }
} 