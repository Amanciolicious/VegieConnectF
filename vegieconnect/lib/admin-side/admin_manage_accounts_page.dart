import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:path/path.dart';
import 'package:vegieconnect/theme.dart';

class AdminManageAccountsPage extends StatelessWidget {
  const AdminManageAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Manage Accounts', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Accounts',
              style: AppTextStyles.headline.copyWith(fontSize: screenWidth * 0.06),
            ),
            SizedBox(height: screenWidth * 0.04),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Neumorphic(
                        style: AppNeumorphic.card,
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.08),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people,
                                size: screenWidth * 0.15,
                                color: AppColors.primaryGreen,
                              ),
                              SizedBox(height: screenWidth * 0.04),
                              Text(
                                'No Users',
                                style: AppTextStyles.headline.copyWith(
                                  fontSize: screenWidth * 0.06,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              Text(
                                'No user accounts found',
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
                    );
                  }

                  final users = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index].data() as Map<String, dynamic>;
                      return _buildUserCard(screenWidth, users[index].id, user);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(double screenWidth, String userId, Map<String, dynamic> user) {
    final createdAt = user['createdAt'] as Timestamp?;
    final date = createdAt?.toDate() ?? DateTime.now();
    
    return Neumorphic(
      style: AppNeumorphic.card,
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header
            Row(
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.04,
                  backgroundColor: AppColors.primaryGreen,
                  child: Text(
                    (user['fullName'] ?? 'U')[0].toUpperCase(),
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['fullName'] ?? 'Unknown User',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.045,
                        ),
                      ),
                      Text(
                        user['email'] ?? 'No email',
                        style: AppTextStyles.body.copyWith(
                          fontSize: screenWidth * 0.035,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user['role']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Text(
                    user['role'] ?? 'User',
                    style: AppTextStyles.body.copyWith(
                      fontSize: screenWidth * 0.035,
                      color: _getRoleColor(user['role']),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            // User Details
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone, size: screenWidth * 0.04, color: AppColors.primaryGreen),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Phone: ${user['phone'] ?? 'Not provided'}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: screenWidth * 0.035,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: screenWidth * 0.04, color: AppColors.primaryGreen),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Joined: ${date.day}/${date.month}/${date.year}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: screenWidth * 0.035,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: user['isActive'] == true ? Colors.red : AppColors.primaryGreen,
                    ),
                    onPressed: () => _toggleUserStatus(userId, user['isActive'] != true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      child: Text(
                        user['isActive'] == true ? 'Deactivate' : 'Activate',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: Colors.transparent,
                    ),
                    onPressed: () => _deleteUser(userId),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      child: Text(
                        'Delete',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.red,
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'supplier':
        return Colors.blue;
      case 'buyer':
        return Colors.green;
      default:
        return AppColors.primaryGreen;
    }
  }

  Future<void> _toggleUserStatus(String userId, bool newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('User status updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error updating user status: $e')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('User deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error deleting user: $e')),
      );
    }
  }
} 