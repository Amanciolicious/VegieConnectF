import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/customer-side/checkout_summary_page.dart'; // Added import for CheckoutSummaryPage

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  User? get user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> get _cartRef =>
      FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('cart');

  Future<void> _updateQuantity(String docId, int newQty) async {
    if (newQty > 0) {
      await _cartRef.doc(docId).update({'quantity': newQty});
    } else {
      await _cartRef.doc(docId).delete();
    }
  }

  Future<void> _removeItem(String docId) async {
    await _cartRef.doc(docId).delete();
  }

  double _calculateTotal(List<QueryDocumentSnapshot<Map<String, dynamic>>> items) {
    double total = 0;
    for (final doc in items) {
      final data = doc.data();
      total += (data['price'] ?? 0) * (data['quantity'] ?? 1);
    }
    return total;
  }

  bool _isProcessing = false;
  String _selectedPaymentMethod = 'cash_on_pickup';

  Future<String?> _showPaymentMethodDialog() async {
    String tempMethod = _selectedPaymentMethod;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                value: 'cash_on_pickup',
                groupValue: tempMethod,
                onChanged: (val) => setState(() => tempMethod = val!),
                title: const Text('Cash on Pick Up'),
              ),
              // Add more payment methods here in the future
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, tempMethod),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(List<QueryDocumentSnapshot<Map<String, dynamic>>> cartItems) async {
    if (cartItems.isEmpty || _isProcessing) return;
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;
    setState(() {
      _isProcessing = true;
      _selectedPaymentMethod = paymentMethod;
    });
    try {
      final batch = FirebaseFirestore.instance.batch();
      final ordersRef = FirebaseFirestore.instance.collection('orders');
      for (final doc in cartItems) {
        final data = doc.data();
        batch.set(ordersRef.doc(), {
          'buyerId': user!.uid,
          'productId': data['productId'],
          'sellerId': data['sellerId'],
          'productName': data['name'],
          'quantity': data['quantity'],
          'unit': data['unit'],
          'price': data['price'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'paymentMethod': paymentMethod,
          'paymentStatus': paymentMethod == 'cash_on_pickup' ? 'pending' : 'unpaid',
        });
        batch.delete(_cartRef.doc(doc.id));
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order placed for all cart items! Payment: ${_selectedPaymentMethod == 'cash_on_pickup' ? 'Cash on Pick Up' : _selectedPaymentMethod}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checkout failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in.')),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Cart', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _cartRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cartItems = snapshot.data?.docs ?? [];
          if (cartItems.isEmpty) {
            return Center(
              child: Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Your cart is empty.', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 18)),
                ),
              ),
            );
          }
          final total = _calculateTotal(cartItems);
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
                  itemBuilder: (context, i) {
                    final item = cartItems[i].data();
                    return Neumorphic(
                      style: AppNeumorphic.card,
                      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
                        leading: Icon(Icons.eco, color: AppColors.primaryGreen, size: screenWidth * 0.09),
                        title: Text(item['name'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                        subtitle: Text('\u20b1${item['price']} x ${item['quantity']}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, size: screenWidth * 0.07),
                              onPressed: () => _updateQuantity(cartItems[i].id, (item['quantity'] ?? 1) - 1),
                            ),
                            Text('${item['quantity']}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.045)),
                            IconButton(
                              icon: Icon(Icons.add, size: screenWidth * 0.07),
                              onPressed: () => _updateQuantity(cartItems[i].id, (item['quantity'] ?? 1) + 1),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red, size: screenWidth * 0.07),
                              onPressed: () => _removeItem(cartItems[i].id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05)),
                        Text('\u20b1${total.toStringAsFixed(2)}', style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05)),
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
                        onPressed: _isProcessing || cartItems.isEmpty
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CheckoutSummaryPage(cartItems: cartItems),
                                  ),
                                );
                              },
                        child: Text('Proceed to Checkout', style: AppTextStyles.button.copyWith(fontSize: screenWidth * 0.05)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 