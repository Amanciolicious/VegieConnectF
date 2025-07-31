import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'digital_receipt_page.dart';
import 'package:vegieconnect/theme.dart';
import '../services/payment_service.dart';
import '../widgets/payment_status_checker.dart';
// Added for debugPrint

class CheckoutSummaryPage extends StatefulWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> cartItems;
  const CheckoutSummaryPage({super.key, required this.cartItems});

  @override
  State<CheckoutSummaryPage> createState() => _CheckoutSummaryPageState();
}

class _CheckoutSummaryPageState extends State<CheckoutSummaryPage> {
  bool isProcessing = false;
  String selectedPaymentMethod = 'cash_on_pickup';
  String selectedOnlineMethod = 'gcash'; // Default online payment method
  final PaymentService _paymentService = PaymentService();
  Map<String, String> availablePaymentMethods = {};

  @override
  void initState() {
    super.initState();
    availablePaymentMethods = _paymentService.getPaymentMethods();
  }

  double _calculateTotal() {
    double total = 0;
    for (final doc in widget.cartItems) {
      final data = doc.data();
      total += (data['price'] ?? 0) * (data['quantity'] ?? 1);
    }
    return total;
  }

  String _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cash_on_pickup':
        return '💵';
      case 'gcash':
        return '📱';
      case 'paymaya':
        return '💳';
      default:
        return '💰';
    }
  }

  String _getPaymentMethodDisplayName(String method) {
    switch (method) {
      case 'cash_on_pickup':
        return 'Cash on Pickup';
      case 'gcash':
        return 'Online Payment - GCash';
      case 'paymaya':
        return 'Online Payment - PayMaya';
      default:
        return 'Unknown Method';
    }
  }

  String _getPaymentMethodSubtitle(String method) {
    switch (method) {
      case 'cash_on_pickup':
        return 'Pay on Pickup';
      case 'gcash':
      case 'paymaya':
        return 'Secure Online Payment';
      default:
        return 'Payment Method';
    }
  }

  Future<String?> _showPaymentMethodDialog() async {
    String tempMethod = selectedPaymentMethod;
    String tempOnlineMethod = selectedOnlineMethod;
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cash on Pickup Option
              RadioListTile<String>(
                value: 'cash_on_pickup',
                groupValue: tempMethod,
                onChanged: (val) => setState(() => tempMethod = val!),
                title: Row(
                  children: [
                    Text('💵', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text('Cash on Pickup'),
                  ],
                ),
                subtitle: const Text(
                  'Pay on Pickup',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
              
              // Online Payment Option
              RadioListTile<String>(
                value: 'online_payment',
                groupValue: tempMethod,
                onChanged: (val) => setState(() => tempMethod = val!),
                title: Row(
                  children: [
                    Text('💳', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text('Online Payment'),
                  ],
                ),
                subtitle: const Text(
                  'Secure Online Payment',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
              ),
              
              // Online Payment Method Dropdown (only show if online payment is selected)
              if (tempMethod == 'online_payment') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Online Payment Method:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: tempOnlineMethod,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'gcash',
                            child: Row(
                              children: [
                                Text('📱', style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                const Text('GCash'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'paymaya',
                            child: Row(
                              children: [
                                Text('💳', style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                const Text('PayMaya'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) => setState(() => tempOnlineMethod = value!),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Return the appropriate payment method
              String finalMethod = tempMethod;
              if (tempMethod == 'online_payment') {
                finalMethod = tempOnlineMethod;
              }
              Navigator.pop(context, finalMethod);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final total = _calculateTotal();
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create orders in Firestore
      final batch = FirebaseFirestore.instance.batch();
      final ordersRef = FirebaseFirestore.instance.collection('orders');

      for (final doc in widget.cartItems) {
        final data = doc.data();
        final orderDoc = ordersRef.doc();
        
        batch.set(orderDoc, {
          'buyerId': user.uid,
          'productId': data['productId'],
          'sellerId': data['sellerId'],
          'productName': data['name'],
          'quantity': data['quantity'],
          'unit': data['unit'],
          'price': data['price'],
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'paymentMethod': selectedPaymentMethod,
          'paymentStatus': selectedPaymentMethod == 'cash_on_pickup' ? 'pending' : 'unpaid',
          'paymentAmount': total,
          'paymentDate': FieldValue.serverTimestamp(),
          'imageUrl': data['imageUrl'],
          'supplierName': data['supplierName'],
          'orderId': orderId,
          'totalAmount': total,
        });
      }

      // Commit the batch first to create all orders
      await batch.commit();

      // Process payment based on method
      Map<String, dynamic> paymentResult;

      if (selectedPaymentMethod == 'cash_on_pickup') {
        // For cash on pickup, orders are already created with payment info
        // Just return success since no additional processing is needed
        paymentResult = {
          'success': true,
          'payment_method': 'cash_on_pickup',
          'payment_status': 'pending',
          'order_id': orderId,
        };
      } else {
        // Process online payment (GCash/PayMaya) with external browser
        try {
          // Get user information for payment
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          final userData = userDoc.data() ?? {};
          final customerName = userData['name'] ?? 'Customer';
          final customerEmail = userData['email'] ?? 'customer@example.com';

          // Use the new external payment method for GCash/PayMaya
          if (_paymentService.requiresExternalBrowser(selectedPaymentMethod)) {
            // Test Paymongo connection first
            debugPrint('Testing Paymongo connection before creating payment...');
            final connectionTest = await _paymentService.testPaymongoConnection();
            
            debugPrint('Connection test result: $connectionTest');
            debugPrint('Connection test success: ${connectionTest['success']}');
            
            if (!connectionTest['success']) {
              debugPrint('Paymongo connection failed: ${connectionTest['error']}');
              // Show connection error and fallback to cash on pickup
              if (mounted) {
                final shouldFallback = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Payment Service Unavailable'),
                    content: Text(
                      'Online payment service is currently unavailable.\n\n'
                      'Error: ${connectionTest['error']}\n'
                      'Details: ${connectionTest['details']}\n\n'
                      'Would you like to proceed with Cash on Pickup instead?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Use Cash on Pickup'),
                      ),
                    ],
                  ),
                );

                if (shouldFallback == true) {
                  selectedPaymentMethod = 'cash_on_pickup';
                  paymentResult = {
                    'success': true,
                    'payment_method': 'cash_on_pickup',
                    'payment_status': 'pending',
                    'order_id': orderId,
                  };
                  
                } else {
                  throw Exception('Payment cancelled by user');
                }
              }
            }

            debugPrint('Paymongo connection successful, creating external payment intent...');
            
            paymentResult = await _paymentService.createExternalPaymentIntent(
            amount: total,
            currency: 'PHP',
            paymentMethod: selectedPaymentMethod,
            orderId: orderId,
            customerEmail: customerEmail,
            customerName: customerName,
            metadata: {
              'buyer_id': user.uid,
              'order_type': 'cart_checkout',
            },
          );

            if (paymentResult['success'] && paymentResult['redirect_url'] != null) {
              // Show confirmation dialog for external browser redirect
              if (mounted) {
                final shouldRedirect = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: Text('Complete Payment with ${_getPaymentMethodDisplayName(selectedPaymentMethod)}'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You will be redirected to ${_getPaymentMethodDisplayName(selectedPaymentMethod)} in your browser to complete the payment.',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Details:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Amount: ₱${total.toStringAsFixed(2)}'),
                              Text('Order ID: $orderId'),
                              Text('Payment Method: ${_getPaymentMethodDisplayName(selectedPaymentMethod)}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '⚠️ Important: Please complete the payment in your browser and return to the app.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.payment),
                        label: Text('Pay with ${_getPaymentMethodDisplayName(selectedPaymentMethod)}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );

                if (shouldRedirect == true) {
                  // Launch external browser for payment
                  final launchResult = await _paymentService.launchExternalPayment(
                    redirectUrl: paymentResult['redirect_url'],
                    orderId: orderId,
                    paymentMethod: selectedPaymentMethod,
                  );

                  if (launchResult['success']) {
                    // Show success message and instructions
                    if (mounted) {
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: const Text('Payment Gateway Opened'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Your payment gateway has been opened in your browser.',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Next Steps:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    Text('1. Complete payment in your browser'),
                                    Text('2. Return to this app'),
                                    Text('3. Check your order status'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Update payment result to indicate external redirect
                  paymentResult = {
                    'success': true,
                    'payment_method': selectedPaymentMethod,
                    'payment_status': 'pending',
                    'order_id': orderId,
                      'payment_intent_id': paymentResult['payment_intent_id'],
                      'external_redirect': true,
                      'message': 'Payment gateway opened in external browser',
                  };
                  } else {
                    throw Exception(launchResult['error']);
                  }
                } else {
                  throw Exception('Payment cancelled by user');
                }
              }
            } else {
              throw Exception(paymentResult['error']);
            }
          } else {
            // Fallback to legacy payment method for other payment types
            paymentResult = await _paymentService.processOnlinePayment(
              amount: total,
              currency: 'PHP',
              paymentMethod: selectedPaymentMethod,
              orderId: orderId,
              customerEmail: customerEmail,
              customerName: customerName,
              metadata: {
                'buyer_id': user.uid,
                'order_type': 'cart_checkout',
              },
            );
          }
        } catch (e) {
            // If online payment fails, fall back to cash on pickup
            if (mounted) {
              final shouldFallback = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Payment Method Unavailable'),
                  content: Text(
                    'Online payment (${_getPaymentMethodDisplayName(selectedPaymentMethod)}) is currently unavailable. '
                  'Would you like to proceed with Cash on Pickup instead?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Use Cash on Pickup'),
                  ),
                ],
              ),
            );

            if (shouldFallback == true) {
              // Update the payment method to cash on pickup
              selectedPaymentMethod = 'cash_on_pickup';
              paymentResult = {
                'success': true,
                'payment_method': 'cash_on_pickup',
                'payment_status': 'pending',
                'order_id': orderId,
              };
            } else {
              throw Exception('Payment failed: $e');
            }
          } else {
            throw Exception('Payment failed: $e');
          }
        }
      }

      if (paymentResult['success']) {
        // Clear cart
        final cartBatch = FirebaseFirestore.instance.batch();
        for (final doc in widget.cartItems) {
          cartBatch.delete(FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('cart')
              .doc(doc.id));
        }

        await cartBatch.commit();

        if (mounted) {
          // Check if this was an external browser payment
          if (paymentResult['external_redirect'] == true) {
            // Show payment status checker for external payments
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Payment Initiated'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your payment has been initiated in your browser. Please complete the payment and return to check the status.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    PaymentStatusChecker(
                      orderId: orderId,
                      sourceId: paymentResult['payment_intent_id'],
                      onStatusUpdated: () {
                        // Refresh the page or show updated status
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DigitalReceiptPage(
                            cartItems: widget.cartItems,
                            total: total,
                            paymentMethod: selectedPaymentMethod,
                            orderId: orderId,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Receipt'),
                  ),
                ],
              ),
            );
          } else {
            // For cash on pickup or other immediate payments, go directly to receipt
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DigitalReceiptPage(
                cartItems: widget.cartItems,
                total: total,
                paymentMethod: selectedPaymentMethod,
                orderId: orderId,
              ),
            ),
          );
          }
        }
      } else {
        throw Exception(paymentResult['error']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isProcessing = false);
    }
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
            
            // Payment Method Selection
            Neumorphic(
              style: AppNeumorphic.card,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Method',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.045,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    InkWell(
                      onTap: () async {
                        final method = await _showPaymentMethodDialog();
                        if (method != null) {
                          setState(() {
                            selectedPaymentMethod = method;
                            // Update the online method if it's an online payment
                            if (method == 'gcash' || method == 'paymaya') {
                              selectedOnlineMethod = method;
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryGreen),
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _getPaymentMethodIcon(selectedPaymentMethod),
                              style: const TextStyle(fontSize: 24),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getPaymentMethodDisplayName(selectedPaymentMethod),
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getPaymentMethodSubtitle(selectedPaymentMethod),
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Order Items
            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, i) {
                  final item = widget.cartItems[i].data();
                  return Neumorphic(
                    style: AppNeumorphic.card,
                    margin: EdgeInsets.only(bottom: screenWidth * 0.02),
                    child: ListTile(
                      leading: item['imageUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              child: Image.network(
                                item['imageUrl'],
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      color: AppColors.textSecondary,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                              ),
                              child: Icon(
                                Icons.image,
                                color: AppColors.textSecondary,
                              ),
                            ),
                      title: Text(
                        item['name'] ?? '',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₱${item['price']} x ${item['quantity']}'),
                          if (item['supplierName'] != null)
                            Text(
                              'Supplier: ${item['supplierName']}',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primaryGreen,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '₱${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Total and Checkout Button
            Neumorphic(
              style: AppNeumorphic.card,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.05),
                        ),
                        Text(
                          '₱${total.toStringAsFixed(2)}',
                          style: AppTextStyles.headline.copyWith(
                            fontSize: screenWidth * 0.05,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    SizedBox(
                      width: double.infinity,
                      height: screenWidth * 0.13,
                      child: NeumorphicButton(
                        style: AppNeumorphic.button.copyWith(
                          color: AppColors.primaryGreen,
                          boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(screenWidth * 0.04),
                          ),
                        ),
                        onPressed: isProcessing
                            ? null
                            : _processPayment,
                        child: isProcessing
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                'Place Order',
                                style: AppTextStyles.button.copyWith(
                                  fontSize: screenWidth * 0.05,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 