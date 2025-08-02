import 'package:flutter_test/flutter_test.dart';
import 'package:vegieconnect/services/countdown_timer_service.dart';

void main() {
  group('CountdownTimerService Tests', () {
    late CountdownTimerService countdownService;

    setUp(() {
      countdownService = CountdownTimerService();
    });

    tearDown(() {
      countdownService.dispose();
    });

    test('should start countdown for a product', () {
      const productId = 'test_product_1';
      
      // Start countdown
      countdownService.startCountdown(productId);
      
      // Check if countdown is active
      expect(countdownService.isCountdownActive(productId), isTrue);
      
      // Check if stream is available
      expect(countdownService.getCountdownStream(productId), isNotNull);
    });

    test('should cancel countdown for a product', () {
      const productId = 'test_product_2';
      
      // Start countdown
      countdownService.startCountdown(productId);
      expect(countdownService.isCountdownActive(productId), isTrue);
      
      // Cancel countdown
      countdownService.cancelCountdown(productId);
      expect(countdownService.isCountdownActive(productId), isFalse);
    });

    test('should not start multiple countdowns for same product', () {
      const productId = 'test_product_3';
      
      // Start countdown twice
      countdownService.startCountdown(productId);
      countdownService.startCountdown(productId);
      
      // Should only have one active countdown
      expect(countdownService.isCountdownActive(productId), isTrue);
    });

    test('should cancel all countdowns', () {
      const productId1 = 'test_product_4';
      const productId2 = 'test_product_5';
      
      // Start multiple countdowns
      countdownService.startCountdown(productId1);
      countdownService.startCountdown(productId2);
      
      expect(countdownService.isCountdownActive(productId1), isTrue);
      expect(countdownService.isCountdownActive(productId2), isTrue);
      
      // Cancel all
      countdownService.cancelAllCountdowns();
      
      expect(countdownService.isCountdownActive(productId1), isFalse);
      expect(countdownService.isCountdownActive(productId2), isFalse);
    });

    test('should get remaining time for active countdown', () {
      const productId = 'test_product_6';
      
      // Start countdown
      countdownService.startCountdown(productId);
      
      // Should have remaining time
      final remainingTime = countdownService.getRemainingTime(productId);
      expect(remainingTime, isNotNull);
      expect(remainingTime, greaterThan(0));
      expect(remainingTime, lessThanOrEqualTo(120)); // 2 minutes
    });

    test('should return null for remaining time of inactive countdown', () {
      const productId = 'test_product_7';
      
      // No countdown started
      final remainingTime = countdownService.getRemainingTime(productId);
      expect(remainingTime, isNull);
    });
  });
} 