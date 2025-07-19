// ignore_for_file: deprecated_member_use, empty_catches, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/supplier-side/add_product_page.dart';
import 'package:vegieconnect/supplier-side/farm_map_page.dart' show SupplierLocationPage;
import 'package:vegieconnect/supplier-side/supplier_location_management_page.dart';
import '../authentication/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/product_image_widget.dart';
import '../services/image_storage_service.dart';
import '../customer-side/product_details_page.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({super.key});

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  int _selectedIndex = 0;

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
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
              ),
              child: Text('Supplier Menu', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 24)),
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
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Overview',
            style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.06),
          ),
          SizedBox(height: screenWidth * 0.05),
          SizedBox(
            height: 220,
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: screenWidth * 0.04,
              mainAxisSpacing: screenWidth * 0.04,
              childAspectRatio: 1.5,
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
                        revenue += (data['price'] ?? 0) * (data['quantity'] ?? 1);
                      }
                    }
                    return _buildStatCard(screenWidth, cardRadius, 'Revenue', '\u20b1${revenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: screenWidth * 0.06),
                const Spacer(),
                Icon(Icons.trending_up, color: color, size: screenWidth * 0.05),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(title, style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04, color: AppColors.textSecondary)),
            SizedBox(height: screenWidth * 0.01),
            Text(value, style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(double screenWidth) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No recent orders.'));
        }
        final orders = snapshot.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final status = (order['status'] ?? 'pending').toString().toLowerCase();
            Color statusColor;
            switch (status) {
              case 'delivered':
                statusColor = AppColors.primaryGreen;
                break;
              case 'processing':
                statusColor = Colors.orange;
                break;
              default:
                statusColor = Colors.grey;
            }
            return Container(
              margin: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: order['productImage'] != null && order['productImage'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order['productImage'],
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    )
                  : CircleAvatar(
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                      child: Text(
                        order['id'] != null && order['id'].toString().isNotEmpty
                            ? order['id'].toString().replaceAll(RegExp(r'[^0-9]'), '')
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                title: Text('Order #${order['id'] ?? ''}', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${order['customer'] ?? ''} • ₱${(order['price'] ?? 0).toStringAsFixed(2)}'),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Products',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddProductPage()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProductList(),
        ],
      ),
    );
  }

  Widget _buildProductList() {
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
          return Center(child: Text('Error: \n${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products yet.'));
        }
        final products = snapshot.data!.docs;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: screenWidth * 0.04,
            childAspectRatio: 0.8,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index].data() as Map<String, dynamic>;
            final docId = products[index].id;
            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(
                      product: product,
                      productId: docId,
                    ),
                  ),
                );
              },
              child: Container(
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
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        height: screenWidth * 0.12,
                        child: ProductImageWidget(
                          imagePath: product['imageUrl'] ?? '',
                          width: screenWidth * 0.16,
                          height: screenWidth * 0.125,
                          placeholder: Icon(Icons.shopping_basket, size: screenWidth * 0.08, color: AppColors.primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\u20b1${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Supplier: ${product['supplierName'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                          tooltip: 'Edit',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddProductPage(
                                  product: product,
                                  docId: docId,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          tooltip: 'Delete',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Product'),
                                content: const Text('Are you sure you want to delete this product?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                final imageUrl = product['imageUrl'] ?? '';
                                if (imageUrl.isNotEmpty) {
                                  if (ImageStorageService.isLocalPath(imageUrl)) {
                                    await ImageStorageService.deleteImage(imageUrl);
                                  } else if (ImageStorageService.isNetworkUrl(imageUrl)) {
                                    try {
                                      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
                                      await ref.delete();
                                    } catch (e) {}
                                  }
                                }
                                await FirebaseFirestore.instance.collection('products').doc(docId).delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Product deleted.')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete product: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStockManagementTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Management',
            style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.06),
          ),
          SizedBox(height: screenWidth * 0.05),
          _buildStockOverview(),
          SizedBox(height: screenWidth * 0.05),
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
        
        return SizedBox(
          height: 200, // Fixed height to prevent overflow
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: screenWidth * 0.04,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(screenWidth, BorderRadius.circular(screenWidth * 0.05), 'Total Products', '$totalProducts', Icons.inventory, Colors.blue),
              _buildStatCard(screenWidth, BorderRadius.circular(screenWidth * 0.05), 'Low Stock', '$lowStockProducts', Icons.warning, Colors.orange),
              _buildStatCard(screenWidth, BorderRadius.circular(screenWidth * 0.05), 'Out of Stock', '$outOfStockProducts', Icons.remove_shopping_cart, Colors.red),
              _buildStatCard(screenWidth, BorderRadius.circular(screenWidth * 0.05), 'Total Value', '\u20b1${totalValue.toStringAsFixed(2)}', Icons.attach_money, Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStockList() {
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
            child: Neumorphic(
              style: AppNeumorphic.card,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error,
                      size: screenWidth * 0.15,
                      color: Colors.red,
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    Text(
                      'Error Loading Products',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: screenWidth * 0.06,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      'Please try again later',
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Neumorphic(
              style: AppNeumorphic.card,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2,
                      size: screenWidth * 0.15,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    Text(
                      'No Products Found',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: screenWidth * 0.06,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      'Add your first product to start managing stock',
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
            
            return Neumorphic(
              style: AppNeumorphic.card,
              margin: EdgeInsets.only(bottom: screenWidth * 0.03),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      child: SizedBox(
                        width: screenWidth * 0.15,
                        height: screenWidth * 0.15,
                        child: ProductImageWidget(
                          imagePath: product['imageUrl'] ?? '',
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          placeholder: Icon(Icons.shopping_basket, size: screenWidth * 0.08, color: AppColors.primaryGreen),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
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
                            '\u20b1${price.toStringAsFixed(2)}',
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
              const Text(
                'Profile & Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
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
                      child: const Icon(
                        Icons.store,
                        size: 50,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['name'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      data['email'] ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      'Role: ${data['role'] ?? ''}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Products count
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
                        // Orders count
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
                        // Rating average
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('supplier_ratings')
                              .where('supplierId', isEqualTo: user.uid)
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
              const SizedBox(height: 20),
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
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Edit Profile'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notifications'),
                      subtitle: const Text('Manage notification settings'),
                      trailing: Switch(
                        value: true,
                        onChanged: (value) {},
                        activeColor: AppColors.primaryGreen,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Security'),
                      subtitle: const Text('Password and authentication'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {},
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