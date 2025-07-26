// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../theme.dart';
import '../services/image_storage_service.dart';
import '../services/content_filter_service.dart';
import '../services/auto_approval_service.dart';

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
  final _quantityController = TextEditingController(); // Add quantity controller
  int _quantity = 0;
  String _unit = 'kg';
  String _category = 'Vegetable';
  bool _isActive = true;
  File? _imageFile;
  Uint8List? _webImageBytes;
  String? _imageUrl;
  bool _isUploading = false;
  String? _rejectionReason;

  // Predefined categories and units
  static const List<String> _categories = [
    'Vegetable',
    'Fruit',
    'Herbs & Spices',
    'Root Crops',
    'Leafy Greens',
    'Legumes',
    'Grains',
    'Organic',
    'Local Produce',
    'Seasonal',
  ];

  static const List<String> _units = [
    'kg',
    'pieces',
    'sack',
    'bundle',
    'dozen',
    'pack',
    'box',
    'bag',
    'gram',
    'pound',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!['name'] ?? '';
      _descController.text = widget.product!['description'] ?? '';
      _priceController.text = widget.product!['price']?.toString() ?? '';
      _quantity = widget.product!['quantity'] ?? 0;
      _quantityController.text = _quantity.toString(); // Initialize quantity controller
      _unit = widget.product!['unit'] ?? 'kg';
      _category = widget.product!['category'] ?? 'Vegetable';
      _isActive = widget.product!['isActive'] ?? true;
      _imageUrl = widget.product!['imageUrl'];
      _rejectionReason = widget.product!['rejectionReason'];
    } else {
      _quantityController.text = '0'; // Set default value
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _quantityController.dispose(); // Dispose quantity controller
    super.dispose();
  }

  void _incrementQuantity() {
    setState(() {
      if (_quantity < 999999) { // Add reasonable maximum limit
        _quantity++;
        _quantityController.text = _quantity.toString();
      }
    });
  }

  void _decrementQuantity() {
    if (_quantity > 0) {
      setState(() {
        _quantity--;
        _quantityController.text = _quantity.toString();
      });
    }
  }

  void _updateQuantity(String value) {
    final newQuantity = int.tryParse(value) ?? 0;
    // Clamp the quantity between 0 and 999999
    final clampedQuantity = newQuantity.clamp(0, 999999);
    setState(() {
      _quantity = clampedQuantity;
      // Only update controller if it's different to avoid cursor jumping
      if (_quantityController.text != clampedQuantity.toString()) {
        _quantityController.text = clampedQuantity.toString();
      }
    });
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Available Quantity',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * 0.04,
                                    ),
                                  ),
                                  Text(
                                    'Range: 0 - 999,999',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: screenWidth * 0.03,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Neumorphic(
                              style: AppNeumorphic.inset,
                              child: Row(
                            children: [
                              Expanded(
                                child: NeumorphicButton(
                                  style: AppNeumorphic.button.copyWith(
                                    color: _quantity > 0 ? AppColors.primaryGreen : Colors.grey,
                                  ),
                                  onPressed: _quantity > 0 ? _decrementQuantity : null,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                                    child: Text(
                                      '-',
                                      style: AppTextStyles.button.copyWith(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: Neumorphic(
                                  style: AppNeumorphic.inset,
                                  child: TextFormField(
                                    controller: _quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      hintText: 'Quantity',
                                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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
                                      final quantity = int.tryParse(value) ?? 0;
                                      if (quantity < 0) {
                                        return 'Quantity cannot be negative';
                                      }
                                      if (quantity > 999999) {
                                        return 'Quantity too high (max: 999,999)';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      _updateQuantity(value);
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Expanded(
                                child: NeumorphicButton(
                                  style: AppNeumorphic.button.copyWith(
                                    color: _quantity < 999999 ? AppColors.primaryGreen : Colors.grey,
                                  ),
                                  onPressed: _quantity < 999999 ? _incrementQuantity : null,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                                    child: Text(
                                      '+',
                                      style: AppTextStyles.button.copyWith(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.04,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Unit Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                              child: Text(
                                'Unit of Measurement',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ),
                            Neumorphic(
                          style: AppNeumorphic.inset,
                          child: InkWell(
                            onTap: () async {
                              final selectedUnit = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Select Unit'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _units.length,
                                      itemBuilder: (context, index) {
                                        final unit = _units[index];
                                        return ListTile(
                                          leading: Icon(
                                            Icons.straighten,
                                            color: AppColors.primaryGreen,
                                          ),
                                          title: Text(unit),
                                          selected: unit == _unit,
                                          onTap: () => Navigator.pop(context, unit),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                              if (selectedUnit != null) {
                                setState(() {
                                  _unit = selectedUnit;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                              child: Row(
                                children: [
                                  Icon(Icons.straighten, color: AppColors.primaryGreen),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Text(
                                      _unit,
                                      style: AppTextStyles.body.copyWith(
                                        color: _unit.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        // Category Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: screenWidth * 0.02),
                              child: Text(
                                'Product Category',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ),
                            Neumorphic(
                          style: AppNeumorphic.inset,
                          child: InkWell(
                            onTap: () async {
                              final selectedCategory = await showDialog<String>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Select Category'),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _categories.length,
                                      itemBuilder: (context, index) {
                                        final category = _categories[index];
                                        return ListTile(
                                          leading: Icon(
                                            Icons.category,
                                            color: AppColors.primaryGreen,
                                          ),
                                          title: Text(category),
                                          selected: category == _category,
                                          onTap: () => Navigator.pop(context, category),
                                        );
                                      },
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                              if (selectedCategory != null) {
                                setState(() {
                                  _category = selectedCategory;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.04),
                              child: Row(
                                children: [
                                  Icon(Icons.category, color: AppColors.primaryGreen),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Text(
                                      _category,
                                      style: AppTextStyles.body.copyWith(
                                        color: _category.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        // Show rejection reason if product is rejected
                        if ((widget.product?['status'] ?? '') == 'rejected' && _rejectionReason != null && _rejectionReason!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Rejected: $_rejectionReason',
                                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
                                // Fetch supplier name and trust status from Firestore
                                final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                                final supplierName = userDoc.data()?['name'] ?? 'Unknown Supplier';
                                final isTrusted = userDoc.data()?['isTrusted'] == true;

                                // --- Automatic Assessment Logic ---
                                final prohibitedKeywords = ['illegal', 'banned', 'prohibited'];
                                final name = _nameController.text.trim();
                                final desc = _descController.text.trim();
                                final price = double.tryParse(_priceController.text.trim()) ?? 0;
                                final hasAllFields = name.isNotEmpty && desc.isNotEmpty && price > 0 && _quantity > 0 && _unit.isNotEmpty && _category.isNotEmpty;
                                final priceValid = price > 0 && price < 10000;
                                // Content filtering
                                final contentFilterService = ContentFilterService();
                                final contentCheck = contentFilterService.checkProductContent(
                                  productName: name,
                                  description: desc,
                                  supplierId: user.uid,
                                  category: _category,
                                  price: price,
                                );

                                final noProhibited = !prohibitedKeywords.any((word) => name.toLowerCase().contains(word) || desc.toLowerCase().contains(word));
                                // For image, check if _imageFile or _webImageBytes or _imageUrl is present
                                final hasImage = (_imageFile != null) || (_webImageBytes != null) || ((_imageUrl ?? '').isNotEmpty);

                                String status = 'pending';
                                bool isVerified = false;
                                bool contentFlagged = false;
                                bool autoApproved = false;

                                // Auto-approve if content is clean and supplier is trusted
                                if (hasAllFields && priceValid && noProhibited && hasImage && isTrusted && contentCheck.isApproved) {
                                  status = 'approved';
                                  isVerified = true;
                                  autoApproved = true;
                                } else if (contentCheck.issues.isNotEmpty) {
                                  contentFlagged = true;
                                  status = 'pending';
                                  isVerified = false;
                                } else {
                                  // For non-trusted suppliers, products remain pending for manual review
                                  status = 'pending';
                                  isVerified = false;
                                  autoApproved = false;
                                }

                                if (widget.product == null || (widget.product?['status'] ?? '') == 'rejected') {
                                  // Add new product or resubmit rejected product
                                  final docRef = widget.product == null
                                      ? await FirebaseFirestore.instance.collection('products').add({
                                          'sellerId': user.uid,
                                          'supplierName': supplierName,
                                          'name': name,
                                          'description': desc,
                                          'price': price,
                                          'quantity': _quantity,
                                          'unit': _unit,
                                          'category': _category,
                                          'isActive': _isActive,
                                          'createdAt': FieldValue.serverTimestamp(),
                                          'updatedAt': FieldValue.serverTimestamp(),
                                          'imageUrl': '',
                                          'status': status,
                                          'isVerified': isVerified,
                                          'rejectionReason': '',
                                          'contentFlagged': contentFlagged,
                                          'autoApproved': autoApproved,
                                          'contentIssues': contentCheck.issues,
                                          'contentSeverity': contentCheck.severity.toString(),
                                          'isTrustedSupplier': contentCheck.isTrustedSupplier,
                                          'requiresManualReview': contentCheck.requiresManualReview,
                                        })
                                      : FirebaseFirestore.instance.collection('products').doc(widget.docId!);
                                  final imagePath = await _saveImageLocally(widget.product == null ? docRef.id : widget.docId!);
                                  if (imagePath != null) {
                                    if (widget.product == null) {
                                      await docRef.update({'imageUrl': imagePath});
                                    } else {
                                      await docRef.update({
                                        'imageUrl': imagePath, 
                                        'status': status, 
                                        'isVerified': isVerified, 
                                        'rejectionReason': '',
                                        'contentFlagged': contentFlagged,
                                        'autoApproved': autoApproved,
                                        'contentIssues': contentCheck.issues,
                                        'contentSeverity': contentCheck.severity.toString(),
                                        'isTrustedSupplier': contentCheck.isTrustedSupplier,
                                        'requiresManualReview': contentCheck.requiresManualReview,
                                      });
                                    }
                                  } else if (widget.product != null) {
                                    await docRef.update({
                                      'status': status, 
                                      'isVerified': isVerified, 
                                      'rejectionReason': '',
                                      'contentFlagged': contentFlagged,
                                      'autoApproved': autoApproved,
                                      'contentIssues': contentCheck.issues,
                                      'contentSeverity': contentCheck.severity.toString(),
                                      'isTrustedSupplier': contentCheck.isTrustedSupplier,
                                      'requiresManualReview': contentCheck.requiresManualReview,
                                    });
                                  }

                                } else {
                                  // Edit existing product (not rejected)
                                  final imagePath = await _saveImageLocally(widget.docId!);
                                  await FirebaseFirestore.instance.collection('products').doc(widget.docId!).update({
                                    'sellerId': user.uid,
                                    'supplierName': supplierName,
                                    'name': name,
                                    'description': desc,
                                    'price': price,
                                    'quantity': _quantity,
                                    'unit': _unit,
                                    'category': _category,
                                    'isActive': _isActive,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                    'imageUrl': imagePath ?? _imageUrl ?? '',
                                    'status': status,
                                    'isVerified': isVerified,
                                    'contentFlagged': contentFlagged,
                                    'autoApproved': autoApproved,
                                    'contentIssues': contentCheck.issues,
                                    'contentSeverity': contentCheck.severity.toString(),
                                    'isTrustedSupplier': contentCheck.isTrustedSupplier,
                                    'requiresManualReview': contentCheck.requiresManualReview,
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
                          ]),
                ]),
            ]),
          ),
          ),
        ),
      ],
    )
          ),
        ),
      
    );
  }
  
}