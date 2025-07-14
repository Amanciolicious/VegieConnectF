// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../authentication/pin_verify_page.dart';

class ContactInfoPage extends StatefulWidget {
  final String userId;
  const ContactInfoPage({super.key, required this.userId});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _streetController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
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
        'phone': _phoneController.text.trim(),
        'country': _countryController.text.trim(),
        'city': _cityController.text.trim(),
        'postalCode': _postalController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final green = const Color(0xFFA7C957);
    final cardRadius = BorderRadius.circular(screenWidth * 0.05);
    final neumorphicShadow = [
      BoxShadow(
        color: Colors.grey.shade300,
        offset: Offset(screenWidth * 0.015, screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
      BoxShadow(
        color: Colors.white,
        offset: Offset(-screenWidth * 0.015, -screenWidth * 0.015),
        blurRadius: screenWidth * 0.04,
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: screenWidth * 0.5,
              height: screenHeight * 0.22,
              decoration: BoxDecoration(
                color: green.withOpacity(0.2),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(screenWidth * 0.18),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: screenWidth * 0.08),
                  // Header icon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: cardRadius,
                      boxShadow: neumorphicShadow,
                    ),
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: Icon(Icons.location_on, size: screenWidth * 0.11, color: green),
                  ),
                  SizedBox(height: screenWidth * 0.045),
                  Text(
                    'Billing Address',
                    style: TextStyle(
                      fontSize: screenWidth * 0.065,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing sed diam nonummy nibh euismod tincidunt.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.black54),
                  ),
                  SizedBox(height: screenWidth * 0.06),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: cardRadius,
                      boxShadow: neumorphicShadow,
                    ),
                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.08),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Contact Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                            ),
                            SizedBox(height: screenWidth * 0.045),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: cardRadius,
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.phone, size: screenWidth * 0.06),
                              ),
                              style: TextStyle(fontSize: screenWidth * 0.04),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            TextFormField(
                              controller: _countryController,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: cardRadius,
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.public, size: screenWidth * 0.06),
                              ),
                              style: TextStyle(fontSize: screenWidth * 0.04),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your country';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _cityController,
                                    decoration: InputDecoration(
                                      labelText: 'City',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: cardRadius,
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: TextStyle(fontSize: screenWidth * 0.04),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter city';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Expanded(
                                  child: TextFormField(
                                    controller: _postalController,
                                    decoration: InputDecoration(
                                      labelText: 'Postal Code',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: cardRadius,
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: TextStyle(fontSize: screenWidth * 0.04),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter postal code';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenWidth * 0.03),
                            TextFormField(
                              controller: _streetController,
                              decoration: InputDecoration(
                                labelText: 'Street Address',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: cardRadius,
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Icon(Icons.home, size: screenWidth * 0.06),
                              ),
                              maxLines: 2,
                              style: TextStyle(fontSize: screenWidth * 0.04),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your street address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: screenWidth * 0.045),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                              ),
                            if (_successMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(_successMessage!, style: const TextStyle(color: Colors.green)),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: green,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 2,
                                ),
                                onPressed: _isLoading ? null : _saveContactInfo,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Save & Confirm',
                                        style: TextStyle(fontSize: 18, color: Colors.white, letterSpacing: 1.2),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 