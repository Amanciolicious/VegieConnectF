import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DigitalReceiptPage extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> cartItems;
  final double total;
  const DigitalReceiptPage({super.key, required this.cartItems, required this.total});

  String _generateOrderNumber() {
    final rand = Random();
    return 'VC${rand.nextInt(99999999).toString().padLeft(8, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final orderNumber = _generateOrderNumber();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    final paymentMethod = 'Cash on Pick Up';
    final subtotal = total;
    final shipping = 0.0;
    final orderStatus = 'Order Placed';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text('Order Summary', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: screenWidth * 0.18, color: AppColors.primaryGreen),
                    SizedBox(height: screenWidth * 0.02),
                    Text('Thank you for your purchase!', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.055)),
                    SizedBox(height: screenWidth * 0.01),
                    Text('Your order has been placed successfully.', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
                  ],
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Card(
                margin: EdgeInsets.only(bottom: screenWidth * 0.04),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Status:', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                          Text(orderStatus, style: AppTextStyles.body.copyWith(color: AppColors.primaryGreen)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order No.:', style: AppTextStyles.body),
                          Text(orderNumber, style: AppTextStyles.body),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order Date:', style: AppTextStyles.body),
                          Text(dateStr, style: AppTextStyles.body),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Text('Items', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.045)),
              SizedBox(height: 8),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  separatorBuilder: (context, i) => Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = cartItems[i].data();
                    return ListTile(
                      leading: item['imageUrl'] != null
                          ? Image.network(item['imageUrl'], width: 48, height: 48, fit: BoxFit.cover)
                          : Icon(Icons.image, size: 48, color: AppColors.primaryGreen),
                      title: Text(item['name'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('₱${item['price']} x ${item['quantity']}'),
                      trailing: Text('₱${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: AppTextStyles.body),
                          Text('₱${subtotal.toStringAsFixed(2)}', style: AppTextStyles.body),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Shipping', style: AppTextStyles.body),
                          Text('₱${shipping.toStringAsFixed(2)}', style: AppTextStyles.body),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05)),
                          Text('₱${(subtotal + shipping).toStringAsFixed(2)}', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Payment Method', style: AppTextStyles.body),
                          Text(paymentMethod, style: AppTextStyles.body),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              Center(
                child: Text('You can view your order details in Order History.', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 