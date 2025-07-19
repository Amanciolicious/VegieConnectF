// ignore_for_file: deprecated_member_use
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/theme.dart';
import '../authentication/login_page.dart';
import 'admin_farm_map_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_verify_listings_page.dart';
import 'admin_reports_page.dart';
import 'admin_manage_accounts_page.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
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
              selected: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminManageAccountsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('Settings', style: AppTextStyles.body),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
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
          _buildSettingsTab(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
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
    return SingleChildScrollView(
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
          _buildUserList(),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final users = [
            {'name': 'John Doe', 'email': 'john.doe@email.com', 'role': 'Customer', 'status': 'Active'},
            {'name': 'Jane Smith', 'email': 'jane.smith@email.com', 'role': 'Supplier', 'status': 'Active'},
            {'name': 'Bob Johnson', 'email': 'bob.johnson@email.com', 'role': 'Customer', 'status': 'Pending'},
            {'name': 'Alice Brown', 'email': 'alice.brown@email.com', 'role': 'Supplier', 'status': 'Active'},
            {'name': 'Charlie Wilson', 'email': 'charlie.wilson@email.com', 'role': 'Customer', 'status': 'Active'},
            {'name': 'Diana Davis', 'email': 'diana.davis@email.com', 'role': 'Supplier', 'status': 'Suspended'},
            {'name': 'Edward Miller', 'email': 'edward.miller@email.com', 'role': 'Customer', 'status': 'Active'},
            {'name': 'Fiona Garcia', 'email': 'fiona.garcia@email.com', 'role': 'Supplier', 'status': 'Active'},
            {'name': 'George Martinez', 'email': 'george.martinez@email.com', 'role': 'Customer', 'status': 'Active'},
            {'name': 'Helen Taylor', 'email': 'helen.taylor@email.com', 'role': 'Supplier', 'status': 'Active'},
          ];
          
          final user = users[index];
          final isActive = user['status'] == 'Active';
          
          return ListTile(
            leading: CircleAvatar(
  
              backgroundColor: const Color(0xFFA7C957).withOpacity(0.1),
              child: Text(
                user['name']!.substring(0, 1),
                style: const TextStyle(
                  color: Color(0xFFA7C957),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(user['name']!),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email']!),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
             
                        color: user['role'] == 'Supplier' ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        user['role']!,
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
                        user['status']!,
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
                const PopupMenuItem(
                  value: 'suspend',
                  child: Row(
                    children: [
                      Icon(Icons.block),
                      SizedBox(width: 8),
                      Text('Suspend'),
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
              onSelected: (value) {
                // Handle menu selection
              },
            ),
          );
        },
      ),
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
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsItem('This Month', '\$8,234', '+12%'),
                      ),
                      Expanded(
                        child: _buildAnalyticsItem('Last Month', '\$7,345', '+8%'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsItem('This Year', '\$89,123', '+23%'),
                      ),
                      Expanded(
                        child: _buildAnalyticsItem('Last Year', '\$72,456', '+15%'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'User Growth',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsItem('New Users', '234', '+18%'),
                      ),
                      Expanded(
                        child: _buildAnalyticsItem('Active Users', '1,123', '+5%'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmLocationsTab() {
    return const AdminFarmMapPage();
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

  Widget _buildSettingsTab() {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name: ${data['name'] ?? ''}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${data['email'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Role: ${data['role'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Push Notifications'),
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
                title: const Text('Security Settings'),
                subtitle: const Text('Password and authentication'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup & Restore'),
                subtitle: const Text('Data backup settings'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: const Text('English'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('About'),
                subtitle: const Text('App version and information'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }
} 