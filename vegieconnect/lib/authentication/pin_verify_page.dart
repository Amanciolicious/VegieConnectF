// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:vegieconnect/admin-side/admin_dashboard.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

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
      if (userRole == 'admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => AdminDashboard()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
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
    final green = const Color(0xFFA7C957);
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48, color: Color(0xFFA7C957)),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter PIN',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A 5-digit PIN was sent to:',
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Expires in $minutes:$seconds', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _isLoading || _secondsLeft == 0 ? null : _verifyPin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Verify'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    onPressed: _resendPin,
                    child: const Text('Resend PIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 