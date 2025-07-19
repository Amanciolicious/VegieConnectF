// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class BuyerOrderHistoryPage extends StatefulWidget {
  const BuyerOrderHistoryPage({super.key});

  @override
  State<BuyerOrderHistoryPage> createState() => _BuyerOrderHistoryPageState();
}

class _BuyerOrderHistoryPageState extends State<BuyerOrderHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Pending', 'Processing', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Order History', style: AppTextStyles.headline.copyWith(color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('buyerId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No orders yet.', style: AppTextStyles.body));
                }
                final orders = snapshot.data!.docs.where((doc) {
                  if (tab == 'All') return true;
                  final status = (doc['status'] ?? '').toString().toLowerCase();
                  return status == tab.toLowerCase();
                }).toList();
                if (orders.isEmpty) {
                  return Center(child: Text('No orders in this category.', style: AppTextStyles.body));
                }
                return ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => SizedBox(height: screenWidth * 0.02),
                  itemBuilder: (context, index) {
                    final order = orders[index].data() as Map<String, dynamic>;
                    final status = order['status'] ?? 'pending';
                    Color statusColor;
                    switch (status) {
                      case 'delivered':
                        statusColor = AppColors.primaryGreen;
                        break;
                      case 'processing':
                        statusColor = Colors.orange;
                        break;
                      case 'cancelled':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }
                    return Neumorphic(
                      style: AppNeumorphic.card,
                      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.03),
                        leading: order['productImage'] != null && order['productImage'].toString().isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                order['productImage'],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            )
                          : CircleAvatar(
                              backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                              child: Text(
                                order['productName'] != null && order['productName'].isNotEmpty
                                    ? order['productName'][0].toUpperCase()
                                    : '?',
                                style: AppTextStyles.body.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
                              ),
                            ),
                        title: Text(order['productName'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Qty: ${order['quantity']} ${order['unit']}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
                            Text('\u20b1${order['price']?.toStringAsFixed(2) ?? '0.00'}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
                            Text('Status: $status', style: AppTextStyles.body.copyWith(color: statusColor, fontSize: screenWidth * 0.04)),
                            Text('Payment: ${order['paymentMethod'] == 'cash_on_pickup' ? 'Cash on Pick Up' : (order['paymentMethod'] ?? 'N/A')}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.038)),
                            Text('Payment Status: ${order['paymentStatus'] ?? 'N/A'}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.038)),
                            if (status != 'delivered' && status != 'cancelled')
                              TextButton.icon(
                                icon: Icon(Icons.cancel, color: Colors.red, size: screenWidth * 0.05),
                                label: Text('Cancel Order', style: AppTextStyles.body.copyWith(color: Colors.red, fontSize: screenWidth * 0.04)),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Cancel Order'),
                                      content: const Text('Are you sure you want to cancel this order?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('No'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Yes, Cancel'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('orders')
                                          .doc(orders[index].id)
                                          .update({'status': 'cancelled', 'updatedAt': FieldValue.serverTimestamp()});
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Order cancelled.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to cancel order: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: AppTextStyles.body.copyWith(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                          ),
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
                                  Text('Price: \u20b1${order['price']?.toStringAsFixed(2) ?? '0.00'}'),
                                  Text('Status: $status'),
                                  if (order['createdAt'] != null)
                                    Text('Ordered: ${order['createdAt'].toDate()}'),
                                  if (order['sellerId'] != null)
                                    Text('Seller ID: ${order['sellerId']}'),
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
                      ),
                    );
                  },
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
} 