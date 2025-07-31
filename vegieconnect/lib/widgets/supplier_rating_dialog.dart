import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vegieconnect/theme.dart';

class SupplierRatingDialog extends StatefulWidget {
  final String orderId;
  final String supplierId;
  final String supplierName;
  final String orderNumber;

  const SupplierRatingDialog({
    super.key,
    required this.orderId,
    required this.supplierId,
    required this.supplierName,
    required this.orderNumber,
  });

  @override
  State<SupplierRatingDialog> createState() => _SupplierRatingDialogState();
}

class _SupplierRatingDialogState extends State<SupplierRatingDialog> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Check if user has already rated this order
      final existingRating = await FirebaseFirestore.instance
          .collection('order_ratings')
          .where('orderId', isEqualTo: widget.orderId)
          .where('buyerId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingRating.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already rated this order')),
        );
        Navigator.pop(context);
        return;
      }

      // Save rating to Firestore
      await FirebaseFirestore.instance.collection('order_ratings').add({
        'orderId': widget.orderId,
        'supplierId': widget.supplierId,
        'buyerId': user.uid,
        'rating': _rating,
        'feedback': _feedbackController.text.trim(),
        'orderNumber': widget.orderNumber,
        'supplierName': widget.supplierName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update order with rating status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'hasRating': true,
        'rating': _rating,
        'ratingTimestamp': FieldValue.serverTimestamp(),
      });

      // Recalculate supplier average rating
      await _updateSupplierRating();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _updateSupplierRating() async {
    try {
      // Get all ratings for this supplier
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('order_ratings')
          .where('supplierId', isEqualTo: widget.supplierId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      int ratingCount = 0;

      for (var doc in ratingsSnapshot.docs) {
        final rating = doc['rating'] as int? ?? 0;
        if (rating > 0) {
          totalRating += rating;
          ratingCount++;
        }
      }

      if (ratingCount > 0) {
        final averageRating = totalRating / ratingCount;

        // Update supplier's average rating
        await FirebaseFirestore.instance
            .collection('suppliers')
            .doc(widget.supplierId)
            .update({
          'averageRating': averageRating,
          'ratingCount': ratingCount,
          'lastRatingUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating supplier rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: AppColors.primaryGreen,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    'Rate Your Experience',
                    style: AppTextStyles.headline.copyWith(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenWidth * 0.03),
            
            // Order Info
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order: ${widget.orderNumber}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.01),
                  Text(
                    'Supplier: ${widget.supplierName}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Rating Stars
            Text(
              'How would you rate your experience?',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenWidth * 0.03),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.amber : Colors.grey,
                      size: screenWidth * 0.08,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Feedback Text Field
            Text(
              'Additional Feedback (Optional)',
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Neumorphic(
              style: AppNeumorphic.inset,
              child: TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience with this supplier...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(screenWidth * 0.03),
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button,
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.button.copyWith(fontSize: screenWidth * 0.04),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: _isSubmitting ? null : _submitRating,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
                      child: _isSubmitting
                          ? SizedBox(
                              height: screenWidth * 0.04,
                              width: screenWidth * 0.04,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit',
                              style: AppTextStyles.button.copyWith(
                                fontSize: screenWidth * 0.04,
                                color: Colors.white,
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
} 