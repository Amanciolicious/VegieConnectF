# 🏦 Paymongo API Setup Guide

## 📋 Overview
This guide will help you set up Paymongo API for legitimate online payments in your VegieConnect app.

## 🚀 Step-by-Step Setup

### Step 1: Sign Up for Paymongo
1. Go to [https://paymongo.com/](https://paymongo.com/)
2. Click "Get Started" or "Sign Up"
3. Complete the registration process with your business details
4. Verify your email address
5. Complete your business profile

### Step 2: Get Your API Keys
1. Log in to your Paymongo Dashboard
2. Navigate to **API Keys** in the sidebar
3. Copy your **Secret Key** and **Public Key**
4. Keep your Secret Key secure - never share it publicly

### Step 3: Configure Your App
1. Open `vegieconnect/lib/services/paymongo_config.dart`
2. Replace the placeholder keys with your actual keys:

```dart
// Replace these with your actual test keys
static const String testSecretKey = 'sk_test_YOUR_ACTUAL_TEST_SECRET_KEY';
static const String testPublicKey = 'pk_test_YOUR_ACTUAL_TEST_PUBLIC_KEY';

// Replace these with your actual live keys (for production)
static const String liveSecretKey = 'sk_live_YOUR_ACTUAL_LIVE_SECRET_KEY';
static const String livePublicKey = 'pk_live_YOUR_ACTUAL_LIVE_PUBLIC_KEY';
```

3. Set the environment:
```dart
// Set to false for testing, true for production
static const bool isProduction = false;
```

### Step 4: Test the Integration
1. Use test mode first (`isProduction = false`)
2. Test with small amounts (₱1-₱10)
3. Use test phone numbers for GCash/PayMaya
4. Verify payments appear in your Paymongo dashboard

### Step 5: Go Live
1. Switch `isProduction` to `true`
2. Use live API keys
3. Test thoroughly with real payments
4. Monitor transactions in Paymongo Dashboard

## 🔧 Configuration Details

### API Keys Format
- **Test Keys**: Start with `sk_test_` and `pk_test_`
- **Live Keys**: Start with `sk_live_` and `pk_live_`

### Supported Payment Methods
- ✅ **GCash**: Mobile wallet payments
- ✅ **PayMaya**: Mobile wallet payments
- ✅ **Credit/Debit Cards**: International cards

### Currency Support
- ✅ **PHP (Philippine Peso)**: Primary currency
- ✅ **USD**: Available for international payments

## 🧪 Testing

### Test Cards (Credit/Debit)
```
Card Number: 4343434343434345
Expiry: Any future date
CVV: Any 3 digits
```

### Test Mobile Numbers (GCash/PayMaya)
```
Use any valid Philippine mobile number format:
+639XXXXXXXXX
```

### Test Amounts
- Start with small amounts: ₱1, ₱5, ₱10
- Test different payment methods
- Verify webhook notifications

## 🔒 Security Best Practices

### API Key Security
- ✅ Never commit API keys to version control
- ✅ Use environment variables in production
- ✅ Rotate keys regularly
- ✅ Monitor API usage

### Payment Security
- ✅ Always use HTTPS
- ✅ Validate payment amounts server-side
- ✅ Implement webhook verification
- ✅ Monitor for suspicious transactions

## 📊 Monitoring & Analytics

### Paymongo Dashboard
- **Transactions**: View all payments
- **Analytics**: Payment trends and insights
- **Webhooks**: Monitor payment notifications
- **Settlements**: Track fund transfers

### App Monitoring
- Monitor payment success rates
- Track user payment preferences
- Monitor error rates and types
- Set up alerts for payment failures

## 🚨 Troubleshooting

### Common Issues

#### 1. "Authentication failed" Error
**Solution**: Check your API keys are correct and active

#### 2. "Invalid payment method" Error
**Solution**: Ensure payment method is supported in your region

#### 3. "Amount too small" Error
**Solution**: Minimum amount is ₱1.00 for most payment methods

#### 4. "Currency not supported" Error
**Solution**: Ensure currency is PHP for Philippine payments

### Debug Steps
1. Check API key format and validity
2. Verify payment method support
3. Test with minimum amounts
4. Check network connectivity
5. Review Paymongo dashboard logs

## 📞 Support

### Paymongo Support
- **Email**: support@paymongo.com
- **Documentation**: [https://developers.paymongo.com/](https://developers.paymongo.com/)
- **Status Page**: [https://status.paymongo.com/](https://status.paymongo.com/)

### App Support
- Check error logs in console
- Verify configuration in `paymongo_config.dart`
- Test with different payment methods
- Monitor transaction status

## 🔄 Webhook Setup (Optional)

### Webhook Configuration
```dart
// In paymongo_config.dart
static const String webhookUrl = 'https://your-domain.com/webhook/paymongo';
```

### Webhook Events
- `payment.paid`: Payment completed successfully
- `payment.failed`: Payment failed
- `source.chargeable`: Payment source ready

### Webhook Security
- Verify webhook signatures
- Use HTTPS endpoints
- Implement idempotency
- Handle duplicate events

## 📈 Going Live Checklist

- [ ] API keys configured correctly
- [ ] Test payments working
- [ ] Error handling implemented
- [ ] Webhooks configured (optional)
- [ ] Monitoring set up
- [ ] Support documentation ready
- [ ] Legal compliance verified
- [ ] User terms updated

## 🎯 Success Metrics

### Payment Success Rate
- Target: >95% success rate
- Monitor: Failed payment reasons
- Optimize: Payment flow and error handling

### User Experience
- Payment completion time
- Error message clarity
- Fallback option availability
- Mobile payment optimization

### Business Metrics
- Total transaction volume
- Average order value
- Payment method preferences
- Revenue growth

---

**Note**: This setup ensures your Paymongo integration works legitimately and securely. Always test thoroughly before going live with real payments. 