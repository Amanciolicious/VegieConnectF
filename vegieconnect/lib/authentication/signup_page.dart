// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vegieconnect/customer-side/contact_info_page.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

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
  final bool _acceptTerms = false;

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
        'isNewlyRegistered': true, // Track newly registered users
        'onboardingCompleted': false, // Track onboarding completion
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Create Account', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),
              // Welcome Section
              Neumorphic(
                style: AppNeumorphic.card,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco,
                        size: screenWidth * 0.12,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Text(
                        'Join VegieConnect',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.06,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        'Connect with fresh produce from local farms',
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
              SizedBox(height: screenHeight * 0.04),
              // Signup Form
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Account Details',
                          style: AppTextStyles.headline.copyWith(
                            fontSize: screenWidth * 0.055,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        // Full Name Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.person, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Email Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Email Address',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.email, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
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
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Password Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.lock, color: AppColors.primaryGreen),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.primaryGreen,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
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
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Confirm Password Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _passwordController, // This controller is used for both password and confirm password
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryGreen),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.primaryGreen,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Phone Number Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
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
                              hintText: 'Birth Date',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.cake, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select your birthday';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Role Selection
                        Text(
                          'I want to:',
                          style: AppTextStyles.body.copyWith(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Row(
                          children: [
                            Expanded(
                              child: NeumorphicButton(
                                style: AppNeumorphic.button.copyWith(
                                  color: _selectedRole == 'buyer' ? AppColors.primaryGreen : Colors.transparent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedRole = 'buyer';
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                                  child: Text(
                                    'Buy Products',
                                    style: AppTextStyles.body.copyWith(
                                      color: _selectedRole == 'buyer' ? Colors.white : AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: NeumorphicButton(
                                style: AppNeumorphic.button.copyWith(
                                  color: _selectedRole == 'supplier' ? AppColors.primaryGreen : Colors.transparent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _selectedRole = 'supplier';
                                  });
                                },
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                                  child: Text(
                                    'Sell Products',
                                    style: AppTextStyles.body.copyWith(
                                      color: _selectedRole == 'supplier' ? Colors.white : AppColors.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        // Sign Up Button
                        NeumorphicButton(
                          style: AppNeumorphic.button.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                          onPressed: _isLoading ? null : _proceed,
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
                                    'Sign up',
                                    style: AppTextStyles.button.copyWith(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTextStyles.body.copyWith(
                                fontSize: screenWidth * 0.035,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (widget.onLoginTap != null) {
                                  widget.onLoginTap!();
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: Text(
                                'Log in',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primaryGreen,
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        backgroundColor: AppColors.primaryGreen,
      ),
      body: const Center(
        child: Text('Welcome to VegieConnect!'),
      ),
    );
  }
} 