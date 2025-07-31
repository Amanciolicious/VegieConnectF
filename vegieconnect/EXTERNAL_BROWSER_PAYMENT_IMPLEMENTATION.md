# External Browser Payment Implementation

## Overview

This implementation modifies the Paymongo API integration to handle payments through external browsers, specifically for GCash and PayMaya payment methods. The payment processing is moved to external browsers while maintaining the frontend selection and status tracking within the app.

## Key Features

### 🔄 **External Browser Payment Flow**
- **GCash/PayMaya**: Payments are processed in external browser
- **Cash on Pickup**: Remains as in-app payment method
- **Secure Redirects**: Uses Paymongo's secure payment gateway
- **Status Tracking**: Real-time payment status monitoring

### 📱 **Frontend Integration**
- **Payment Method Selection**: Users choose payment method in app
- **External Browser Launch**: Seamless redirect to payment gateway
- **Status Checker**: Built-in payment status verification
- **Fallback Handling**: Automatic fallback to Cash on Pickup

### 🔒 **Security & Compliance**
- **PCI DSS Compliant**: Payment processing in external browser
- **Secure Webhooks**: Payment status updates via webhooks
- **Signature Verification**: Webhook signature validation (TODO)
- **Encrypted Communication**: All payment data encrypted

## Architecture

### **Payment Service (`payment_service.dart`)**

#### **New External Payment Methods**

```dart
// Create external payment intent
Future<Map<String, dynamic>> createExternalPaymentIntent({
  required double amount,
  required String currency,
  required String paymentMethod,
  required String orderId,
  required String customerEmail,
  required String customerName,
  Map<String, dynamic>? metadata,
})

// Launch external browser for payment
Future<Map<String, dynamic>> launchExternalPayment({
  required String redirectUrl,
  required String orderId,
  required String paymentMethod,
})

// Create payment source for external redirect
Future<Map<String, dynamic>> createPaymentSource({
  required double amount,
  required String currency,
  required String paymentMethod,
  required String orderId,
  required String customerEmail,
  required String customerName,
  Map<String, dynamic>? metadata,
})
```

#### **Payment Status Management**

```dart
// Verify payment status from webhook or manual check
Future<Map<String, dynamic>> verifyPaymentStatus({
  required String sourceId,
  required String orderId,
})

// Update order payment status in Firestore
Future<void> updateOrderPaymentStatus(String orderId, String status)

// Handle webhook from Paymongo
Future<Map<String, dynamic>> handlePaymentWebhook(Map<String, dynamic> webhookData)
```

### **Webhook Service (`webhook_service.dart`)**

#### **Webhook Processing**

```dart
// Handle incoming webhook from Paymongo
Future<Map<String, dynamic>> handleWebhook({
  required String webhookData,
  required String signature,
})

// Manual payment status verification
Future<Map<String, dynamic>> verifyPaymentStatus({
  required String sourceId,
  required String orderId,
})

// Get payment status for an order
Future<Map<String, dynamic>> getOrderPaymentStatus(String orderId)
```

### **Payment Status Checker Widget (`payment_status_checker.dart`)**

#### **Real-time Status Monitoring**

```dart
class PaymentStatusChecker extends StatefulWidget {
  final String orderId;
  final String? sourceId;
  final VoidCallback? onStatusUpdated;
}
```

## Implementation Details

### **1. External Browser Payment Flow**

#### **Step 1: Payment Method Selection**
```dart
// User selects GCash or PayMaya in the app
selectedPaymentMethod = 'gcash'; // or 'paymaya'
```

#### **Step 2: Create Payment Source**
```dart
final paymentResult = await _paymentService.createExternalPaymentIntent(
  amount: total,
  currency: 'PHP',
  paymentMethod: selectedPaymentMethod,
  orderId: orderId,
  customerEmail: customerEmail,
  customerName: customerName,
);
```

#### **Step 3: Launch External Browser**
```dart
final launchResult = await _paymentService.launchExternalPayment(
  redirectUrl: paymentResult['redirect_url'],
  orderId: orderId,
  paymentMethod: selectedPaymentMethod,
);
```

#### **Step 4: Payment Status Tracking**
```dart
PaymentStatusChecker(
  orderId: orderId,
  sourceId: paymentResult['source_id'],
  onStatusUpdated: () {
    // Handle status updates
  },
)
```

### **2. Webhook Integration**

#### **Webhook Endpoint Setup**
```dart
// In your webhook endpoint (server-side)
final webhookService = WebhookService();
final result = await webhookService.handleWebhook(
  webhookData: request.body,
  signature: request.headers['paymongo-signature'],
);
```

#### **Webhook Event Handling**
```dart
// Handle different webhook events
switch (eventType) {
  case 'source.chargeable':
    await _handlePaymentSuccess(data);
    break;
  case 'source.failed':
    await _handlePaymentFailure(data);
    break;
  case 'payment.paid':
    await _handlePaymentPaid(data);
    break;
  case 'payment.failed':
    await _handlePaymentFailed(data);
    break;
}
```

### **3. Payment Status Updates**

#### **Automatic Status Updates**
```dart
// Update order status in Firestore
await updateOrderPaymentStatus(orderId, status);

// Firestore document update
batch.update(doc.reference, {
  'paymentStatus': status == 'chargeable' ? 'paid' : 'pending',
  'paymentVerifiedAt': FieldValue.serverTimestamp(),
  'lastUpdated': FieldValue.serverTimestamp(),
});
```

#### **Manual Status Verification**
```dart
// Verify payment status with Paymongo API
final verifyResult = await _webhookService.verifyPaymentStatus(
  sourceId: sourceId,
  orderId: orderId,
);
```

## Configuration

### **Paymongo Configuration**

#### **Update `paymongo_config.dart`**
```dart
class PaymongoConfig {
  // Webhook settings
  static const String webhookUrl = 'https://your-domain.com/webhook/paymongo';
  
  // Payment method settings
  static const Map<String, String> supportedPaymentMethods = {
    'gcash': 'gcash',
    'paymaya': 'paymaya',
  };
}
```

#### **Webhook URL Configuration**
1. Set up webhook endpoint in your server
2. Configure webhook URL in Paymongo dashboard
3. Add webhook secret for signature verification

### **Dependencies**

#### **Add to `pubspec.yaml`**
```yaml
dependencies:
  url_launcher: ^6.2.5
```

## Usage Examples

### **1. Checkout Process**

```dart
// In checkout_summary_page.dart
if (_paymentService.requiresExternalBrowser(selectedPaymentMethod)) {
  // Use external browser payment
  paymentResult = await _paymentService.createExternalPaymentIntent(
    amount: total,
    currency: 'PHP',
    paymentMethod: selectedPaymentMethod,
    orderId: orderId,
    customerEmail: customerEmail,
    customerName: customerName,
  );
  
  if (paymentResult['success'] && paymentResult['redirect_url'] != null) {
    // Launch external browser
    final launchResult = await _paymentService.launchExternalPayment(
      redirectUrl: paymentResult['redirect_url'],
      orderId: orderId,
      paymentMethod: selectedPaymentMethod,
    );
  }
}
```

### **2. Payment Status Monitoring**

```dart
// Show payment status checker
PaymentStatusChecker(
  orderId: orderId,
  sourceId: sourceId,
  onStatusUpdated: () {
    // Handle status updates
    setState(() {
      // Update UI
    });
  },
)
```

### **3. Webhook Processing**

```dart
// Process webhook events
final webhookService = WebhookService();
final result = await webhookService.handleWebhook(
  webhookData: webhookPayload,
  signature: webhookSignature,
);

if (result['success']) {
  // Webhook processed successfully
  print('Webhook processed: ${result['event_type']}');
} else {
  // Handle webhook error
  print('Webhook error: ${result['error']}');
}
```

## Security Considerations

### **1. Webhook Security**
- Implement proper signature verification
- Use HTTPS for webhook endpoints
- Validate webhook payload structure
- Log all webhook events for monitoring

### **2. Payment Data Security**
- Never store sensitive payment data in app
- Use external browser for payment processing
- Implement proper error handling
- Log payment events for audit trail

### **3. Error Handling**
- Graceful fallback to Cash on Pickup
- Clear error messages for users
- Retry mechanisms for failed payments
- Comprehensive logging for debugging

## Testing

### **1. Test Environment**
```dart
// Use test API keys
static const bool isProduction = false;
static const String testSecretKey = 'sk_test_...';
static const String testPublicKey = 'pk_test_...';
```

### **2. Test Payment Flow**
1. Select GCash/PayMaya payment method
2. Complete checkout process
3. Verify external browser launch
4. Check payment status updates
5. Verify order status in Firestore

### **3. Webhook Testing**
1. Set up webhook endpoint
2. Configure webhook in Paymongo dashboard
3. Test webhook signature verification
4. Verify payment status updates

## Troubleshooting

### **Common Issues**

#### **1. External Browser Not Launching**
- Check URL launcher permissions
- Verify redirect URL format
- Test with different browsers

#### **2. Payment Status Not Updating**
- Check webhook configuration
- Verify webhook endpoint accessibility
- Check Firestore permissions
- Review webhook logs

#### **3. Payment Verification Fails**
- Verify Paymongo API keys
- Check network connectivity
- Review API response logs
- Test with manual verification

### **Debug Tools**

#### **1. Webhook Logs**
```dart
// View webhook processing logs
Stream<List<Map<String, dynamic>>> getWebhookLogs()
```

#### **2. Payment Statistics**
```dart
// Get payment processing statistics
Future<Map<String, dynamic>> getWebhookStatistics()
```

#### **3. Manual Verification**
```dart
// Manually verify payment status
Future<Map<String, dynamic>> verifyPaymentStatus({
  required String sourceId,
  required String orderId,
})
```

## Migration Guide

### **From In-App Payments**

1. **Update Payment Service**
   - Add external payment methods
   - Implement URL launcher functionality
   - Add webhook handling

2. **Update Checkout Process**
   - Modify payment method selection
   - Add external browser launch
   - Implement status tracking

3. **Add Webhook Service**
   - Create webhook handler
   - Implement status updates
   - Add logging and monitoring

4. **Update UI Components**
   - Add payment status checker
   - Modify checkout flow
   - Add error handling

### **Configuration Changes**

1. **Add Dependencies**
   ```yaml
   url_launcher: ^6.2.5
   ```

2. **Update Permissions**
   ```xml
   <!-- Android -->
   <uses-permission android:name="android.permission.INTERNET" />
   ```

3. **Configure Webhooks**
   - Set up webhook endpoint
   - Configure Paymongo webhook URL
   - Test webhook functionality

## Best Practices

### **1. User Experience**
- Clear payment instructions
- Progress indicators
- Error recovery options
- Status feedback

### **2. Security**
- Validate all inputs
- Implement proper error handling
- Log security events
- Regular security audits

### **3. Performance**
- Optimize webhook processing
- Implement caching where appropriate
- Monitor response times
- Handle network failures gracefully

### **4. Monitoring**
- Track payment success rates
- Monitor webhook delivery
- Log payment events
- Alert on failures

## Future Enhancements

### **1. Additional Payment Methods**
- Credit card processing
- Bank transfer integration
- Digital wallet support

### **2. Advanced Features**
- Recurring payments
- Payment scheduling
- Refund processing
- Dispute handling

### **3. Analytics**
- Payment analytics dashboard
- Conversion tracking
- User behavior analysis
- Performance metrics

## Support

For issues or questions regarding the external browser payment implementation:

1. Check the troubleshooting section
2. Review webhook logs
3. Test with different payment methods
4. Contact development team

## Conclusion

This implementation provides a secure, user-friendly external browser payment system for GCash and PayMaya while maintaining the existing Cash on Pickup functionality. The modular design allows for easy extension to additional payment methods and provides comprehensive monitoring and debugging capabilities. 