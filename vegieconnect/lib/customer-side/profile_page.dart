import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final green = const Color(0xFFA7C957);
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
        return Scaffold(
          backgroundColor: const Color(0xFFF6F6F6),
          appBar: AppBar(
            backgroundColor: green,
            title: const Text('Profile'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 48, color: Colors.black38),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${data['name'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Email: ${data['email'] ?? ''}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Role: ${data['role'] ?? ''}', style: const TextStyle(fontSize: 16)),
                    // Add more fields as needed
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Order History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('buyerId', isEqualTo: user!.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return ListTile(
                      leading: Icon(Icons.receipt_long, color: green),
                      title: const Text('No orders yet.'),
                    );
                  }
                  final orders = snapshot.data!.docs;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                          leading: Icon(Icons.receipt_long, color: green, size: screenWidth * 0.09),
                          title: Text(order['productName'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Qty: ${order['quantity']} ${order['unit']}', style: TextStyle(fontSize: screenWidth * 0.04)),
                              Text('₱${order['price']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontSize: screenWidth * 0.04)),
                              Text('Status: $status', style: TextStyle(color: statusColor, fontSize: screenWidth * 0.04)),
                              Text('Payment: ${order['paymentMethod'] == 'cash_on_pickup' ? 'Cash on Pick Up' : (order['paymentMethod'] ?? 'N/A')}', style: TextStyle(fontSize: screenWidth * 0.038)),
                              Text('Payment Status: ${order['paymentStatus'] ?? 'N/A'}', style: TextStyle(fontSize: screenWidth * 0.038)),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.015),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(screenWidth * 0.04),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: screenWidth * 0.04, color: statusColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                  child: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 