// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/authentication/login_page.dart';
import 'package:vegieconnect/admin-side/admin_dashboard.dart';
import 'package:vegieconnect/supplier-side/supplier_dashboard.dart';
import 'package:vegieconnect/customer-side/onboarding_page.dart';

class PinVerifyPage extends StatefulWidget {
  final String userId;
  final String email;
  const PinVerifyPage({super.key, required this.userId, required this.email});

  @override
  State<PinVerifyPage> createState() => _PinVerifyPageState();
}

class _PinVerifyPageState extends State<PinVerifyPage> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _secondsLeft = 300;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(_tick);
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    if (!mounted) return;
    setState(() {
      _secondsLeft = 300 - elapsed.inSeconds;
      if (_secondsLeft <= 0) {
        _ticker.stop();
        _secondsLeft = 0;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final data = doc.data();
      if (data == null) throw Exception('User not found');
      final pin = data['pin'] as String?;
      final expiresAt = (data['pinExpiresAt'] as Timestamp?)?.toDate();
      if (_pinController.text.trim() != pin) {
        setState(() {
          _errorMessage = 'Incorrect PIN.';
          _isLoading = false;
        });
        return;
      }
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        setState(() {
          _errorMessage = 'PIN expired. Please request a new one.';
          _isLoading = false;
        });
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({'verified': true});
      if (!mounted) return;
      // Check user role and route accordingly
      final updatedDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final updatedData = updatedDoc.data();
      final userRole = updatedData != null ? updatedData['role'] ?? 'buyer' : 'buyer';
      final isNewlyRegistered = updatedData != null ? updatedData['isNewlyRegistered'] ?? false : false;
      final onboardingCompleted = updatedData != null ? updatedData['onboardingCompleted'] ?? false : false;
      
      if (userRole == 'admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AdminDashboard()),
          (route) => false,
        );
      } else if (userRole == 'supplier') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => SupplierDashboard()),
          (route) => false,
        );
      } else {
        // For buyers, check if they need onboarding
        if (isNewlyRegistered && !onboardingCompleted) {
          // Show onboarding for newly registered users
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => OnboardingPage(userId: widget.userId)),
            (route) => false,
          );
        } else {
          // Go to login page for existing users
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginPage()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed.';
        _isLoading = false;
      });
    }
  }

  Future<void> sendPinEmail(String email, String pin) async {
    const serviceId = 'your_service_id';
    const templateId = 'your_template_id';
    const userId = 'your_user_id';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'to_email': email,
          'pin': pin,
        },
      }),
    );
    if (response.statusCode == 200) {
      print('PIN email sent!');
    } else {
      print('Failed to send PIN email: \\${response.body}');
    }
  }

  Future<void> _resendPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Generate new PIN
      final newPin = (Random().nextInt(90000) + 10000).toString();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'pin': newPin,
        'pinExpiresAt': expiresAt,
      });
      await sendPinEmail(widget.email, newPin);
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _secondsLeft = 300;
      });
      _ticker.stop();
      _ticker.start();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new PIN has been sent to your email!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to resend PIN.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('PIN Verification', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              // Header Section
              Neumorphic(
                style: AppNeumorphic.card,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.08),
                  child: Column(
                    children: [
                      Icon(
                        Icons.security,
                        size: screenWidth * 0.15,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        'Secure Verification',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.06,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        'Enter your 6-digit PIN to continue',
                        style: AppTextStyles.body.copyWith(
                          fontSize: screenWidth * 0.04,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              // PIN Input Section
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    children: [
                      Text(
                        'Enter PIN',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.055,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      // PIN Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return Neumorphic(
                            style: AppNeumorphic.inset.copyWith(
                              color: _pinController.text.length > index 
                                  ? AppColors.primaryGreen.withOpacity(0.1) 
                                  : Colors.white,
                            ),
                            child: SizedBox(
                              width: screenWidth * 0.12,
                              height: screenWidth * 0.12,
                              child: Center(
                                child: index < _pinController.text.length
                                    ? Icon(
                                        Icons.circle,
                                        size: screenWidth * 0.06,
                                        color: AppColors.primaryGreen,
                                      )
                                    : Text(
                                        '',
                                        style: AppTextStyles.headline.copyWith(
                                          fontSize: screenWidth * 0.06,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      // Hidden TextField for PIN input
                      Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: (value) {
                            setState(() {});
                            if (value.length == 6) {
                              _verifyPin();
                            }
                          },
                          decoration: InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      // Number Pad
                      SizedBox(height: screenWidth * 0.05),
                      Column(
                        children: [
                          for (int i = 0; i < 3; i++)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                for (int j = 1; j <= 3; j++)
                                  _buildNumberButton(screenWidth, (i * 3 + j).toString()),
                              ],
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildNumberButton(screenWidth, ''),
                              _buildNumberButton(screenWidth, '0'),
                              _buildBackspaceButton(screenWidth),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      // Verify Button
                      NeumorphicButton(
                        style: AppNeumorphic.button.copyWith(
                          color: AppColors.primaryGreen,
                        ),
                        onPressed: _isLoading ? null : _verifyPin,
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                          child: _isLoading
                              ? SizedBox(
                                  height: screenWidth * 0.05,
                                  width: screenWidth * 0.05,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Verify PIN',
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      // Forgot PIN
                      TextButton(
                        onPressed: () {
                          // TODO: Implement forgot PIN functionality
                        },
                        child: Text(
                          'Forgot PIN?',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryGreen,
                            fontSize: screenWidth * 0.035,
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
      ),
    );
  }

  Widget _buildNumberButton(double screenWidth, String number) {
    if (number.isEmpty) {
      return SizedBox(width: screenWidth * 0.12, height: screenWidth * 0.12);
    }
    
    return NeumorphicButton(
      style: AppNeumorphic.button.copyWith(
        color: Colors.white,
      ),
      onPressed: () {
        if (_pinController.text.length < 6) {
          _pinController.text += number;
          setState(() {});
          if (_pinController.text.length == 6) {
            _verifyPin();
          }
        }
      },
      child: SizedBox(
        width: screenWidth * 0.12,
        height: screenWidth * 0.12,
        child: Center(
          child: Text(
            number,
            style: AppTextStyles.headline.copyWith(
              fontSize: screenWidth * 0.06,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton(double screenWidth) {
    return NeumorphicButton(
      style: AppNeumorphic.button.copyWith(
        color: Colors.white,
      ),
      onPressed: () {
        if (_pinController.text.isNotEmpty) {
          _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
          setState(() {});
        }
      },
      child: SizedBox(
        width: screenWidth * 0.12,
        height: screenWidth * 0.12,
        child: Center(
          child: Icon(
            Icons.backspace,
            size: screenWidth * 0.06,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }
} 