import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final _quantityController = TextEditingController();
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
      _quantityController.text = widget.product!['quantity']?.toString() ?? '';
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
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Web: Use file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _webImageBytes = result.files.single.bytes;
          _imageFile = null;
        });
      }
    } else {
      // Mobile: Use image_picker
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<String?> _uploadImage(String productId) async {
    const imgbbApiKey = '624d224505d2d7ed98eb474772d79015';
    Uint8List? imageBytes;
    if (kIsWeb && _webImageBytes != null) {
      imageBytes = _webImageBytes;
    } else if (_imageFile != null) {
      imageBytes = await _imageFile!.readAsBytes();
    } else {
      return _imageUrl;
    }
    final base64Image = base64Encode(imageBytes!);
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$imgbbApiKey');
    final response = await http.post(url, body: {'image': base64Image});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']['url'];
    } else {
      debugPrint('imgbb upload failed: \\${response.body}');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final green = const Color(0xFFA7C957);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product != null ? 'Edit Product' : 'Add Product'),
        backgroundColor: green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: kIsWeb
                      ? (_webImageBytes != null
                          ? Image.memory(_webImageBytes!, width: 120, height: 120, fit: BoxFit.cover)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? Image.network(_imageUrl!, width: 120, height: 120, fit: BoxFit.cover)
                              : Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                ))
                      : (_imageFile != null
                          ? Image.file(_imageFile!, width: 120, height: 120, fit: BoxFit.cover)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? Image.network(_imageUrl!, width: 120, height: 120, fit: BoxFit.cover)
                              : Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                                )),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter product name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Enter price' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Enter quantity' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _unit,
                items: const [
                  DropdownMenuItem(value: 'kg', child: Text('kg')),
                  DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                  DropdownMenuItem(value: 'g', child: Text('g')),
                ],
                onChanged: (val) => setState(() => _unit = val ?? 'kg'),
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                items: const [
                  DropdownMenuItem(value: 'Vegetable', child: Text('Vegetable')),
                  DropdownMenuItem(value: 'Fruit', child: Text('Fruit')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _category = val ?? 'Vegetable'),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
                title: const Text('Active'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isUploading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isUploading = true);
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Not logged in!')),
                                );
                                setState(() => _isUploading = false);
                                return;
                              }
                              if (widget.product == null) {
                                // Add new product
                                final docRef = await FirebaseFirestore.instance.collection('products').add({
                                  'sellerId': user.uid,
                                  'name': _nameController.text.trim(),
                                  'description': _descController.text.trim(),
                                  'price': double.tryParse(_priceController.text.trim()) ?? 0,
                                  'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
                                  'unit': _unit,
                                  'category': _category,
                                  'isActive': _isActive,
                                  'createdAt': FieldValue.serverTimestamp(),
                                  'updatedAt': FieldValue.serverTimestamp(),
                                  'imageUrl': '',
                                });
                                final imageUrl = await _uploadImage(docRef.id);
                                if (imageUrl != null) {
                                  await docRef.update({'imageUrl': imageUrl});
                                }
                              } else {
                                // Edit existing product
                                final imageUrl = await _uploadImage(widget.docId!);
                                await FirebaseFirestore.instance.collection('products').doc(widget.docId!).update({
                                  'name': _nameController.text.trim(),
                                  'description': _descController.text.trim(),
                                  'price': double.tryParse(_priceController.text.trim()) ?? 0,
                                  'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
                                  'unit': _unit,
                                  'category': _category,
                                  'isActive': _isActive,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                  'imageUrl': imageUrl ?? '',
                                });
                              }
                              if (!mounted) return;
                              setState(() => _isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(widget.product == null ? 'Product added!' : 'Product updated!')),
                              );
                              Navigator.pop(context);
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