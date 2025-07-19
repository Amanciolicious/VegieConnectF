import 'package:firebase_auth/firebase_auth.dart';
import '../customer-side/contact_info_page.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/authentication/login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  final String userId;
  final String email;
  const VerifyEmailPage({super.key, required this.userId, required this.email});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  Future<void> _checkVerified() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ContactInfoPage(userId: widget.userId),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Email not verified yet.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() {
        _infoMessage = 'Verification email resent!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to resend email.';
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
              SizedBox(height: screenHeight * 0.1),
              // Header Section
              Neumorphic(
                style: AppNeumorphic.card,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.08),
                  child: Column(
                    children: [
                      Icon(
                        Icons.email,
                        size: screenWidth * 0.15,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      Text(
                        'Verify Your Email',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.06,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        'We\'ve sent a verification link to your email',
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
              // Email Display
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    children: [
                      Text(
                        'Email Address',
                        style: AppTextStyles.body.copyWith(
                          fontSize: screenWidth * 0.04,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        widget.email,
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.045,
                          color: AppColors.primaryGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              // Instructions
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    children: [
                      Text(
                        'What to do next:',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.05,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      _buildInstructionItem(screenWidth, '1', 'Check your email inbox', Icons.inbox),
                      SizedBox(height: screenWidth * 0.02),
                      _buildInstructionItem(screenWidth, '2', 'Click the verification link', Icons.link),
                      SizedBox(height: screenWidth * 0.02),
                      _buildInstructionItem(screenWidth, '3', 'Return to the app', Icons.arrow_back),
                    ],
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.04),
              // Action Buttons
              Column(
                children: [
                  NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: _isLoading ? null : _checkVerified,
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
                              'I\'ve Verified My Email',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                                fontSize: screenWidth * 0.045,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: Colors.transparent,
                    ),
                    onPressed: _resendEmail,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                      child: Text(
                        'Resend Verification Email',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primaryGreen,
                          fontSize: screenWidth * 0.045,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Login',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(double screenWidth, String number, String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: screenWidth * 0.08,
          height: screenWidth * 0.08,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          child: Center(
            child: Text(
              number,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.04),
        Icon(icon, color: AppColors.primaryGreen, size: screenWidth * 0.05),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              fontSize: screenWidth * 0.04,
            ),
          ),
        ),
      ],
    );
  }
} 