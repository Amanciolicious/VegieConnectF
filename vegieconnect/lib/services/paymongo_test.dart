import 'package:flutter/foundation.dart';
import 'payment_service.dart';
import 'paymongo_config.dart';

class PaymongoTest {
  static final PaymentService _paymentService = PaymentService();

  // Test the Paymongo configuration
  static Future<void> testConfiguration() async {
    debugPrint('=== PAYMONGO CONFIGURATION TEST ===');
    
    // Check if Paymongo is configured
    final isConfigured = PaymongoConfig.isConfigured;
    debugPrint('Is Configured: $isConfigured');
    
    if (!isConfigured) {
      debugPrint('Configuration Error: ${PaymongoConfig.configurationError}');
      debugPrint('Please update your test secret key in paymongo_config.dart');
      return;
    }
    
    // Display configuration details
    debugPrint('Environment: ${PaymongoConfig.environment}');
    debugPrint('Base URL: ${PaymongoConfig.baseUrl}');
    debugPrint('Secret Key: ${PaymongoConfig.secretKey.substring(0, 10)}...');
    
    // Test API connection
    debugPrint('\n=== TESTING API CONNECTION ===');
    final connectionResult = await _paymentService.testConnection();
    
    if (connectionResult['success']) {
      debugPrint('✅ API Connection: SUCCESS');
      debugPrint('Message: ${connectionResult['message']}');
      debugPrint('Environment: ${connectionResult['environment']}');
      debugPrint('Details: ${connectionResult['details']}');
    } else {
      debugPrint('❌ API Connection: FAILED');
      debugPrint('Error: ${connectionResult['error']}');
      debugPrint('Details: ${connectionResult['details']}');
    }
  }

  // Test payment intent creation
  static Future<void> testPaymentIntentCreation() async {
    debugPrint('\n=== TESTING PAYMENT INTENT CREATION ===');
    
    if (!PaymongoConfig.isConfigured) {
      debugPrint('❌ Cannot test payment intent - Paymongo not configured');
      return;
    }
    
    try {
      final result = await _paymentService.createPaymentIntent(
        amount: 100.0, // 100 PHP
        currency: 'PHP',
        paymentMethod: 'gcash',
        orderId: 'TEST_ORDER_${DateTime.now().millisecondsSinceEpoch}',
        metadata: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (result['success']) {
        debugPrint('✅ Payment Intent Creation: SUCCESS');
        debugPrint('Payment Intent ID: ${result['payment_intent_id']}');
        debugPrint('Status: ${result['status']}');
        debugPrint('Environment: ${result['environment']}');
      } else {
        debugPrint('❌ Payment Intent Creation: FAILED');
        debugPrint('Error: ${result['error']}');
        debugPrint('Details: ${result['details']}');
      }
    } catch (e) {
      debugPrint('❌ Payment Intent Creation Error: $e');
    }
  }

  // Test external payment creation
  static Future<void> testExternalPayment() async {
    debugPrint('\n=== TESTING EXTERNAL PAYMENT CREATION ===');
    
    if (!PaymongoConfig.isConfigured) {
      debugPrint('❌ Cannot test external payment - Paymongo not configured');
      return;
    }
    
    try {
      final result = await _paymentService.createExternalPaymentIntent(
        amount: 50.0, // 50 PHP
        currency: 'PHP',
        paymentMethod: 'gcash',
        orderId: 'TEST_EXTERNAL_${DateTime.now().millisecondsSinceEpoch}',
        customerEmail: 'test@example.com',
        customerName: 'Test User',
        metadata: {
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (result['success']) {
        debugPrint('✅ External Payment Creation: SUCCESS');
        debugPrint('Payment Method: ${result['payment_method']}');
        debugPrint('Payment Status: ${result['payment_status']}');
        debugPrint('Order ID: ${result['order_id']}');
        debugPrint('Environment: ${result['environment']}');
        if (result['redirect_url'] != null) {
          debugPrint('Redirect URL: ${result['redirect_url']}');
        }
      } else {
        debugPrint('❌ External Payment Creation: FAILED');
        debugPrint('Error: ${result['error']}');
        debugPrint('Details: ${result['details']}');
      }
    } catch (e) {
      debugPrint('❌ External Payment Creation Error: $e');
    }
  }

  // Run all tests
  static Future<void> runAllTests() async {
    debugPrint('🚀 STARTING PAYMONGO INTEGRATION TESTS');
    debugPrint('=====================================');
    
    await testConfiguration();
    await testPaymentIntentCreation();
    await testExternalPayment();
    
    debugPrint('\n=====================================');
    debugPrint('🏁 PAYMONGO INTEGRATION TESTS COMPLETED');
  }
}

// Usage example:
// In your main.dart or any widget, you can call:
// await PaymongoTest.runAllTests(); 