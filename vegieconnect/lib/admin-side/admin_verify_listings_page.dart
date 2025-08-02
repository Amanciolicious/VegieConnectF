import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:vegieconnect/theme.dart';
import '../services/content_filter_service.dart';
import '../services/auto_approval_service.dart';
import '../services/countdown_timer_service.dart';
import '../widgets/countdown_timer_widget.dart';

class AdminVerifyListingsPage extends StatefulWidget {
  const AdminVerifyListingsPage({super.key});

  @override
  State<AdminVerifyListingsPage> createState() => _AdminVerifyListingsPageState();
}

class _AdminVerifyListingsPageState extends State<AdminVerifyListingsPage> {
  final ContentFilterService _contentFilterService = ContentFilterService();
  final CountdownTimerService _countdownService = CountdownTimerService();
  String _filterStatus = 'all'; // 'all', 'pending', 'flagged', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    // Start countdowns for all pending products when page loads
    _countdownService.startCountdownForPendingProducts();
  }

  /// Start countdown for a specific product
  void _startCountdownForProduct(String productId) {
    if (!_countdownService.isCountdownActive(productId)) {
      _countdownService.startCountdown(productId);
    }
  }

  @override
  void dispose() {
    // Clean up countdowns when page is disposed
    _countdownService.cancelAllCountdowns();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Verify Listings',
                style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: screenWidth * 0.055),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              
            ),
          ],
        ),
        elevation: 0,
        actions: [
        
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Products')),
              const PopupMenuItem(value: 'pending', child: Text('Pending Review')),
              const PopupMenuItem(value: 'flagged', child: Text('Content Flagged')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
              const PopupMenuItem(value: 'recently_processed', child: Text('Recently Processed')),
            ],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            // Filter Status Indicator
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: _getFilterColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(color: _getFilterColor()),
              ),
              child: Row(
                children: [
                  Icon(
                    _getFilterIcon(),
                    color: _getFilterColor(),
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    _getFilterText(),
                    style: AppTextStyles.body.copyWith(
                      color: _getFilterColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            // Products List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildProductQuery(),
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
                                _getEmptyStateIcon(),
                                size: screenWidth * 0.15,
                                color: AppColors.primaryGreen,
                              ),
                              SizedBox(height: screenWidth * 0.04),
                              Text(
                                _getEmptyStateText(),
                                style: AppTextStyles.headline.copyWith(
                                  fontSize: screenWidth * 0.06,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              Text(
                                _getEmptyStateSubtext(),
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
                      return _buildProductCard(context, products[index].id, product);
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

  Stream<QuerySnapshot> _buildProductQuery() {
    final baseQuery = FirebaseFirestore.instance.collection('products');
    
    switch (_filterStatus) {
      case 'pending':
        return baseQuery
            .where('status', isEqualTo: 'pending')
            .snapshots();
      case 'flagged':
        return baseQuery
            .where('contentFlagged', isEqualTo: true)
            .snapshots();
      case 'approved':
        return baseQuery
            .where('status', isEqualTo: 'approved')
            .snapshots();
      case 'rejected':
        return baseQuery
            .where('status', isEqualTo: 'rejected')
            .snapshots();
      case 'recently_processed':
        // Show products that were processed by admin in the last 24 hours
        final yesterday = DateTime.now().subtract(const Duration(hours: 24));
        return baseQuery
            .where('verificationDate', isGreaterThan: yesterday)
            .where('verifiedBy', isEqualTo: 'admin')
            .snapshots();
      default:
        return baseQuery.snapshots();
    }
  }

  Color _getFilterColor() {
    switch (_filterStatus) {
      case 'pending':
        return Colors.orange;
      case 'flagged':
        return Colors.red;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'recently_processed':
        return Colors.purple;
      default:
        return AppColors.primaryGreen;
    }
  }

  IconData _getFilterIcon() {
    switch (_filterStatus) {
      case 'pending':
        return Icons.pending;
      case 'flagged':
        return Icons.warning;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'recently_processed':
        return Icons.history;
      default:
        return Icons.list;
    }
  }

  String _getFilterText() {
    switch (_filterStatus) {
      case 'pending':
        return 'Pending Review';
      case 'flagged':
        return 'Content Flagged';
      case 'approved':
        return 'Approved Products';
      case 'rejected':
        return 'Rejected Products';
      case 'recently_processed':
        return 'Recently Processed';
      default:
        return 'All Products';
    }
  }

  bool _isProductOverdue(Map<String, dynamic> product) {
    final scheduledTime = product['scheduledApprovalTime'] as String?;
    if (scheduledTime == null) return false;
    
    final scheduledDateTime = DateTime.parse(scheduledTime);
    final now = DateTime.now();
    
    return now.isAfter(scheduledDateTime);
  }

  String _getOverdueText(Map<String, dynamic> product) {
    final scheduledTime = product['scheduledApprovalTime'] as String?;
    if (scheduledTime == null) return '';
    
    final scheduledDateTime = DateTime.parse(scheduledTime);
    final now = DateTime.now();
    final difference = now.difference(scheduledDateTime);
    
    if (difference.inMinutes > 0) {
      return 'Overdue by ${difference.inMinutes} minutes';
    } else {
      return 'Due in ${-difference.inMinutes} minutes';
    }
  }

 

  IconData _getEmptyStateIcon() {
    switch (_filterStatus) {
      case 'pending':
        return Icons.verified;
      case 'flagged':
        return Icons.warning;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'recently_processed':
        return Icons.history;
      default:
        return Icons.verified;
    }
  }

  String _getEmptyStateText() {
    switch (_filterStatus) {
      case 'pending':
        return 'No Pending Reviews!';
      case 'flagged':
        return 'No Flagged Content!';
      case 'approved':
        return 'No Approved Products!';
      case 'rejected':
        return 'No Rejected Products!';
      case 'recently_processed':
        return 'No recently processed products!';
      default:
        return 'All Listings Verified!';
    }
  }

  String _getEmptyStateSubtext() {
    switch (_filterStatus) {
      case 'pending':
        return 'All products have been reviewed';
      case 'flagged':
        return 'No content violations detected';
      case 'approved':
        return 'No approved products in this filter';
      case 'rejected':
        return 'No rejected products in this filter';
      case 'recently_processed':
        return 'No products have been processed by the admin in the last 24 hours.';
      default:
        return 'No pending listings to verify';
    }
  }

  Widget _buildProductCard(BuildContext context, String productId, Map<String, dynamic> product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final contentCheck = _contentFilterService.checkProductContent(
      productName: product['name'] ?? '',
      description: product['description'] ?? '',
      supplierId: product['sellerId'] ?? '',
      category: product['category'],
      price: product['price']?.toDouble(),
    );

    final isFlagged = product['contentFlagged'] == true || contentCheck.issues.isNotEmpty;
    final isTrusted = contentCheck.isTrustedSupplier;

    return Neumorphic(
      style: AppNeumorphic.card,
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Status Badge
            if (isFlagged)
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: screenWidth * 0.04),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      'Content Flagged',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.red,
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (isTrusted)
              Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: screenWidth * 0.04),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      'Trusted Supplier',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.green,
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            // Removed: Auto-approval status
            // if (product['autoApprovalScheduled'] == true && product['autoApprovalCompleted'] != true)
            //   Container(
            //     padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
            //     decoration: BoxDecoration(
            //       color: _isProductOverdue(product) ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(screenWidth * 0.02),
            //       border: Border.all(color: _isProductOverdue(product) ? Colors.red : Colors.orange),
            //     ),
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Icon(
            //           _isProductOverdue(product) ? Icons.schedule : Icons.timer,
            //           color: _isProductOverdue(product) ? Colors.red : Colors.orange,
            //           size: screenWidth * 0.04,
            //         ),
            //         SizedBox(width: screenWidth * 0.01),
            //         Text(
            //           _isProductOverdue(product) ? 'OVERDUE' : 'Auto-approval pending',
            //           style: AppTextStyles.body.copyWith(
            //             color: _isProductOverdue(product) ? Colors.red : Colors.orange,
            //             fontSize: screenWidth * 0.03,
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            SizedBox(height: screenWidth * 0.02),
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
            // Removed: Auto-approval Status Information
            // if (product['autoApprovalScheduled'] == true)
            //   Container(
            //     padding: EdgeInsets.all(screenWidth * 0.03),
            //     decoration: BoxDecoration(
            //       color: _isProductOverdue(product) ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            //       borderRadius: BorderRadius.circular(screenWidth * 0.02),
            //       border: Border.all(color: _isProductOverdue(product) ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3)),
            //     ),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Icon(
            //               _isProductOverdue(product) ? Icons.schedule : Icons.timer,
            //               color: _isProductOverdue(product) ? Colors.red : Colors.blue,
            //               size: screenWidth * 0.04,
            //             ),
            //             SizedBox(width: screenWidth * 0.02),
            //             Text(
            //               'Auto-Approval Status',
            //               style: AppTextStyles.body.copyWith(
            //                 fontSize: screenWidth * 0.035,
            //                 fontWeight: FontWeight.bold,
            //                 color: _isProductOverdue(product) ? Colors.red : Colors.blue,
            //               ),
            //             ),
            //           ],
            //         ),
            //         SizedBox(height: screenWidth * 0.01),
            //         Text(
            //           _getOverdueText(product),
            //           style: AppTextStyles.body.copyWith(
            //             fontSize: screenWidth * 0.03,
            //             color: _isProductOverdue(product) ? Colors.red : Colors.blue,
            //           ),
            //         ),
            //         if (product['scheduledApprovalTime'] != null) ...[
            //           SizedBox(height: screenWidth * 0.01),
            //           Text(
            //             'Scheduled: ${DateTime.parse(product['scheduledApprovalTime']).toString()}',
            //             style: AppTextStyles.body.copyWith(
            //               fontSize: screenWidth * 0.03,
            //               color: AppColors.textSecondary,
            //             ),
            //           ),
            //         ],
            //         // Debug information
            //         SizedBox(height: screenWidth * 0.01),
            //         Text(
            //           'Status: ${product['status'] ?? 'unknown'} | Auto-Approved: ${product['autoApproved'] ?? false} | Completed: ${product['autoApprovalCompleted'] ?? false}',
            //           style: AppTextStyles.body.copyWith(
            //             fontSize: screenWidth * 0.025,
            //             color: AppColors.textSecondary,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // Content Issues (if any)
            if (contentCheck.issues.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Issues:',
                      style: AppTextStyles.body.copyWith(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    ...contentCheck.issues.map((issue) => Padding(
                      padding: EdgeInsets.only(bottom: screenWidth * 0.01),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: screenWidth * 0.03),
                          SizedBox(width: screenWidth * 0.01),
                          Expanded(
                            child: Text(
                              issue,
                              style: AppTextStyles.body.copyWith(
                                fontSize: screenWidth * 0.03,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              SizedBox(height: screenWidth * 0.03),
            ],
            // Countdown Timer for Pending Products
            if (product['status'] == 'pending' || product['status'] == null) ...[
              SizedBox(height: screenWidth * 0.02),
              CountdownTimerWidget(
                productId: productId,
                onTimerComplete: () {
                  // Refresh the page when timer completes
                  setState(() {});
                },
              ),
            ],
            // Action Buttons
            if (product['status'] == 'pending' || product['status'] == null) ...[
              Row(
                children: [
                  Expanded(
                    child: NeumorphicButton(
                      style: AppNeumorphic.button.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                      onPressed: () => _verifyProduct(context, productId, true),
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
                      onPressed: () => _verifyProduct(context, productId, false),
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
            ] else ...[
              // Show processed status
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: (product['status'] == 'approved' ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  border: Border.all(color: product['status'] == 'approved' ? Colors.green : Colors.red),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      product['status'] == 'approved' ? Icons.check_circle : Icons.cancel,
                      color: product['status'] == 'approved' ? Colors.green : Colors.red,
                      size: screenWidth * 0.04,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      product['status'] == 'approved' 
                          ? 'Product Approved - Now Visible to Buyers'
                          : 'Product Rejected',
                      style: AppTextStyles.body.copyWith(
                        color: product['status'] == 'approved' ? Colors.green : Colors.red,
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Removed: Force Process Button for Overdue Products
            // if (_isProductOverdue(product) && product['autoApprovalScheduled'] == true)
            //   Padding(
            //     padding: EdgeInsets.only(top: screenWidth * 0.02),
            //     child: SizedBox(
            //       width: double.infinity,
            //       child: NeumorphicButton(
            //         style: AppNeumorphic.button.copyWith(
            //           color: Colors.orange,
            //         ),
            //         onPressed: () => _forceProcessProduct(context, productId),
            //         child: Padding(
            //           padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
            //           child: Row(
            //             mainAxisAlignment: MainAxisAlignment.center,
            //             children: [
            //               Icon(Icons.schedule, color: Colors.white, size: screenWidth * 0.04),
            //               SizedBox(width: screenWidth * 0.02),
            //               Text(
            //                 'Force Process Auto-Approval',
            //                 style: AppTextStyles.button.copyWith(
            //                   color: Colors.white,
            //                   fontSize: screenWidth * 0.04,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyProduct(BuildContext context, String productId, bool isApproved) async {
    try {
      if (isApproved) {
        // Cancel countdown for this product since it's being manually approved
        _countdownService.cancelCountdown(productId);
        
        // Use the new manual approval method
        final autoApprovalService = AutoApprovalService();
        await autoApprovalService.manualApproveProduct(productId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product approved and now visible to buyers!')),
        );
        
        // Switch to recently processed filter to show the result
        setState(() {
          _filterStatus = 'recently_processed';
        });
      } else {
        // Cancel countdown for this product since it's being rejected
        _countdownService.cancelCountdown(productId);
        
        final reason = await _showRejectionDialog(context);
        if (reason == null || reason.trim().isEmpty) return;
        await FirebaseFirestore.instance.collection('products').doc(productId).update({
          'isVerified': false,
          'isActive': false,
          'status': 'rejected',
          'rejectionReason': reason.trim(),
          'verifiedBy': 'admin',
          'verificationDate': FieldValue.serverTimestamp(),
          'contentFlagged': true,
          'autoApprovalCompleted': true,
          'autoApprovalFailed': true,
          'autoApprovalFailureReason': 'Manually rejected by admin',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product rejected.')),
        );
        
        // Switch to recently processed filter to show the result
        setState(() {
          _filterStatus = 'recently_processed';
        });
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