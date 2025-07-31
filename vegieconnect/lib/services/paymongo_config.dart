// Paymongo API Configuration
// 
// SETUP INSTRUCTIONS:
// 1. Sign up at https://paymongo.com/
// 2. Go to Dashboard > API Keys
// 3. Copy your Secret Key and Public Key
// 4. Replace the keys below with your actual keys
// 5. For production, use live keys (sk_live_* and pk_live_*)
// 6. For testing, use test keys (sk_test_* and pk_test_*)

class PaymongoConfig {
  // ===== TESTING KEYS (Replace with your actual test keys) =====
  // These are sample test keys - replace with your actual Paymongo test keys
  static const String testSecretKey = 'sk_test_96Aw6B2dbzVtBWFqrXTyDJoD';
  static const String testPublicKey = 'pk_test_snsdQKrbXbvjkoVynqucGYwt';
  
  // ===== PRODUCTION KEYS (Replace with your actual live keys) =====
  static const String liveSecretKey = 'sk_live_96Aw6B2dbzVtBWFqrXTyDJoD';
  static const String livePublicKey = 'pk_live_snsdQKrbXbvjkoVynqucGYwt';
  
  // ===== ENVIRONMENT SETTING =====
  // Set this to true for production, false for testing
  static const bool isProduction = false;
  
  // ===== API CONFIGURATION =====
  static const String baseUrl = 'https://api.paymongo.com/v1';
  
  // ===== PAYMENT METHODS =====
  static const Map<String, String> supportedPaymentMethods = {
    'gcash': 'gcash',
    'paymaya': 'paymaya',
  };
  
  // ===== CURRENCY SETTINGS =====
  static const String defaultCurrency = 'PHP';
  
  // ===== WEBHOOK SETTINGS =====
  static const String webhookUrl = 'https://http:/amancioliciaus.com/webhook/paymongo';
  
  // ===== HELPER METHODS =====
  static String get secretKey => isProduction ? liveSecretKey : testSecretKey;
  static String get publicKey => isProduction ? livePublicKey : testPublicKey;
  
  static bool get isConfigured {
    // For testing purposes, we'll allow the sample keys to work
    // In production, you should replace these with your actual keys
    return secretKey.isNotEmpty && 
           publicKey.isNotEmpty && 
           secretKey != 'sk_live_YOUR_LIVE_SECRET_KEY_HERE' &&
           publicKey != 'pk_live_YOUR_LIVE_PUBLIC_KEY_HERE';
  }
  
  static String get environment => isProduction ? 'production' : 'test';
  
  // ===== VALIDATION METHODS =====
  static bool isValidSecretKey(String key) {
    return key.startsWith('sk_') && key.length > 20;
  }
  
  static bool isValidPublicKey(String key) {
    return key.startsWith('pk_') && key.length > 20;
  }
  
  // ===== ERROR MESSAGES =====
  static String get configurationError => 
    'Paymongo is not properly configured. Please update the API keys in paymongo_config.dart';
  
  static String get testModeMessage => 
    'Running in TEST mode. Use test cards for payment testing.';
  
  static String get productionModeMessage => 
    'Running in PRODUCTION mode. Real payments will be processed.';
}

// ===== PAYMONGO SETUP GUIDE =====
/*
STEP 1: SIGN UP FOR PAYMONGO
- Go to https://paymongo.com/
- Click "Get Started" or "Sign Up"
- Complete the registration process
- Verify your email address

STEP 2: GET YOUR API KEYS
- Log in to your Paymongo Dashboard
- Go to "API Keys" in the sidebar
- Copy your Secret Key and Public Key
- Keep your Secret Key secure and never share it

STEP 3: CONFIGURE THE APP
- Open vegieconnect/lib/services/paymongo_config.dart
- Replace the placeholder keys with your actual keys
- Set isProduction to false for testing
- Set isProduction to true for production

STEP 4: TEST THE INTEGRATION
- Use test cards for testing (see Paymongo documentation)
- Test with small amounts first
- Verify webhook endpoints if using webhooks

STEP 5: GO LIVE
- Switch isProduction to true
- Use live API keys
- Test thoroughly before going live
- Monitor transactions in Paymongo Dashboard

TEST CARDS FOR GCASH/PAYMaya:
- GCash: Use any valid Philippine mobile number
- PayMaya: Use any valid Philippine mobile number
- For testing, use test mode with small amounts

IMPORTANT SECURITY NOTES:
- Never commit API keys to version control
- Use environment variables in production
- Keep your secret key secure
- Monitor your Paymongo dashboard regularly
*/ 