import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../customer-side/landing_page.dart';
import '../customer-side/onboarding_page.dart';
import '../admin-side/admin_dashboard.dart';
import '../supplier-side/supplier_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Check Firestore for verification and role
      final doc = await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).get();
      final data = doc.data();
      if (data == null || data['verified'] != true) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _isLoading = false;
        });
        return;
      }
      if (!mounted) return;
      
      // Route based on user role
      final userRole = data['role'] ?? 'buyer';
      
      if (userRole == 'admin') {
        // Admins go directly to admin dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else if (userRole == 'supplier') {
        // Suppliers go to supplier dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SupplierDashboard()),
        );
      } else {
        // Buyers follow normal flow
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
        if (onboardingDone) {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LandingPage()),
          );
        } else {
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const OnboardingPage()),
          );
        }
      }
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.08),
              // Logo and Title
              Neumorphic(
                style: AppNeumorphic.card,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.08),
                  child: Column(
                    children: [
                      Icon(
                        Icons.eco,
                        size: screenWidth * 0.15,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        'VegieConnect',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.08,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        'Fresh from Farm to Table',
                        style: AppTextStyles.body.copyWith(
                          fontSize: screenWidth * 0.04,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.06),
              // Login Form
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.06,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      // Email Field
                      Neumorphic(
                        style: AppNeumorphic.inset,
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                            prefixIcon: Icon(Icons.email, color: AppColors.primaryGreen),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                          ),
                          style: AppTextStyles.body,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      // Password Field
                      Neumorphic(
                        style: AppNeumorphic.inset,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                            prefixIcon: Icon(Icons.lock, color: AppColors.primaryGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.primaryGreen,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                          ),
                          style: AppTextStyles.body,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primaryGreen,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.05),
                      // Login Button
                      NeumorphicButton(
                        style: AppNeumorphic.button.copyWith(
                          color: AppColors.primaryGreen,
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
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
                                  'Login',
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.045,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      // Or Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.textSecondary)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                            child: Text(
                              'OR',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: screenWidth * 0.035,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.textSecondary)),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      // Sign Up Button
                      NeumorphicButton(
                        style: AppNeumorphic.button.copyWith(
                          color: Colors.transparent,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>  SignUpPage()),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                          child: Text(
                            'Create Account',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.primaryGreen,
                              fontSize: screenWidth * 0.045,
                            ),
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