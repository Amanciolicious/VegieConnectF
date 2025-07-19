// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/image_storage_service.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? product;
  final String? docId;
  const AddProductPage({super.key, this.product, this.docId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  int _quantity = 0;
  String _unit = 'kg';
  String _category = 'Vegetable';
  bool _isActive = true;
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _quantity = widget.product!['quantity'] ?? 0;
      _unit = widget.product!['unit'] ?? 'kg';
      _category = widget.product!['category'] ?? 'Vegetable';
      _isActive = widget.product!['isActive'] ?? true;
      _imageUrl = widget.product!['imageUrl'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Web: Use file_picker
        final imageBytes = await ImageStorageService.pickImageFromWeb();
        if (imageBytes != null) {
          setState(() {
            _webImageBytes = imageBytes;
            _imageFile = null;
          });
        }
      } else {
        // Mobile: Use image_picker
        final imageFile = await ImageStorageService.pickImageFromGallery();
        if (imageFile != null) {
          setState(() {
            _imageFile = imageFile;
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<String?> _saveImageLocally(String productId) async {
    try {
      if (kIsWeb && _webImageBytes != null) {
        // For web, we'll still use imgbb as fallback since local storage isn't supported
        const imgbbApiKey = '624d224505d2d7ed98eb474772d79015';
        final base64Image = base64Encode(_webImageBytes!);
        final url = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
        final response = await http.post(url, body: {'image': base64Image});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['data']['url'];
        } else {
          debugPrint('imgbb upload failed: ${response.body}');
          return null;
        }
      } else if (_imageFile != null) {
        // For mobile, save to local storage
        return await ImageStorageService.saveImageFromFile(_imageFile!, productId);
      } else {
        return _imageUrl;
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
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
        title: Text('Add Product', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
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
                        Icons.add_shopping_cart,
                        size: screenWidth * 0.12,
                        color: AppColors.primaryGreen,
                      ),
                      SizedBox(height: screenWidth * 0.03),
                      Text(
                        'Add New Product',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.06,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        'List your fresh produce for customers to discover',
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
              // Product Form
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
                          'Product Details',
                          style: AppTextStyles.headline.copyWith(
                            fontSize: screenWidth * 0.055,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        // Product Name Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Product Name',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.inventory, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product name';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Description Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Product Description',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.description, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter product description';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Price Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Price per unit',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.attach_money, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Quantity Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            initialValue: _quantity.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Available Quantity',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.shopping_basket, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter quantity';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid quantity';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _quantity = int.tryParse(value) ?? 0;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Unit Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            initialValue: _unit,
                            decoration: InputDecoration(
                              hintText: 'Unit (e.g., KG, pieces)',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.straighten, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter unit';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _unit = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Category Field
                        Neumorphic(
                          style: AppNeumorphic.inset,
                          child: TextFormField(
                            initialValue: _category,
                            decoration: InputDecoration(
                              hintText: 'Category (e.g., Vegetables, Fruits)',
                              hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                              prefixIcon: Icon(Icons.category, color: AppColors.primaryGreen),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                            ),
                            style: AppTextStyles.body,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter category';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _category = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        // Image Upload Section
                        Neumorphic(
                          style: AppNeumorphic.card,
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              children: [
                                Text(
                                  'Product Image',
                                  style: AppTextStyles.headline.copyWith(
                                    fontSize: screenWidth * 0.045,
                                  ),
                                ),
                                SizedBox(height: screenWidth * 0.03),
                                if (_imageFile != null)
                                  Container(
                                    width: screenWidth * 0.3,
                                    height: screenWidth * 0.3,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                      image: DecorationImage(
                                        image: FileImage(_imageFile!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: screenWidth * 0.3,
                                    height: screenWidth * 0.3,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                    ),
                                    child: Icon(
                                      Icons.add_photo_alternate,
                                      size: screenWidth * 0.1,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                SizedBox(height: screenWidth * 0.03),
                                NeumorphicButton(
                                  style: AppNeumorphic.button.copyWith(
                                    color: AppColors.primaryGreen,
                                  ),
                                  onPressed: _pickImage,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                                    child: Text(
                                      'Select Image',
                                      style: AppTextStyles.button.copyWith(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        // Submit Button
                        NeumorphicButton(
                          style: AppNeumorphic.button.copyWith(
                            color: AppColors.primaryGreen,
                          ),
                          onPressed: _isUploading
                                ? null
                                : () async {
                            if (_formKey.currentState!.validate()) {
                              if (widget.product != null) {
                                // Show confirmation dialog before updating
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Update Product'),
                                    content: const Text('Are you sure you want to update this product?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Update'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                              }
                              setState(() => _isUploading = true);
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Not logged in!')),
                                );
                                setState(() => _isUploading = false);
                                return;
                              }
                              try {
                                // Fetch supplier name from Firestore
                                final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                                final supplierName = userDoc.data()?['name'] ?? 'Unknown Supplier';
                                if (widget.product == null) {
                                  // Add new product
                                  final docRef = await FirebaseFirestore.instance.collection('products').add({
                                    'sellerId': user.uid,
                                    'supplierName': supplierName,
                                    'name': _nameController.text.trim(),
                                    'description': _descController.text.trim(),
                                    'price': double.tryParse(_priceController.text.trim()) ?? 0,
                                    'quantity': _quantity,
                                    'unit': _unit,
                                    'category': _category,
                                    'isActive': _isActive,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    'updatedAt': FieldValue.serverTimestamp(),
                                    'imageUrl': '',
                                  });
                                  final imagePath = await _saveImageLocally(docRef.id);
                                  if (imagePath != null) {
                                    await docRef.update({'imageUrl': imagePath});
                                  }
                                } else {
                                  // Edit existing product
                                  final imagePath = await _saveImageLocally(widget.docId!);
                                  await FirebaseFirestore.instance.collection('products').doc(widget.docId!).update({
                                    'sellerId': user.uid,
                                    'supplierName': supplierName,
                                    'name': _nameController.text.trim(),
                                    'description': _descController.text.trim(),
                                    'price': double.tryParse(_priceController.text.trim()) ?? 0,
                                    'quantity': _quantity,
                                    'unit': _unit,
                                    'category': _category,
                                    'isActive': _isActive,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                    'imageUrl': imagePath ?? _imageUrl ?? '',
                                  });
                                }
                                if (!mounted) return;
                                setState(() => _isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(widget.product == null ? 'Product added!' : 'Product updated!')),
                                );
                                Navigator.pop(context);
                              } catch (e) {
                                setState(() => _isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to ${widget.product == null ? 'add' : 'update'} product: $e')),
                                );
                              }
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                            child: _isUploading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    widget.product == null ? 'Add Product' : 'Update Product',
                                    style: AppTextStyles.button.copyWith(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.045,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),],
            ),
          ),
        ),
      );
  }
} 