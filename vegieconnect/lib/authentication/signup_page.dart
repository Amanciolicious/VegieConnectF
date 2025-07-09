import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vegieconnect/customer-side/contact_info_page.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, this.onLoginTap});
  final VoidCallback? onLoginTap;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthdayController = TextEditingController();
  DateTime? _selectedBirthday;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'buyer';
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> sendPinEmail(String email, String pin) async {
    const serviceId = 'service_iuouffm';
    const templateId = 'template_n68ct9l';
    const userId = 'LU5nqmNiQgb_vus3a';

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

  Future<void> _proceed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Generate 5-digit PIN
      final pin = (Random().nextInt(90000) + 10000).toString();
      final expiresAt = DateTime.now().add(const Duration(minutes: 5));
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'birthday': _birthdayController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'pin': pin,
        'pinExpiresAt': expiresAt,
        'verified': false,
      });
      // Send PIN email notification
      await sendPinEmail(_emailController.text.trim(), pin);
      if (!mounted) return;
      
      // All users go to contact info page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ContactInfoPage(userId: credential.user!.uid),
        ),
      );
    } on FirebaseAuthException {
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF2196F3);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          // Blue accent background (bottom left)
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: 180,
              decoration: BoxDecoration(
                color: blue,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(80),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Join Us',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Learn more about our smart, convenient ordering and earn rewards in each transaction.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _birthdayController,
                              readOnly: true,
                              onTap: () async {
                                FocusScope.of(context).requestFocus(FocusNode());
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedBirthday ?? DateTime(2000, 1, 1),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _selectedBirthday = picked;
                                    _birthdayController.text = "${picked.month}/${picked.day}/${picked.year}";
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Birth Date',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.cake),
                                suffixIcon: const Icon(Icons.calendar_today),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your birthday';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            // Role selection
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Register as:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Row(
                              children: [
                                Radio<String>(
                                  value: 'buyer',
                                  groupValue: _selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                                const Text('Buyer'),
                                const SizedBox(width: 20),
                                Radio<String>(
                                  value: 'supplier',
                                  groupValue: _selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  },
                                ),
                                const Text('Supplier'),
                                const SizedBox(width: 20),
                                ///
                              ///  Radio<String>(
                              ///    value: 'admin',
                               ///   groupValue: _selectedRole,
                                ///  onChanged: (value) {
                                ///    setState(() {
                                ///      _selectedRole = value!;
                                  ///  });
                                 /// },
                               /// ),
                                ///const Text('Admin'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (val) {
                                    setState(() {
                                      _acceptTerms = val ?? false;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text('I accept the Terms and Conditions', maxLines: 2),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA7C957),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: _isLoading || !_acceptTerms ? null : _proceed,
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Sign up', style: TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? '),
                                GestureDetector(
                                  onTap: () {
                                    if (widget.onLoginTap != null) {
                                      widget.onLoginTap!();
                                    } else {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: const Text('Log in', style: TextStyle(color: Color(0xFFA7C957), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Or, Register with'),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: blue,
                            child: const Text('A', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: const Text('B', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            backgroundColor: Colors.green,
                            child: const Text('C', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VegieConnect Home'),
        backgroundColor: const Color(0xFFA7C957),
      ),
      body: const Center(
        child: Text('Welcome to VegieConnect!'),
      ),
    );
  }
} 