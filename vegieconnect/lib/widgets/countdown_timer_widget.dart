import 'package:flutter/material.dart';
import 'dart:async';
import '../services/countdown_timer_service.dart';
import '../theme.dart';

class CountdownTimerWidget extends StatefulWidget {
  final String productId;
  final VoidCallback? onTimerComplete;

  const CountdownTimerWidget({
    super.key,
    required this.productId,
    this.onTimerComplete,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  final CountdownTimerService _countdownService = CountdownTimerService();
  StreamSubscription<int>? _countdownSubscription;
  int _remainingSeconds = 120;
  bool _isActive = false;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
  }

  void _initializeCountdown() {
    // Start countdown if not already active
    if (!_countdownService.isCountdownActive(widget.productId)) {
      _countdownService.startCountdown(widget.productId);
    }

    // Get current remaining time
    final currentRemainingTime = _countdownService.getRemainingTime(widget.productId);
    if (currentRemainingTime != null) {
      setState(() {
        _remainingSeconds = currentRemainingTime;
        _isActive = true;
      });
    }

    // Listen to countdown updates
    _countdownSubscription = _countdownService.getCountdownStream(widget.productId)?.listen(
      (remainingSeconds) {
        setState(() {
          _remainingSeconds = remainingSeconds;
          _isActive = true;
        });

        if (remainingSeconds <= 0) {
          _isActive = false;
          widget.onTimerComplete?.call();
        }
      },
    );
  }

  @override
  void dispose() {
    _countdownSubscription?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_remainingSeconds > 60) {
      return Colors.green;
    } else if (_remainingSeconds > 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (!_isActive && _remainingSeconds <= 0) {
      return Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: screenWidth * 0.04),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Auto-approved!',
              style: AppTextStyles.body.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: _getTimerColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(color: _getTimerColor()),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: _getTimerColor(),
            size: screenWidth * 0.04,
          ),
          SizedBox(width: screenWidth * 0.02),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto-approval in:',
                style: AppTextStyles.body.copyWith(
                  fontSize: screenWidth * 0.03,
                  color: _getTimerColor(),
                ),
              ),
              Text(
                _formatTime(_remainingSeconds),
                style: AppTextStyles.body.copyWith(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: _getTimerColor(),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_remainingSeconds <= 30)
            Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(screenWidth * 0.01),
              ),
              child: Text(
                'URGENT',
                style: AppTextStyles.body.copyWith(
                  fontSize: screenWidth * 0.025,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 