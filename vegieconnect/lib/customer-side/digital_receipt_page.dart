import 'package:intl/intl.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/payment_service.dart';
import 'buyer_order_history_page.dart';

class DigitalReceiptPage extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> cartItems;
  final double total;
  final String paymentMethod;
  final String orderId;
  
  const DigitalReceiptPage({
    super.key, 
    required this.cartItems, 
    required this.total,
    required this.paymentMethod,
    required this.orderId,
  });

  String _generateOrderNumber() {
    return orderId;
  }

  String _getPaymentMethodDisplayName() {
    final paymentService = PaymentService();
    return paymentService.getPaymentMethodDisplayName(paymentMethod);
  }

  String _getPaymentMethodIcon() {
    final paymentService = PaymentService();
    return paymentService.getPaymentMethodIcon(paymentMethod);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final orderNumber = _generateOrderNumber();
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    final paymentMethodDisplay = _getPaymentMethodDisplayName();
    final paymentIcon = _getPaymentMethodIcon();
    final subtotal = total;
    final shipping = 0.0;
    final orderStatus = 'Order Placed';
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: const Text('Order Receipt', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success Header
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle, 
                      size: screenWidth * 0.18, 
                      color: AppColors.primaryGreen
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      'Thank you for your purchase!', 
                      style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.055)
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      'Your order has been placed successfully.', 
                      style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)
                    ),
                  ],
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              
              // Order Details Card
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      _buildDetailRow('Order Number', orderNumber),
                      _buildDetailRow('Date & Time', dateStr),
                      _buildDetailRow('Status', orderStatus),
                      _buildDetailRow('Payment Method', '$paymentIcon $paymentMethodDisplay'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              
              // Order Items
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Items',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: cartItems.length,
                        separatorBuilder: (context, i) => Divider(height: 1),
                        itemBuilder: (context, i) {
                          final item = cartItems[i].data();
                          return ListTile(
                            leading: item['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    child: Image.network(
                                      item['imageUrl'], 
                                      width: 48, 
                                      height: 48, 
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: AppColors.background,
                                            borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                          ),
                                          child: Icon(
                                            Icons.image,
                                            color: AppColors.textSecondary,
                                            size: 24,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                    ),
                                    child: Icon(
                                      Icons.image,
                                      color: AppColors.textSecondary,
                                      size: 24,
                                    ),
                                  ),
                            title: Text(
                              item['name'] ?? '', 
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)
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
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              
              // Payment Summary
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      _buildSummaryRow('Subtotal', '₱${subtotal.toStringAsFixed(2)}'),
                      _buildSummaryRow('Shipping', '₱${shipping.toStringAsFixed(2)}'),
                      Divider(),
                      _buildSummaryRow(
                        'Total', 
                        '₱${(subtotal + shipping).toStringAsFixed(2)}',
                        isTotal: true,
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      _buildSummaryRow('Payment Method', '$paymentIcon $paymentMethodDisplay'),
                      if (paymentMethod != 'cash_on_pickup')
                        _buildSummaryRow('Payment Status', 'Pending'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              
              // Next Steps
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s Next?',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      if (paymentMethod == 'cash_on_pickup') ...[
                        _buildNextStep(
                          Icons.payment,
                          'Pay on Pickup',
                          'Pay with cash when you pick up your order',
                        ),
                        _buildNextStep(
                          Icons.location_on,
                          'Pickup Location',
                          'Collect your order from the supplier\'s location',
                        ),
                      ] else ...[
                        _buildNextStep(
                          Icons.payment,
                          'Complete Payment',
                          'Complete your online payment to confirm your order',
                        ),
                        _buildNextStep(
                          Icons.notifications,
                          'Payment Confirmation',
                          'You\'ll receive a confirmation once payment is processed',
                        ),
                      ],
                      _buildNextStep(
                        Icons.track_changes,
                        'Track Order',
                        'Monitor your order status in your profile',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: NeumorphicButton(
                      style: AppNeumorphic.button,
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                        child: Text(
                          'Continue Shopping',
                          style: AppTextStyles.button.copyWith(fontSize: screenWidth * 0.04),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: NeumorphicButton(
                      style: AppNeumorphic.button.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                      onPressed: () {
                        // Navigate to order history
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BuyerOrderHistoryPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                        child: Text(
                          'View Order History',
                          style: AppTextStyles.button.copyWith(
                            fontSize: screenWidth * 0.04,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppColors.primaryGreen : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryGreen,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 