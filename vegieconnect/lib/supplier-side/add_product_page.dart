// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/image_storage_service.dart';
import '../widgets/product_image_widget.dart';

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
    final green = const Color(0xFFA7C957);
    final bg = const Color(0xFFF6F6F6);
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
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product', style: TextStyle(fontSize: screenWidth * 0.055, fontWeight: FontWeight.bold)),
        backgroundColor: green,
        elevation: 0,
      ),
      backgroundColor: bg,
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: cardRadius,
                      boxShadow: neumorphicShadow,
                    ),
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: _webImageBytes != null
                        ? Image.memory(_webImageBytes!, width: screenWidth * 0.3, height: screenWidth * 0.3, fit: BoxFit.cover)
                        : _imageFile != null
                            ? Image.file(_imageFile!, width: screenWidth * 0.3, height: screenWidth * 0.3, fit: BoxFit.cover)
                            : ProductImageWidget(
                                imagePath: _imageUrl ?? '',
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                              ),
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.03),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Product Name', border: OutlineInputBorder(borderRadius: cardRadius)),
                validator: (value) => value == null || value.isEmpty ? 'Enter product name' : null,
                style: TextStyle(fontSize: screenWidth * 0.045),
              ),
              SizedBox(height: screenWidth * 0.03),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: cardRadius)),
                maxLines: 2,
                style: TextStyle(fontSize: screenWidth * 0.045),
              ),
              SizedBox(height: screenWidth * 0.03),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText: '₱ ',
                  border: OutlineInputBorder(borderRadius: cardRadius),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Enter price' : null,
                style: TextStyle(fontSize: screenWidth * 0.045),
              ),
              SizedBox(height: screenWidth * 0.03),
              Row(
                children: [
                  Text('Quantity', style: TextStyle(fontSize: screenWidth * 0.045)),
                  SizedBox(width: screenWidth * 0.04),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: cardRadius,
                      color: Colors.white,
                      boxShadow: neumorphicShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, size: screenWidth * 0.06),
                          onPressed: _quantity > 0 ? () => setState(() => _quantity--) : null,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                          child: Text('$_quantity', style: TextStyle(fontSize: screenWidth * 0.045)),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, size: screenWidth * 0.06),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              DropdownButtonFormField<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                ],
                onChanged: (val) => setState(() => _unit = val ?? 'kg'),
                decoration: InputDecoration(labelText: 'Unit', border: OutlineInputBorder(borderRadius: cardRadius)),
                style: TextStyle(fontSize: screenWidth * 0.045),
              ),
              SizedBox(height: screenWidth * 0.03),
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'Vegetable', child: Text('Vegetable')),
                  DropdownMenuItem(value: 'Fruit', child: Text('Fruit')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _category = val ?? 'Vegetable'),
                decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: cardRadius)),
                style: TextStyle(fontSize: screenWidth * 0.045),
              ),
              SizedBox(height: screenWidth * 0.03),
              SwitchListTile(
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                title: Text('Active', style: TextStyle(fontSize: screenWidth * 0.045)),
                contentPadding: EdgeInsets.zero,
              ),
              SizedBox(height: screenWidth * 0.05),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(fontSize: screenWidth * 0.045)),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  ElevatedButton(
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
                    style: ElevatedButton.styleFrom(backgroundColor: green),
                    child: _isUploading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.product == null ? 'Add' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 