// ignore_for_file: deprecated_member_use, empty_catches, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/supplier-side/add_product_page.dart';
import 'package:vegieconnect/supplier-side/farm_map_page.dart' show SupplierLocationPage;
import '../authentication/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/product_image_widget.dart';
import '../services/image_storage_service.dart';
import '../customer-side/product_details_page.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;
    final green = const Color(0xFFA7C957);
    final bg = const Color(0xFFF6F6F6);
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    final neumorphicShadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: Offset(screenWidth * 0.015, screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
      BoxShadow(
        color: Colors.white,
        offset: Offset(-screenWidth * 0.015, -screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
    ];
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Supplier Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.055),
        ),
        backgroundColor: green,
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
                color: green,
              ),
              child: const Text('Supplier Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Overview'),
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
              title: const Text('Products'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Orders'),
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
              title: const Text('Profile'),
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
              title: const Text('Supplier Location'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupplierLocationPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
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
          _buildOverviewTab(screenWidth, cardRadius, neumorphicShadow),
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: green,
        unselectedItemColor: Colors.grey,
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
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(double screenWidth, BorderRadius cardRadius, List<BoxShadow> neumorphicShadow) {
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
            style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
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
                    return _buildStatCard(screenWidth, cardRadius, neumorphicShadow, 'Total Products', '$count', Icons.inventory, Colors.blue);
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
                    return _buildStatCard(screenWidth, cardRadius, neumorphicShadow, 'Active Orders', '$count', Icons.shopping_cart, Colors.green);
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
                        revenue += (data['price'] ?? 0) is int
                          ? (data['price'] ?? 0).toDouble()
                          : (data['price'] ?? 0);
                      }
                    }
                    return _buildStatCard(screenWidth, cardRadius, neumorphicShadow, 'Revenue', '₱${revenue.toStringAsFixed(2)}', Icons.attach_money, Colors.orange);
                  },
                ),
                // Rating
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
                    return _buildStatCard(screenWidth, cardRadius, neumorphicShadow, 'Rating', avg > 0 ? avg.toStringAsFixed(1) : 'N/A', Icons.star, Colors.purple);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Orders',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Fix: Wrap _buildRecentOrders in SizedBox to prevent overflow
          SizedBox(
            height: 320, // Adjust as needed for your UI
            child: _buildRecentOrders(screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(double screenWidth, BorderRadius cardRadius, List<BoxShadow> neumorphicShadow, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0, // Removed elevation for neumorphic effect
      shape: RoundedRectangleBorder(borderRadius: cardRadius),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: screenWidth * 0.06),
                const Spacer(),
                Icon(Icons.trending_up, color: Colors.green, size: screenWidth * 0.05),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey),
            ),
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
            final status = order['status'] ?? 'pending';
            final statusColor = status == 'Delivered'
                ? Colors.green
                : status == 'Processing'
                    ? Colors.orange
                    : Colors.grey;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFA7C957).withOpacity(0.1),
                child: Text(
                  order['id'] != null && order['id'].toString().isNotEmpty
                      ? order['id'].toString().replaceAll(RegExp(r'[^0-9]'), '')
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFFA7C957),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text('Order #${order['id'] ?? ''}'),
              subtitle: Text('${order['customer'] ?? ''} • ₱${(order['price'] ?? 0).toStringAsFixed(2)}'),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
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
    final screenHeight = MediaQuery.of(context).size.height;
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
                  backgroundColor: const Color(0xFFA7C957),
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
    final screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
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
              child: Card(
                elevation: 0, // Removed elevation for neumorphic effect
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.05)),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.02),
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
                            placeholder: Icon(Icons.shopping_basket, size: screenWidth * 0.08, color: const Color(0xFFA7C957)),
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
                        '₱${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFA7C957),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list),
                label: const Text('Filter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA7C957),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOrderList(),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in.'));
    }
    return StreamBuilder<QuerySnapshot>(
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
        final orders = snapshot.data!.docs;
        // Notification: Show SnackBar if a new order is received
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (orders.isNotEmpty) {
            final now = DateTime.now();
            final createdAt = orders.first['createdAt'];
            if (createdAt != null &&
                createdAt is Timestamp &&
                now.difference(createdAt.toDate()).inSeconds < 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New order received!')),
              );
            }
          }
        });
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            final docId = orders[index].id;
            final status = order['status'] ?? 'pending';
            switch (status) {
              case 'completed':
                break;
              case 'processing':
                break;
              default:
            }
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFA7C957).withOpacity(0.1),
                child: Text(
                  order['productName'] != null && order['productName'].isNotEmpty
                      ? order['productName'][0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFFA7C957),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(order['productName'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buyer: ${order['buyerId'] ?? ''}'),
                  Text('Qty: ${order['quantity']} ${order['unit']}'),
                  Text('₱${order['price']?.toStringAsFixed(2) ?? '0.00'}'),
                  Text('Status: $status'),
                ],
              ),
              trailing: DropdownButton<String>(
                value: ['pending', 'processing', 'completed', 'cancelled'].contains(status) ? status : 'pending',
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'processing', child: Text('Processing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (val) async {
                  if (val != null && val != status) {
                    await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': val});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order status updated to $val.')),
                    );
                  }
                },
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Order Details'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Product: ${order['productName'] ?? ''}'),
                        Text('Quantity: ${order['quantity']} ${order['unit']}'),
                        Text('Price: ₱${order['price']?.toStringAsFixed(2) ?? '0.00'}'),
                        Text('Status: $status'),
                        if (order['createdAt'] != null)
                          Text('Ordered: ${order['createdAt'].toDate()}'),
                        if (order['buyerId'] != null)
                          Text('Buyer ID: ${order['buyerId']}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
              Card(
                elevation: 0, // Removed elevation for neumorphic effect
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.05)),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: screenWidth * 0.125,
                        backgroundColor: const Color(0xFFA7C957).withOpacity(0.1),
                        child: const Icon(
                          Icons.store,
                          size: 50,
                          color: Color(0xFFA7C957),
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
                      const SizedBox(height: 20),
                      // Farm location info
                      FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('farm_locations')
                            .where('supplierId', isEqualTo: user.uid)
                            .where('isActive', isEqualTo: true)
                            .limit(1)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text(
                              'No farm location set.',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            );
                          }
                          final farm = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 32),
                              Row(
                                children: const [
                                  Icon(Icons.location_on, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text('Farm Location', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                farm['name'] ?? 'Unnamed Farm',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Lat: 9${(farm['latitude'] ?? 0.0).toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              Text(
                                'Lng: 9${(farm['longitude'] ?? 0.0).toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0, // Removed elevation for neumorphic effect
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.05)),
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
                        activeColor: const Color(0xFFA7C957),
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