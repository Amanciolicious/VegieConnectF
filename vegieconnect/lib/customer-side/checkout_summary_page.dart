import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'digital_receipt_page.dart';
import 'package:vegieconnect/theme.dart';

class CheckoutSummaryPage extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> cartItems;
  const CheckoutSummaryPage({super.key, required this.cartItems});

  @override
  State<CheckoutSummaryPage> createState() => _CheckoutSummaryPageState();
}

class _CheckoutSummaryPageState extends State<CheckoutSummaryPage> {
  bool isProcessing = false;

  double _calculateTotal() {
    double total = 0;
    for (final doc in widget.cartItems) {
      final data = doc.data();
      total += (data['price'] ?? 0) * (data['quantity'] ?? 1);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final total = _calculateTotal();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text('Order Summary', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary of Purchase', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.055)),
            SizedBox(height: screenWidth * 0.04),
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, i) {
                  final item = widget.cartItems[i].data();
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                    child: ListTile(
                      leading: item['imageUrl'] != null
                          ? Image.network(item['imageUrl'], width: 56, height: 56, fit: BoxFit.cover)
                          : Icon(Icons.image, size: 56, color: AppColors.primaryGreen),
                      title: Text(item['name'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('₱${item['price']} x ${item['quantity']}'),
                      trailing: Text('₱${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                    ),
                  );
                },
              ),
            ),
            Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05)),
                Text('₱${total.toStringAsFixed(2)}', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05)),
              ],
            ),
            SizedBox(height: screenWidth * 0.04),
            SizedBox(
              width: double.infinity,
              height: screenWidth * 0.13,
              child: NeumorphicButton(
                style: AppNeumorphic.button.copyWith(
                  color: AppColors.primaryGreen,
                  boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(screenWidth * 0.04)),
                ),
                onPressed: isProcessing
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Order'),
                            content: const Text('Are you sure you want to place this order?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Place Order'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        setState(() => isProcessing = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) throw Exception('Not logged in');
                          final batch = FirebaseFirestore.instance.batch();
                          final ordersRef = FirebaseFirestore.instance.collection('orders');
                          for (final doc in widget.cartItems) {
                            final data = doc.data();
                            batch.set(ordersRef.doc(), {
                              'buyerId': user.uid,
                              'productId': data['productId'],
                              'sellerId': data['sellerId'],
                              'productName': data['name'],
                              'quantity': data['quantity'],
                              'unit': data['unit'],
                              'price': data['price'],
                              'status': 'pending',
                              'createdAt': FieldValue.serverTimestamp(),
                              'paymentMethod': 'cash_on_pickup',
                              'paymentStatus': 'pending',
                              'imageUrl': data['imageUrl'],
                              'supplierName': data['supplierName'],
                            });
                            batch.delete(FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(doc.id));
                          }
                          await batch.commit();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DigitalReceiptPage(
                                  cartItems: widget.cartItems,
                                  total: total,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Order failed: $e')),
                            );
                          }
                        } finally {
                          if (context.mounted) setState(() => isProcessing = false);
                        }
                      },
                child: isProcessing
                    ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text('Place Order', style: AppTextStyles.button.copyWith(fontSize: screenWidth * 0.05)),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 