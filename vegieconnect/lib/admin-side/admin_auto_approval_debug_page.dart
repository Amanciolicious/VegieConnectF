import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import '../theme.dart';
import '../services/auto_approval_service.dart';


class AdminAutoApprovalDebugPage extends StatefulWidget {
  const AdminAutoApprovalDebugPage({super.key});

  @override
  State<AdminAutoApprovalDebugPage> createState() => _AdminAutoApprovalDebugPageState();
}

class _AdminAutoApprovalDebugPageState extends State<AdminAutoApprovalDebugPage> {
  final AutoApprovalService _autoApprovalService = AutoApprovalService();
 
  List<Map<String, dynamic>> _pendingProducts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingProducts();
  }

  Future<void> _loadPendingProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('status', isEqualTo: 'pending')
          .where('autoApprovalScheduled', isEqualTo: true)
          .get();

      setState(() {
        _pendingProducts = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading pending products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _manualTriggerApproval() async {
    setState(() => _isLoading = true);
    
    try {
     
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manual approval check completed')),
      );
      await _loadPendingProducts(); // Reload the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(
          'Auto-Approval Debug',
          style: AppTextStyles.headline.copyWith(color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            // Status Card
            Neumorphic(
              style: AppNeumorphic.card,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Approval Status',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                   
                    SizedBox(height: screenWidth * 0.02),
                    Text(
                      'Pending Products: ${_pendingProducts.length}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Manual Trigger Button
            NeumorphicButton(
              style: AppNeumorphic.button.copyWith(
                color: AppColors.primaryGreen,
              ),
              onPressed: _isLoading ? null : _manualTriggerApproval,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.refresh, color: Colors.white),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      _isLoading ? 'Processing...' : 'Manual Trigger Approval',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Pending Products List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pendingProducts.isEmpty
                      ? Center(
                          child: Text(
                            'No pending products found',
                            style: AppTextStyles.body,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _pendingProducts.length,
                          itemBuilder: (context, index) {
                            final product = _pendingProducts[index];
                            final scheduledTime = product['scheduledApprovalTime'] as String?;
                            final autoApprovalTime = product['autoApprovalTime'] as Timestamp?;
                            
                            DateTime? scheduledDateTime;
                            if (scheduledTime != null) {
                              scheduledDateTime = DateTime.parse(scheduledTime);
                            }
                            
                            final now = DateTime.now();
                            final isOverdue = scheduledDateTime != null && now.isAfter(scheduledDateTime);
                            
                            return Neumorphic(
                              style: AppNeumorphic.card,
                              margin: EdgeInsets.only(bottom: screenWidth * 0.02),
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product['name'] ?? 'Unknown Product',
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.02,
                                            vertical: screenWidth * 0.01,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isOverdue ? Colors.red : Colors.orange,
                                            borderRadius: BorderRadius.circular(screenWidth * 0.01),
                                          ),
                                          child: Text(
                                            isOverdue ? 'OVERDUE' : 'PENDING',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: screenWidth * 0.01),
                                    Text(
                                      'Supplier: ${product['supplierName'] ?? 'Unknown'}',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: screenWidth * 0.035,
                                      ),
                                    ),
                                    if (scheduledDateTime != null) ...[
                                      SizedBox(height: screenWidth * 0.01),
                                      Text(
                                        'Scheduled: ${scheduledDateTime.toString()}',
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: screenWidth * 0.03,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (autoApprovalTime != null) ...[
                                      SizedBox(height: screenWidth * 0.01),
                                      Text(
                                        'Created: ${autoApprovalTime.toDate().toString()}',
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: screenWidth * 0.03,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                    if (isOverdue) ...[
                                      SizedBox(height: screenWidth * 0.01),
                                      Text(
                                        'Overdue by: ${now.difference(scheduledDateTime).inMinutes} minutes',
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: screenWidth * 0.03,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
} 