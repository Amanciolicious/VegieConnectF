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
    final green = const Color(0xFFA7C957);
    final blue = const Color(0xFF2196F3);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
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
                  // Header icon
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.location_on, size: 40, color: green),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Billing Address',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing sed diam nonummy nibh euismod tincidunt.',
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
                              child: Text('Contact Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.phone),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _countryController,
                              decoration: InputDecoration(
                                labelText: 'Country',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.public),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your country';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
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
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Enter city';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _postalController,
                                    decoration: InputDecoration(
                                      labelText: 'Postal Code',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
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
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _streetController,
                              decoration: InputDecoration(
                                labelText: 'Street Address',
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.home),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your street address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
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