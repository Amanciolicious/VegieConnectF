# Paymongo Integration Setup Guide

This guide will help you set up Paymongo payment integration for testing purposes in your VegieConnect app.

## 🚀 Quick Setup

### Step 1: Get Your Paymongo Test API Key

1. Go to [Paymongo.com](https://paymongo.com/) and sign up for an account
2. Log in to your Paymongo Dashboard
3. Navigate to **API Keys** in the sidebar
4. Copy your **Test Secret Key** (starts with `sk_test_`)
5. Keep this key secure - never share it publicly

### Step 2: Configure Your App

1. Open `vegieconnect/lib/services/paymongo_config.dart`
2. Replace the placeholder with your actual test secret key:

```dart
static const String testSecretKey = 'sk_test_YOUR_ACTUAL_TEST_SECRET_KEY_HERE';
```

3. Save the file

### Step 3: Test the Integration

You can test the integration by calling the test methods in your app:

```dart
import 'package:vegieconnect/lib/services/paymongo_test.dart';

// Run all tests
await PaymongoTest.runAllTests();

// Or run individual tests
await PaymongoTest.testConfiguration();
await PaymongoTest.testPaymentIntentCreation();
await PaymongoTest.testExternalPayment();
```

## 📋 What's Included

### Payment Methods Supported
- **GCash** - Philippine mobile wallet
- **PayMaya** - Philippine digital wallet
- **Cash on Pickup** - Traditional cash payment

### Features
- ✅ Test mode only (safe for development)
- ✅ External browser payment processing
- ✅ Payment status verification
- ✅ Error handling and logging
- ✅ Firestore integration for order tracking

## 🔧 Configuration Details

### Files Modified
- `lib/services/paymongo_config.dart` - API configuration
- `lib/services/payment_service.dart` - Payment processing logic
- `lib/services/paymongo_test.dart` - Testing utilities

### Key Features
- **Test Mode Only**: Configured for testing with test API keys
- **Secret Key Only**: Uses only the secret key for server-side operations
- **Error Handling**: Comprehensive error handling and logging
- **Graceful Fallbacks**: Falls back to cash on pickup if payment fails

## 🧪 Testing

### Test Cards for GCash/PayMaya
- Use any valid Philippine mobile number
- Test with small amounts (e.g., 50 PHP, 100 PHP)
- All transactions are in test mode - no real money involved

### Test Scenarios
1. **Configuration Test**: Verifies API key is valid
2. **Payment Intent Test**: Creates a test payment intent
3. **External Payment Test**: Tests external browser payment flow

## 🛡️ Security Notes

- ✅ Test mode only - no real transactions
- ✅ Secret key only used for server-side operations
- ✅ No sensitive data logged
- ✅ Error messages don't expose sensitive information

## 📱 Usage in Your App

### Basic Payment Processing
```dart
final paymentService = PaymentService();

// Create external payment
final result = await paymentService.createExternalPaymentIntent(
  amount: 100.0,
  currency: 'PHP',
  paymentMethod: 'gcash',
  orderId: 'ORDER_123',
  customerEmail: 'customer@example.com',
  customerName: 'John Doe',
);

if (result['success']) {
  // Launch external browser for payment
  await paymentService.launchExternalPayment(
    redirectUrl: result['redirect_url'],
    orderId: result['order_id'],
    paymentMethod: result['payment_method'],
  );
}
```

### Check Payment Status
```dart
final status = await paymentService.verifyPaymentStatus(
  sourceId: 'payment_intent_id',
  orderId: 'ORDER_123',
);
```

## 🚨 Troubleshooting

### Common Issues

1. **"Paymongo not configured"**
   - Check that you've replaced the placeholder in `paymongo_config.dart`
   - Ensure your test secret key starts with `sk_test_`

2. **"Authentication failed"**
   - Verify your test secret key is correct
   - Check that you're using test keys, not live keys

3. **"API connection failed"**
   - Check your internet connection
   - Verify Paymongo service is available

### Debug Information
The integration includes comprehensive logging. Check your debug console for:
- API request/response details
- Payment flow status
- Error messages and details

## 📞 Support

If you encounter issues:
1. Check the debug logs for detailed error information
2. Verify your Paymongo dashboard for transaction status
3. Ensure you're using test mode for development

## 🔄 Next Steps

Once testing is complete and you're ready for production:
1. Get live API keys from Paymongo
2. Update the configuration for production
3. Test thoroughly with small amounts
4. Monitor transactions in your Paymongo dashboard

---

**Note**: This integration is configured for testing only. For production use, you'll need to modify the configuration to use live API keys and implement additional security measures. 