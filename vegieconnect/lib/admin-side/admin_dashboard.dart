// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/theme.dart';
import '../authentication/login_page.dart';
import 'admin_farm_map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_verify_listings_page.dart';
import 'admin_reports_page.dart';
import 'admin_manage_accounts_page.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  String? _roleFilter; // e.g., 'Supplier', 'Customer', 'Admin'
  String? _statusFilter; // e.g., 'Active', 'Pending', 'Suspended'
  bool _isOnline = true;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _initializeConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isOnline = result != ConnectivityResult.none;
      });
      
      if (!_isOnline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Network connection lost. Auto-approval may be delayed.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Network connection restored.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _createTestProduct() async {
    try {
      final testProduct = {
        'name': 'Test Product - ${DateTime.now().millisecondsSinceEpoch}',
        'description': 'This is a test product for auto-approval testing',
        'price': 50.0,
        'quantity': 10,
        'unit': 'kg',
        'category': 'Vegetables',
        'sellerId': 'test-supplier-id',
        'supplierName': 'Test Supplier',
        'status': 'pending',
        'isVerified': false,
        'isActive': false,
        'contentFlagged': false,
        'autoApproved': false,
        'autoApprovalScheduled': true,
        'autoApprovalCompleted': false,
        'autoApprovalFailed': false,
        'scheduledApprovalTime': DateTime.now().add(Duration(minutes: 1)).toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('products').add(testProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test product created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating test product: $e')),
      );
    }
  }

  Future<void> _testFirestoreConnection() async {
    try {
      debugPrint('🔍 Testing Firestore connection...');
      
      // Test read access
      final testDoc = await FirebaseFirestore.instance.collection('products').limit(1).get();
      debugPrint('✅ Firestore read test successful: ${testDoc.docs.length} documents found');
      
      // Test write access
      final testWrite = await FirebaseFirestore.instance.collection('test').add({
        'timestamp': FieldValue.serverTimestamp(),
        'test': true,
      });
      debugPrint('✅ Firestore write test successful: ${testWrite.id}');
      
      // Clean up test document
      await testWrite.delete();
      debugPrint('✅ Firestore cleanup successful');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firestore connection test successful')),
      );
    } catch (e) {
      debugPrint('💥 Firestore connection test failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore connection test failed: $e')),
      );
    }
  }

 

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Admin Dashboard',
                style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _isOnline ? Colors.green : Colors.red),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isOnline ? Icons.wifi : Icons.wifi_off,
                    color: _isOnline ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _isOnline ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
         
          IconButton(
            icon: const Icon(Icons.cloud),
            onPressed: _testFirestoreConnection,
            tooltip: 'Test Firestore Connection',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTestProduct,
            tooltip: 'Create Test Product',
          ),
         
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
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
              child: Text('Admin Menu', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 24)),
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
              leading: const Icon(Icons.people),
              title: Text('Users', style: AppTextStyles.body),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: Text('Analytics', style: AppTextStyles.body),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text('Farm Locations', style: AppTextStyles.body),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified),
              title: Text('Verify Listings', style: AppTextStyles.body),
              selected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminVerifyListingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: Text('Reports', style: AppTextStyles.body),
              selected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminReportsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: Text('Manage Accounts', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminManageAccountsPage()),
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
                // ignore: use_build_context_synchronously
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
          _buildUsersTab(),
          _buildAnalyticsTab(),
          _buildFarmLocationsTab(),
          // New admin pages
          AdminVerifyListingsPage(),
          AdminReportsPage(),
          AdminManageAccountsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primaryGreen,
        unselectedItemColor: AppColors.textSecondary,
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
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Farms',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(double screenWidth, BorderRadius cardRadius) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Overview',
            style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.06),
          ),
          SizedBox(height: screenWidth * 0.05),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: screenWidth * 0.04,
            mainAxisSpacing: screenWidth * 0.04,
            childAspectRatio: 1.5,
            children: [
              // Total Users (suppliers and buyers only)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', whereIn: ['Supplier', 'Buyer'])
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildStatCard(screenWidth, cardRadius, 'Total Users', '$count', Icons.people, Colors.blue);
                },
              ),
              // Total Products
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildStatCard(screenWidth, cardRadius, 'Total Products', '$count', Icons.inventory, Colors.green);
                },
              ),
              // Total Orders
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return _buildStatCard(screenWidth, cardRadius, 'Total Orders', '$count', Icons.shopping_cart, Colors.orange);
                },
              ),
              // Revenue
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
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
                  return _buildStatCard(screenWidth, cardRadius, 'Total Revenue', '\u20b1${revenue.toStringAsFixed(2)}', Icons.attach_money, Colors.green);
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

  Widget _buildRecentActivityList() {
    // Fetch and merge latest activities from users and orders collections (no flicker)
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchRecentActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return const Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Error loading activity.')),
            ),
          );
        }
        final activities = snapshot.data ?? [];
        if (activities.isEmpty) {
          return const Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No recent activity.')),
            ),
          );
        }
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = activities[index];
              final isUser = activity['type'] == 'user';
              final time = activity['time'] is Timestamp ? (activity['time'] as Timestamp).toDate() : DateTime.now();
              final now = DateTime.now();
              final diff = now.difference(time);
              String timeAgo;
              if (diff.inMinutes < 1) {
                timeAgo = 'just now';
              } else if (diff.inMinutes < 60) {
                timeAgo = '${diff.inMinutes} minutes ago';
              } else if (diff.inHours < 24) {
                timeAgo = '${diff.inHours} hours ago';
              } else {
                timeAgo = '${diff.inDays} days ago';
              }
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFA7C957).withOpacity(0.1),
                  child: Icon(
                    isUser ? Icons.person : Icons.shopping_cart,
                    color: const Color(0xFFA7C957),
                    size: 20,
                  ),
                ),
                title: Text(activity['action']),
                subtitle: Text(activity['user']),
                trailing: Text(
                  timeAgo,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchRecentActivities() async {
    // Fetch latest 5 user registrations and order completions
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();
    final orderSnap = await FirebaseFirestore.instance
        .collection('orders')
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .limit(3)
        .get();
    List<Map<String, dynamic>> activities = [];
    for (var doc in userSnap.docs) {
      final data = doc.data();
      activities.add({
        'type': 'user',
        'action': 'New user registered',
        'user': data['email'] ?? '',
        'time': data['createdAt'],
      });
    }
    for (var doc in orderSnap.docs) {
      final data = doc.data();
      activities.add({
        'type': 'order',
        'action': 'Order completed',
        'user': 'Order #${doc.id}',
        'time': data['createdAt'],
      });
    }
    // Sort by time descending
    activities.sort((a, b) {
      final aTime = a['time'] is Timestamp ? (a['time'] as Timestamp).toDate() : DateTime.now();
      final bTime = b['time'] is Timestamp ? (b['time'] as Timestamp).toDate() : DateTime.now();
      return bTime.compareTo(aTime);
    });
    // Limit to 5
    activities = activities.take(5).toList();
    debugPrint('DEBUG: Recent Activities: ${activities.map((a) => a.toString()).join(', ')}');
    return activities;
  }

  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter',
                onSelected: (value) {
                  if (['Supplier', 'Customer', 'Admin'].contains(value)) {
                    setState(() => _roleFilter = value);
                  } else if (['Active', 'Pending', 'Suspended'].contains(value)) {
                    setState(() => _statusFilter = value);
                  } else if (value == 'Clear') {
                    setState(() {
                      _roleFilter = null;
                      _statusFilter = null;
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Supplier', child: Text('Supplier')),
                  const PopupMenuItem(value: 'Customer', child: Text('Customer')),
                  const PopupMenuItem(value: 'Admin', child: Text('Admin')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'Active', child: Text('Active')),
                  const PopupMenuItem(value: 'Pending', child: Text('Pending')),
                  const PopupMenuItem(value: 'Suspended', child: Text('Suspended')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'Clear', child: Text('Clear Filters')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_roleFilter != null || _statusFilter != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  if (_roleFilter != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(_roleFilter!, style: const TextStyle(color: Colors.blue)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _roleFilter = null),
                            child: const Icon(Icons.close, size: 14, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  if (_statusFilter != null)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(_statusFilter!, style: const TextStyle(color: Colors.orange)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => setState(() => _statusFilter = null),
                            child: const Icon(Icons.close, size: 14, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: _buildUserList(
              searchQuery: _searchQuery,
              roleFilter: _roleFilter,
              statusFilter: _statusFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList({String searchQuery = '', String? roleFilter, String? statusFilter}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        final allUsers = snapshot.data!.docs;
        // Apply search and filter
        final users = allUsers.where((doc) {
          final user = doc.data() as Map<String, dynamic>;
          final name = (user['name'] ?? '').toString().toLowerCase();
          final email = (user['email'] ?? '').toString().toLowerCase();
          final role = (user['role'] ?? '').toString();
          final status = (user['status'] ?? '').toString();
          final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery) || email.contains(searchQuery);
          final matchesRole = roleFilter == null || roleFilter == '' || role == roleFilter;
          final matchesStatus = statusFilter == null || statusFilter == '' || status == statusFilter;
          return matchesSearch && matchesRole && matchesStatus;
        }).toList();
        if (users.isEmpty) {
          return const Center(child: Text('No users found.'));
        }
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final docId = users[index].id;
            final isActive = user['status'] == 'Active';
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFA7C957).withOpacity(0.1),
                child: Text(
                  (user['name'] ?? '?').substring(0, 1),
                  style: const TextStyle(
                    color: Color(0xFFA7C957),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(user['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['email'] ?? ''),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user['role'] == 'Supplier' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['role'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: user['role'] == 'Supplier' ? Colors.blue : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['status'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: isActive ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: isActive ? 'suspend' : 'activate',
                    child: Row(
                      children: [
                        Icon(isActive ? Icons.block : Icons.check),
                        const SizedBox(width: 8),
                        Text(isActive ? 'Suspend' : 'Activate'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  if (value == 'suspend' || value == 'activate') {
                    await FirebaseFirestore.instance.collection('users').doc(docId).update({
                      'status': value == 'suspend' ? 'Suspended' : 'Active',
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User ${value == 'suspend' ? 'suspended' : 'activated'} successfully.')),
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete User'),
                        content: const Text('Are you sure you want to delete this user? This action cannot be undone.'),
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
                      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User deleted.')),
                      );
                    }
                  } else if (value == 'edit') {
                    // TODO: Implement edit user logic (show dialog or navigate to edit page)
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Revenue Overview (real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').snapshots(),
            builder: (context, orderSnap) {
              if (orderSnap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final now = DateTime.now();
              final firstDayThisMonth = DateTime(now.year, now.month, 1);
              final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
              final firstDayThisYear = DateTime(now.year, 1, 1);
              final firstDayLastYear = DateTime(now.year - 1, 1, 1);
              double thisMonth = 0, lastMonth = 0, thisYear = 0, lastYear = 0;
              if (orderSnap.hasData) {
                for (var doc in orderSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final amount = (data['price'] ?? 0) * (data['quantity'] ?? 1);
                  if (createdAt == null) continue;
                  if (createdAt.isAfter(firstDayThisMonth)) thisMonth += amount;
                  if (createdAt.isAfter(firstDayLastMonth) && createdAt.isBefore(firstDayThisMonth)) lastMonth += amount;
                  if (createdAt.isAfter(firstDayThisYear)) thisYear += amount;
                  if (createdAt.isAfter(firstDayLastYear) && createdAt.isBefore(firstDayThisYear)) lastYear += amount;
                }
              }
              double percentMonth = lastMonth > 0 ? ((thisMonth - lastMonth) / lastMonth) * 100 : 0;
              double percentYear = lastYear > 0 ? ((thisYear - lastYear) / lastYear) * 100 : 0;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Revenue Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsItem('This Month', '₱${thisMonth.toStringAsFixed(0)}', '${percentMonth >= 0 ? '+' : ''}${percentMonth.toStringAsFixed(0)}%'),
                          ),
                          Expanded(
                            child: _buildAnalyticsItem('Last Month', '₱${lastMonth.toStringAsFixed(0)}', ''),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsItem('This Year', '₱${thisYear.toStringAsFixed(0)}', '${percentYear >= 0 ? '+' : ''}${percentYear.toStringAsFixed(0)}%'),
                          ),
                          Expanded(
                            child: _buildAnalyticsItem('Last Year', '₱${lastYear.toStringAsFixed(0)}', ''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // User Growth (real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final now = DateTime.now();
              final firstDayThisMonth = DateTime(now.year, now.month, 1);
              int newUsers = 0, activeUsers = 0;
              if (userSnap.hasData) {
                for (var doc in userSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final lastActive = (data['lastLogin'] as Timestamp?)?.toDate();
                  if (createdAt != null && createdAt.isAfter(firstDayThisMonth)) newUsers++;
                  if (lastActive != null && lastActive.isAfter(firstDayThisMonth)) activeUsers++;
                }
              }
              // For demo, percent changes are not calculated (can be added if needed)
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User Growth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsItem('New Users', newUsers.toString(), ''),
                          ),
                          Expanded(
                            child: _buildAnalyticsItem('Active Users', activeUsers.toString(), ''),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Order Counts (real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, orderSnap) {
              if (orderSnap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final now = DateTime.now();
              final firstDayThisMonth = DateTime(now.year, now.month, 1);
              final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
              int totalOrders = 0, thisMonthOrders = 0, lastMonthOrders = 0;
              double totalOrderValue = 0;
              int totalOrderProducts = 0;
              if (orderSnap.hasData) {
                for (var doc in orderSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final value = (data['price'] ?? 0) * (data['quantity'] ?? 1);
                  final quantity = (data['quantity'] ?? 1) as int;
                  totalOrders++;
                  totalOrderValue += value;
                  totalOrderProducts += quantity;
                  if (createdAt != null) {
                    if (createdAt.isAfter(firstDayThisMonth)) thisMonthOrders++;
                    if (createdAt.isAfter(firstDayLastMonth) && createdAt.isBefore(firstDayThisMonth)) lastMonthOrders++;
                  }
                }
              }
              double avgOrderValue = totalOrders > 0 ? totalOrderValue / totalOrders : 0;
              double avgProductsPerOrder = totalOrders > 0 ? totalOrderProducts / totalOrders : 0;
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildAnalyticsItem('Total Orders', totalOrders.toString(), '')),
                          Expanded(child: _buildAnalyticsItem('This Month', thisMonthOrders.toString(), '')),
                          Expanded(child: _buildAnalyticsItem('Last Month', lastMonthOrders.toString(), '')),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildAnalyticsItem('Avg Order Value', '₱${avgOrderValue.toStringAsFixed(0)}', '')),
                          Expanded(child: _buildAnalyticsItem('Avg Products/Order', avgProductsPerOrder.toStringAsFixed(2), '')),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Top Products (real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, productSnap) {
              if (productSnap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              // Aggregate top products by total quantity sold (from orders)
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').snapshots(),
                builder: (context, orderSnap) {
                  if (orderSnap.connectionState == ConnectionState.waiting) {
                    return const SizedBox();
                  }
                  // Map productId to total quantity sold
                  final Map<String, int> productSales = {};
                  if (orderSnap.hasData) {
                    for (var doc in orderSnap.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final productId = data['productId'] ?? '';
                      final quantity = (data['quantity'] ?? 1) as int;
                      if (productId is String && productId.isNotEmpty) {
                        productSales[productId] = (productSales[productId] ?? 0) + quantity;
                      }
                    }
                  }
                  // Get product details
                  final products = productSnap.data?.docs ?? [];
                  final topProducts = products
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final id = doc.id;
                        return {
                          'id': id,
                          'name': data['name'] ?? '',
                          'imageUrl': data['imageUrl'] ?? '',
                          'quantitySold': productSales[id] ?? 0,
                        };
                      })
                      .where((p) => p['quantitySold'] > 0)
                      .toList();
                  topProducts.sort((a, b) => (b['quantitySold'] as int).compareTo(a['quantitySold'] as int));
                  final top5 = topProducts.take(5).toList();
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Top 5 Products (by sales)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          if (top5.isEmpty)
                            const Text('No product sales yet.'),
                          for (var p in top5)
                            ListTile(
                              leading: p['imageUrl'] != null && (p['imageUrl'] as String).isNotEmpty
                                  ? Image.network(p['imageUrl'], width: 40, height: 40, fit: BoxFit.cover)
                                  : const Icon(Icons.shopping_basket, size: 40),
                              title: Text(p['name'] ?? ''),
                              trailing: Text('Sold: ${p['quantitySold']}'),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          // Sales by Category (real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').snapshots(),
            builder: (context, orderSnap) {
              if (orderSnap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              // Aggregate sales by category
              final Map<String, double> categorySales = {};
              if (orderSnap.hasData) {
                for (var doc in orderSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final category = data['category'] ?? 'Uncategorized';
                  final amount = (data['price'] ?? 0) * (data['quantity'] ?? 1);
                  categorySales[category] = (categorySales[category] ?? 0) + amount;
                }
              }
              final sortedCategories = categorySales.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sales by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      if (sortedCategories.isEmpty)
                        const Text('No sales data.'),
                      if (sortedCategories.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              barGroups: [
                                for (int i = 0; i < sortedCategories.length; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: sortedCategories[i].value,
                                        color: Colors.blue,
                                      ),
                                    ],
                                  ),
                              ],
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= sortedCategories.length) return const SizedBox();
                                      return Text(sortedCategories[idx].key, style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Top Suppliers by Sales (real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').snapshots(),
            builder: (context, orderSnap) {
              if (orderSnap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final Map<String, double> supplierSales = {};
              final Map<String, String> supplierNames = {};
              if (orderSnap.hasData) {
                for (var doc in orderSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final supplierId = data['sellerId'] ?? '';
                  final supplierName = data['supplierName'] ?? 'Unknown';
                  final amount = (data['price'] ?? 0) * (data['quantity'] ?? 1);
                  supplierSales[supplierId] = (supplierSales[supplierId] ?? 0) + amount;
                  supplierNames[supplierId] = supplierName;
                }
              }
              final topSuppliers = supplierSales.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final top5 = topSuppliers.take(5).toList();
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top 5 Suppliers (by sales)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      if (top5.isEmpty)
                        const Text('No supplier sales yet.'),
                      for (var entry in top5)
                        ListTile(
                          title: Text(supplierNames[entry.key] ?? 'Unknown'),
                          trailing: Text('₱${entry.value.toStringAsFixed(0)}'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Customer Lifetime Value (CLV) for Top 5 Buyers (real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').snapshots(),
            builder: (context, orderSnap) {
              if (orderSnap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final Map<String, double> buyerCLV = {};
              final Map<String, String> buyerNames = {};
              if (orderSnap.hasData) {
                for (var doc in orderSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final buyerId = data['buyerId'] ?? '';
                  final buyerName = data['buyerName'] ?? 'Unknown';
                  final amount = (data['price'] ?? 0) * (data['quantity'] ?? 1);
                  buyerCLV[buyerId] = (buyerCLV[buyerId] ?? 0) + amount;
                  buyerNames[buyerId] = buyerName;
                }
              }
              final topBuyers = buyerCLV.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final top5 = topBuyers.take(5).toList();
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top 5 Buyers (Customer Lifetime Value)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      if (top5.isEmpty)
                        const Text('No buyer data yet.'),
                      for (var entry in top5)
                        ListTile(
                          title: Text(buyerNames[entry.key] ?? 'Unknown'),
                          trailing: Text('₱${entry.value.toStringAsFixed(0)}'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Conversion Rate (orders/total users, real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').snapshots(),
            builder: (context, orderSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, userSnap) {
                  if (orderSnap.connectionState == ConnectionState.waiting || userSnap.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  final totalOrders = orderSnap.data?.docs.length ?? 0;
                  final totalUsers = userSnap.data?.docs.length ?? 0;
                  final conversionRate = totalUsers > 0 ? (totalOrders / totalUsers) * 100 : 0;
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Conversion Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Text('Orders: $totalOrders'),
                          Text('Users: $totalUsers'),
                          const SizedBox(height: 8),
                          Text('Conversion Rate: ${conversionRate.toStringAsFixed(2)}%'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),
          // Daily/Weekly Sales Trend (last 7/30 days, real-time)
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('orders').where('status', isEqualTo: 'completed').snapshots(),
            builder: (context, orderSnap) {
              if (orderSnap.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              final now = DateTime.now();
              final last7Days = List.generate(7, (i) => now.subtract(Duration(days: i)));
              final last30Days = List.generate(30, (i) => now.subtract(Duration(days: i)));
              final Map<String, double> dailySales = {};
              final Map<String, double> weeklySales = {};
              if (orderSnap.hasData) {
                for (var doc in orderSnap.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  final amount = (data['price'] ?? 0) * (data['quantity'] ?? 1);
                  if (createdAt == null) continue;
                  final dayKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
                  if (now.difference(createdAt).inDays < 7) {
                    dailySales[dayKey] = (dailySales[dayKey] ?? 0) + amount;
                  }
                  if (now.difference(createdAt).inDays < 30) {
                    final weekKey = 'Week ${((now.difference(createdAt).inDays) ~/ 7) + 1}';
                    weeklySales[weekKey] = (weeklySales[weekKey] ?? 0) + amount;
                  }
                }
              }
              final sortedDaily = dailySales.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));
              final sortedWeekly = weeklySales.entries.toList()
                ..sort((a, b) => a.key.compareTo(b.key));
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sales Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      const Text('Last 7 Days:'),
                      for (var entry in sortedDaily)
                        Text('${entry.key}: ₱${entry.value.toStringAsFixed(0)}'),
                      const SizedBox(height: 12),
                      const Text('Last 30 Days (by week):'),
                      for (var entry in sortedWeekly)
                        Text('${entry.key}: ₱${entry.value.toStringAsFixed(0)}'),
                      if (sortedDaily.isNotEmpty)
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: true),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= sortedDaily.length) return const SizedBox();
                                      return Text(sortedDaily[idx].key.substring(5)); // MM-DD
                                    },
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (int i = 0; i < sortedDaily.length; i++)
                                      FlSpot(i.toDouble(), sortedDaily[i].value),
                                  ],
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                  dotData: FlDotData(show: false),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(String label, String value, String change) {
    final isPositive = change.startsWith('+');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              change,
              style: TextStyle(
                fontSize: 12,
                color: isPositive ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmLocationsTab() {
    return const AdminFarmMapPage();
  }
} 