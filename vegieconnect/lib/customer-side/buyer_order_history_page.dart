// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerOrderHistoryPage extends StatelessWidget {
  const BuyerOrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
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
              separatorBuilder: (context, index) => const Divider(height: 1),
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
                  default:
                    statusColor = Colors.grey;
                }
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: green.withOpacity(0.1),
                    child: Text(
                      order['productName'] != null && order['productName'].isNotEmpty
                          ? order['productName'][0].toUpperCase()
                          : '?',
                      style: TextStyle(color: green, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(order['productName'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Qty: ${order['quantity']} ${order['unit']}'),
                      Text('₱${order['price']?.toStringAsFixed(2) ?? '0.00'}'),
                      Text('Status: $status'),
                      Text('Payment: ${order['paymentMethod'] == 'cash_on_pickup' ? 'Cash on Pick Up' : (order['paymentMethod'] ?? 'N/A')}'),
                      Text('Payment Status: ${order['paymentStatus'] ?? 'N/A'}'),
                      if (status != 'completed' && status != 'cancelled')
                        TextButton.icon(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
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
                );
              },
            );
          },
        ),
      ),
    );
  }
} 