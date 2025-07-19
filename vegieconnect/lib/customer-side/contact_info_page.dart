// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import '../authentication/pin_verify_page.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class ContactInfoPage extends StatefulWidget {
  final String userId;
  const ContactInfoPage({super.key, required this.userId});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _postalController = TextEditingController();
  final _streetController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    _postalController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _saveContactInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'fullName': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'postalCodeAlt': _postalController.text.trim(),
        'streetAddress': _streetController.text.trim(),
      });
      setState(() {
        _successMessage = 'Contact information saved! Redirecting to verification...';
        _isLoading = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      // Fetch email from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final email = userDoc.data()?['email'] ?? '';
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PinVerifyPage(userId: widget.userId, email: email)),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save contact info.';
        _isLoading = false;
      });
    }
  }

  Future<void> _skipContactInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Fetch email from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      final email = userDoc.data()?['email'] ?? '';
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => PinVerifyPage(userId: widget.userId, email: email)),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to skip contact info.';
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
        title: Text('Contact Information', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.02),
              // Header Section
              Neumorphic(
                style: AppNeumorphic.card,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    children: [
                      Icon(
                        Icons.contact_phone,
                        size: screenWidth * 0.12,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Text(
                        'Complete Your Profile',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.06,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        'Add your contact information for better service',
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
              // Contact Form
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
                          'Contact Details',
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
                            controller: _fullNameController,
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
                        // Phone Number Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Phone Number',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.phone, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Address Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _addressController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Complete Address',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.location_on, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your address';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // City Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              hintText: 'City',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.location_city, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your city';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Province Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _provinceController,
                            decoration: InputDecoration(
                              hintText: 'Province',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.map, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your province';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Postal Code Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _postalCodeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Postal Code',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.pin_drop, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your postal code';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        // Save Button
                        NeumorphicButton(
                          style: AppNeumorphic.button.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                          onPressed: _isLoading ? null : _saveContactInfo,
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
                                    'Save Contact Information',
                                    style: AppTextStyles.button.copyWith(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Skip Button
                        NeumorphicButton(
                          style: AppNeumorphic.button.copyWith(
                            color: Colors.transparent,
                          ),
                          onPressed: _skipContactInfo,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                            child: Text(
                              'Skip for Now',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: screenWidth * 0.045,
                              ),
                            ),
                          ),
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