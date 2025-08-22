// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vegieconnect/theme.dart'; // For AppColors
import 'package:image_picker/image_picker.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/services/image_storage_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _avatarUrl;
  String? _localAvatarPath;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocalProfileImage();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final localPath = await ImageStorageService.getProfileImage(user.uid);
      if (localPath != null) {
        setState(() {
          _localAvatarPath = localPath;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    if (kIsWeb) {
      await _pickImageWeb();
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primaryGreen),
              title: Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primaryGreen),
              title: Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageWeb() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final bytes = await ImageStorageService.pickImageFromWeb();
      if (bytes == null) return;

      final url = await ImageStorageService.uploadProfileImage(bytes: bytes, userId: user.uid);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'avatarUrl': url});

      setState(() {
        _avatarUrl = url;
        _localAvatarPath = null; // web doesn't use local path
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: $e')),
      );
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final imageFile = await ImageStorageService.pickProfileImage(
        fromCamera: source == ImageSource.camera,
      );
      
      if (imageFile != null) {
        // Upload to Firebase Storage for cross-platform access
        final url = await ImageStorageService.uploadProfileImage(file: imageFile, userId: user.uid);

        // Save to local storage for faster reloads on mobile
        final localPath = await ImageStorageService.saveProfileImageFromFile(imageFile, user.uid);
        await ImageStorageService.deleteOldProfileImages(user.uid);

        // Update Firestore profile
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'avatarUrl': url});

        setState(() {
          _localAvatarPath = localPath;
          _avatarUrl = url;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile image: $e')),
      );
    }
  }

  ImageProvider? _getProfileImage(Map<String, dynamic> data) {
    // Priority: Local image > Network image
    if (_localAvatarPath != null) {
      final file = ImageStorageService.loadImageFromPath(_localAvatarPath!);
      if (file != null) {
        return FileImage(file);
      }
    }
    
    if (data['avatarUrl'] != null) {
      return NetworkImage(data['avatarUrl']);
    }
    
    return null;
  }

  void _showEditProfile(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? '';
    _emailController.text = data['email'] ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                  backgroundImage: _getProfileImage(data),
                  child: _getProfileImage(data) == null ? Icon(Icons.camera_alt, color: AppColors.primaryGreen, size: 32) : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({'name': _nameController.text.trim()});
                    
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = FirebaseAuth.instance.currentUser;
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No profile data found.'));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primaryGreen,
            title: Text('Profile', style: AppTextStyles.headline.copyWith(color: Colors.white)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Neumorphic(
                  style: AppNeumorphic.card.copyWith(
                    boxShape: NeumorphicBoxShape.circle(),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.1),
                    backgroundImage: _getProfileImage(data),
                    child: _getProfileImage(data) == null ? Icon(Icons.person, color: AppColors.primaryGreen, size: 48) : null,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.edit, color: AppColors.primaryGreen),
                  onPressed: () => _showEditProfile(data),
                ),
              ),
              const SizedBox(height: 18),
              Neumorphic(
                style: AppNeumorphic.card,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Name: ${data['name'] ?? ''}', style: AppTextStyles.headline.copyWith(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Email: ${data['email'] ?? ''}', style: AppTextStyles.body.copyWith(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Role: ${data['role'] ?? ''}', style: AppTextStyles.body.copyWith(fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text('Order History', style: AppTextStyles.headline.copyWith(fontSize: 18)),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('buyerId', isEqualTo: user.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return ListTile(
                      leading: Icon(Icons.receipt_long, color: AppColors.primaryGreen),
                      title: Text('No orders yet.', style: AppTextStyles.body),
                    );
                  }
                  final orders = snapshot.data!.docs;
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => SizedBox(height: screenWidth * 0.02),
                    itemBuilder: (context, index) {
                      final order = orders[index].data() as Map<String, dynamic>;
                      final status = order['status'] ?? 'pending';
                      Color statusColor;
                      switch (status) {
                        case 'completed':
                          statusColor = Colors.green;
                          break;
                        case 'processing':
                          statusColor = Colors.orange;
                          break;
                        case 'cancelled':
                          statusColor = Colors.red;
                          break;
                        default:
                          statusColor = Colors.grey;
                      }
                      return Neumorphic(
                        style: AppNeumorphic.card,
                        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.03),
                          leading: Icon(Icons.receipt_long, color: AppColors.primaryGreen, size: screenWidth * 0.09),
                          title: Text(order['productName'] ?? '', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.045)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Qty: ${order['quantity']} ${order['unit']}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
                              Text('\u20b1${order['price']?.toStringAsFixed(2) ?? '0.00'}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04)),
                              Text('Status: $status', style: AppTextStyles.body.copyWith(color: statusColor, fontSize: screenWidth * 0.04)),
                              Text('Payment: ${order['paymentMethod'] == 'cash_on_pickup' ? 'Cash on Pick Up' : (order['paymentMethod'] ?? 'N/A')}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.038)),
                              Text('Payment Status: ${order['paymentStatus'] ?? 'N/A'}', style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.038)),
                            ],
                          ),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.015),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(screenWidth * 0.04),
                            ),
                            child: Text(
                              status,
                              style: AppTextStyles.body.copyWith(fontSize: screenWidth * 0.04, color: statusColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: NeumorphicButton(
                  style: AppNeumorphic.button.copyWith(
                    color: AppColors.primaryGreen,
                    boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/login');
                    }
                  },
                  child: Text('Logout', style: AppTextStyles.button.copyWith(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 