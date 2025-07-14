// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerOrderHistoryPage extends StatelessWidget {
  const BuyerOrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final user = FirebaseAuth.instance.currentUser;
    final green = const Color(0xFFA7C957);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: green,
        title: const Text('Order History'),
      ),
      body: Padding(
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
              return const Center(child: Text('No orders yet.'));
            }
            final orders = snapshot.data!.docs;
            // Notification: Show SnackBar if any order status changes
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (orders.isNotEmpty) {
                for (final doc in orders) {
                  final order = doc.data() as Map<String, dynamic>;
                  final status = order['status'] ?? 'pending';
                  final updatedAt = order['updatedAt'] ?? order['createdAt'];
                  if (updatedAt != null &&
                      updatedAt is Timestamp &&
                      DateTime.now().difference(updatedAt.toDate()).inSeconds < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order status updated to $status!')),
                    );
                    break;
                  }
                }
              }
            });
            return ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (context, index) => SizedBox(height: screenWidth * 0.02),
              itemBuilder: (context, index) {
                final order = orders[index].data() as Map<String, dynamic>;
                final status = order['status'] ?? 'pending';
                Color statusColor;
                switch (status) {
                  case 'completed':
                    statusColor = Colors.green;
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
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    boxShadow: [
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
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.03),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFA7C957).withOpacity(0.1),
                      child: Text(
                        order['productName'] != null && order['productName'].isNotEmpty
                            ? order['productName'][0].toUpperCase()
                            : '?',
                        style: TextStyle(color: const Color(0xFFA7C957), fontWeight: FontWeight.bold, fontSize: screenWidth * 0.05),
                      ),
                    ),
                    title: Text(order['productName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Qty: ${order['quantity']} ${order['unit']}', style: TextStyle(fontSize: screenWidth * 0.04)),
                        Text('₱${order['price']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontSize: screenWidth * 0.04)),
                        Text('Status: $status', style: TextStyle(color: statusColor, fontSize: screenWidth * 0.04)),
                        Text('Payment: ${order['paymentMethod'] == 'cash_on_pickup' ? 'Cash on Pick Up' : (order['paymentMethod'] ?? 'N/A')}', style: TextStyle(fontSize: screenWidth * 0.038)),
                        Text('Payment Status: ${order['paymentStatus'] ?? 'N/A'}', style: TextStyle(fontSize: screenWidth * 0.038)),
                        if (status != 'completed' && status != 'cancelled')
                          TextButton.icon(
                            icon: Icon(Icons.cancel, color: Colors.red, size: screenWidth * 0.05),
                            label: Text('Cancel Order', style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.04)),
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
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
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
                              Text('Price: ₱${order['price']?.toStringAsFixed(2) ?? '0.00'}'),
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
      ),
    );
  }
} 