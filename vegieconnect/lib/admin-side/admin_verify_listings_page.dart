import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:path/path.dart';
import 'package:vegieconnect/theme.dart';


class AdminVerifyListingsPage extends StatelessWidget {
  const AdminVerifyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text('Verify Listings', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055)),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .where('isVerified', isEqualTo: false)
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
                          Icons.verified,
                          size: screenWidth * 0.15,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(height: screenWidth * 0.04),
                        Text(
                          'All Listings Verified!',
                          style: AppTextStyles.headline.copyWith(
                            fontSize: screenWidth * 0.06,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Text(
                          'No pending listings to verify',
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

            final products = snapshot.data!.docs;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index].data() as Map<String, dynamic>;
                return _buildProductCard(screenWidth, products[index].id, product);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(double screenWidth, String productId, Map<String, dynamic> product) {
    return Neumorphic(
      style: AppNeumorphic.card,
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image and Basic Info
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  child: SizedBox(
                    width: screenWidth * 0.2,
                    height: screenWidth * 0.2,
                    child: product['imageUrl'] != null
                        ? Image.network(
                            product['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.background,
                                child: Icon(
                                  Icons.image,
                                  color: AppColors.textSecondary,
                                  size: screenWidth * 0.08,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: AppColors.background,
                            child: Icon(
                              Icons.image,
                              color: AppColors.textSecondary,
                              size: screenWidth * 0.08,
                            ),
                          ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? 'Unknown Product',
                        style: AppTextStyles.headline.copyWith(
                          fontSize: screenWidth * 0.045,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        '\u20b1${product['price']?.toStringAsFixed(2) ?? '0.00'}',
                        style: AppTextStyles.price.copyWith(
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.01),
                      Text(
                        'Stock: ${product['quantity'] ?? 0} ${product['unit'] ?? ''}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: screenWidth * 0.035,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            // Supplier Info
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: screenWidth * 0.05,
                    color: AppColors.primaryGreen,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      'Supplier: ${product['supplierName'] ?? 'Unknown'}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: screenWidth * 0.035,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            // Description
            if (product['description'] != null && product['description'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description:',
                    style: AppTextStyles.body.copyWith(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    product['description'],
                    style: AppTextStyles.body.copyWith(
                      fontSize: screenWidth * 0.035,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.03),
                ],
              ),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: () => _verifyProduct(context as BuildContext, productId, true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      child: Text(
                        'Approve',
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
                      color: Colors.red,
                    ),
                    onPressed: () => _verifyProduct(context as BuildContext, productId, false),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      child: Text(
                        'Reject',
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
          ],
        ),
      ),
    );
  }

  Future<void> _verifyProduct(BuildContext context, String productId, bool isApproved) async {
    try {
      if (isApproved) {
        await FirebaseFirestore.instance.collection('products').doc(productId).update({
          'isVerified': true,
          'isActive': true,
          'status': 'approved',
          'rejectionReason': '',
          'verifiedBy': 'admin',
          'verificationDate': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product approved!')),
        );
      } else {
        final reason = await _showRejectionDialog(context);
        if (reason == null || reason.trim().isEmpty) return;
        await FirebaseFirestore.instance.collection('products').doc(productId).update({
          'isVerified': false,
          'isActive': false,
          'status': 'rejected',
          'rejectionReason': reason.trim(),
          'verifiedBy': 'admin',
          'verificationDate': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product rejected.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying product: $e')),
      );
    }
  }

  Future<String?> _showRejectionDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Product'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
} 