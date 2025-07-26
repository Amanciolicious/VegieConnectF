// ignore_for_file: deprecated_member_use, empty_catches, use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/supplier-side/add_product_page.dart';
import 'package:vegieconnect/supplier-side/farm_map_page.dart' show SupplierLocationPage;
import 'package:vegieconnect/supplier-side/supplier_location_management_page.dart';
import 'package:vegieconnect/supplier-side/supplier_chat_page.dart';
import 'package:vegieconnect/widgets/chat_widgets.dart';
import '../authentication/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/product_image_widget.dart';
import '../services/image_storage_service.dart';
import '../customer-side/product_details_page.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/supplier-side/supplier_orders_page.dart'; // Added import for SupplierOrdersPage

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
              leading: const Icon(Icons.chat),
              title: Text('Chat', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupplierChatPage()),
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
          _buildOrdersTab(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
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
                    // Status label
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: () {
                          final status = (product['status'] ?? 'pending').toString();
                          if (status == 'approved') return Colors.green.withOpacity(0.15);
                          if (status == 'rejected') return Colors.red.withOpacity(0.15);
                          return Colors.orange.withOpacity(0.15);
                        }(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (product['status'] ?? 'pending').toString().toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: () {
                                final status = (product['status'] ?? 'pending').toString();
                                if (status == 'approved') return Colors.green;
                                if (status == 'rejected') return Colors.red;
                                return Colors.orange;
                              }(),
                            ),
                          ),
                          // Show approval method if approved
                          if ((product['status'] ?? '') == 'approved' && (product['approvalMethod'] ?? '').isNotEmpty)
                            Text(
                              product['approvalMethod'] == 'manual' ? 'Admin Approved' : 'Auto Approved',
                              style: TextStyle(
                                fontSize: 10,
                                color: () {
                                  final status = (product['status'] ?? 'pending').toString();
                                  if (status == 'approved') return Colors.green;
                                  if (status == 'rejected') return Colors.red;
                                  return Colors.orange;
                                }(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Show rejection reason if rejected
                    if ((product['status'] ?? '') == 'rejected' && (product['rejectionReason'] ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Reason: ${product['rejectionReason']}',
                          style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
        final userRole = data['role'] ?? '';
        final isBuyer = userRole == 'buyer';
        final isNotSupplier = user.uid != user.uid; // This will always be false, fix below
        // Instead, get the supplierId from the profile being viewed (assume user.uid is supplierId for now)
        final supplierId = user.uid;
        return SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
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
                        // Rate Supplier button for buyers (only if not supplier)
                        if (isBuyer && user.uid != supplierId)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _showRateSupplierDialog(context, supplierId, data['name'] ?? ''),
                            child: const Text('Rate Supplier'),
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

  Widget _buildOrdersTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    // State for search/filter
    String searchQuery = '';
    String? statusFilter;
    String? productFilter;
    int page = 0;
    int pageSize = 10;
    return StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Orders', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download),
                      tooltip: 'Export to CSV',
                      onPressed: () => _exportOrdersToCSV(user.uid),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateOrderDialog(context, user.uid),
                      icon: const Icon(Icons.add),
                      label: const Text('New Order'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search by product, buyer, or note...'),
                    onChanged: (val) => setState(() => searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: statusFilter,
                  hint: const Text('Status'),
                  items: [null, 'pending', 'processing', 'fulfilled', 'shipped', 'delivered', 'cancelled']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s == null ? 'All' : s.capitalize())))
                      .toList(),
                  onChanged: (val) => setState(() => statusFilter = val),
                ),
                const SizedBox(width: 8),
                // Product filter (optional, can be filled with product names)
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('sellerId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No orders yet.'));
                }
                var orders = snapshot.data!.docs;
                // Apply search/filter
                orders = orders.where((doc) {
                  final o = doc.data() as Map<String, dynamic>;
                  final matchesSearch = searchQuery.isEmpty ||
                    (o['productName'] ?? '').toString().toLowerCase().contains(searchQuery) ||
                    (o['buyerName'] ?? '').toString().toLowerCase().contains(searchQuery) ||
                    (o['note'] ?? '').toString().toLowerCase().contains(searchQuery);
                  final matchesStatus = statusFilter == null || (o['status'] ?? '') == statusFilter;
                  return matchesSearch && matchesStatus;
                }).toList();
                // Pagination
                final totalPages = (orders.length / pageSize).ceil();
                final pagedOrders = orders.skip(page * pageSize).take(pageSize).toList();
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: pagedOrders.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final order = pagedOrders[index].data() as Map<String, dynamic>;
                          final orderId = pagedOrders[index].id;
                          final status = (order['status'] ?? 'pending').toString().toLowerCase();
                          final productId = order['productId'] ?? '';
                          final quantity = order['quantity'] ?? 1;
                          return ListTile(
                            leading: order['productImage'] != null && order['productImage'].toString().isNotEmpty
                                ? Image.network(order['productImage'], width: 44, height: 44, fit: BoxFit.cover)
                                : const Icon(Icons.shopping_basket, size: 44),
                            title: Text(order['productName'] ?? 'Order'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Qty: $quantity | ₱${order['price'] ?? ''}'),
                                if (order['buyerName'] != null) Text('Buyer: ${order['buyerName']}'),
                                if (order['note'] != null) Text('Note: ${order['note']}'),
                                Text('Date: ${order['createdAt'] != null ? (order['createdAt'] as Timestamp).toDate().toString() : ''}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _statusChip(status),
                                if (status == 'pending' || status == 'processing')
                                  PopupMenuButton<String>(
                                    onSelected: (val) => _updateOrderStatus(orderId, val),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'processing', child: Text('Mark as Processing')),
                                      const PopupMenuItem(value: 'shipped', child: Text('Mark as Shipped')),
                                      const PopupMenuItem(value: 'delivered', child: Text('Mark as Delivered')),
                                      const PopupMenuItem(value: 'cancelled', child: Text('Cancel Order')),
                                    ],
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  tooltip: 'Details',
                                  onPressed: () => _showOrderDetailsDialog(context, order, orderId),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (totalPages > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: page > 0 ? () => setState(() => page--) : null,
                          ),
                          Text('Page ${page + 1} of $totalPages'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: page < totalPages - 1 ? () => setState(() => page++) : null,
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'fulfilled':
        color = Colors.green;
        break;
      case 'processing':
        color = Colors.orange;
        break;
      case 'shipped':
        color = Colors.blue;
        break;
      case 'delivered':
        color = Colors.purple;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(status.capitalize(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    await orderRef.update({'status': newStatus});
  }

  void _showOrderDetailsDialog(BuildContext context, Map<String, dynamic> order, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order['productImage'] != null && (order['productImage'] as String).isNotEmpty)
                Image.network(order['productImage'], width: 80, height: 80, fit: BoxFit.cover),
              Text('Product: ${order['productName'] ?? ''}'),
              Text('Quantity: ${order['quantity'] ?? ''}'),
              Text('Price: ₱${order['price'] ?? ''}'),
              if (order['buyerName'] != null) Text('Buyer: ${order['buyerName']}'),
              if (order['buyerId'] != null) Text('Buyer ID: ${order['buyerId']}'),
              if (order['note'] != null) Text('Note: ${order['note']}'),
              Text('Status: ${order['status'] ?? ''}'),
              Text('Created: ${order['createdAt'] != null ? (order['createdAt'] as Timestamp).toDate().toString() : ''}'),
              if (order['updatedAt'] != null) Text('Updated: ${(order['updatedAt'] as Timestamp).toDate().toString()}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportOrdersToCSV(String sellerId) async {
    // TODO: Implement CSV export logic (can use csv package and file_saver for web/mobile)
    // For now, show a snackbar
    // You can use List<List<String>> rows = ... and convert to CSV string
    // Then save or share the file
    // See: https://pub.dev/packages/csv
    // and https://pub.dev/packages/file_saver
    // For demo:
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export to CSV coming soon!')));
  }

  void _showCreateOrderDialog(BuildContext context, String sellerId) {
    showDialog(
      context: context,
      builder: (context) => _CreateOrderDialog(sellerId: sellerId),
    );
  }

  void _showRateSupplierDialog(BuildContext context, String supplierId, String supplierName) {
    int rating = 5;
    TextEditingController commentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rate $supplierName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StarRating(
              rating: rating,
              onRatingChanged: (val) {
                rating = val;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You must be logged in to rate.')),
                );
                return;
              }
              // Fetch user role and block if not buyer or is supplier
              final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
              final userRole = userDoc.data()?['role'] ?? '';
              if (userRole != 'buyer' || user.uid == supplierId) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Only buyers can rate suppliers.')),
                );
                return;
              }
              // Save rating to Firestore
              final ratingsRef = FirebaseFirestore.instance.collection('supplier_ratings');
              await ratingsRef.add({
                'supplierId': supplierId,
                'buyerId': user.uid,
                'rating': rating,
                'comment': commentController.text.trim(),
                'timestamp': FieldValue.serverTimestamp(),
              });
              // Recalculate average and update supplier_locations
              final query = await ratingsRef.where('supplierId', isEqualTo: supplierId).get();
              double avg = 0;
              if (query.docs.isNotEmpty) {
                double sum = 0;
                for (var doc in query.docs) {
                  sum += (doc['rating'] ?? 0) is int ? (doc['rating'] ?? 0).toDouble() : (doc['rating'] ?? 0);
                }
                avg = sum / query.docs.length;
              }
              // Update supplier_locations
              final locQuery = await FirebaseFirestore.instance
                  .collection('supplier_locations')
                  .where('supplierId', isEqualTo: supplierId)
                  .limit(1)
                  .get();
              if (locQuery.docs.isNotEmpty) {
                await locQuery.docs.first.reference.update({'rating': avg});
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your review!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class _CreateOrderDialog extends StatefulWidget {
  final String sellerId;
  const _CreateOrderDialog({required this.sellerId});
  @override
  State<_CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<_CreateOrderDialog> {
  String? _selectedProductId;
  int _quantity = 1;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Order'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('sellerId', isEqualTo: widget.sellerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No products available.');
              }
              final products = snapshot.data!.docs;
              return DropdownButton<String>(
                value: _selectedProductId,
                hint: const Text('Select Product'),
                isExpanded: true,
                items: products.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return DropdownMenuItem<String>(
                    value: doc.id,
                    child: Text('${data['name']} (Stock: ${data['quantity']})'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedProductId = val);
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Quantity:'),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: '1'),
                  onChanged: (val) {
                    final q = int.tryParse(val);
                    if (q != null && q > 0) setState(() => _quantity = q);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedProductId == null || _quantity <= 0
              ? null
              : () async {
                  final productRef = FirebaseFirestore.instance.collection('products').doc(_selectedProductId);
                  final productSnap = await productRef.get();
                  final product = productSnap.data() as Map<String, dynamic>;
                  final currentStock = product['quantity'] ?? 0;
                  if (_quantity > currentStock) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock.')));
                    return;
                  }
                  // Create order
                  await FirebaseFirestore.instance.collection('orders').add({
                    'productId': _selectedProductId,
                    'productName': product['name'],
                    'productImage': product['imageUrl'],
                    'sellerId': widget.sellerId,
                    'quantity': _quantity,
                    'price': product['price'],
                    'status': 'fulfilled',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  // Decrease stock
                  await productRef.update({'quantity': currentStock - _quantity});
                  Navigator.pop(context);
                },
          child: const Text('Create'),
        ),
      ],
    );
  }
} 