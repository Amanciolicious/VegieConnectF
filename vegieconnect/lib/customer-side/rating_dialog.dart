import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../widgets/star_rating_widget.dart';

class RatingDialog extends StatefulWidget {
  final String orderId;
  final String supplierId;
  final String supplierName;
  final List<Map<String, dynamic>> products;

  const RatingDialog({
    super.key,
    required this.orderId,
    required this.supplierId,
    required this.supplierName,
    required this.products,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
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
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create rating document
      final ratingData = {
        'orderId': widget.orderId,
        'customerId': user.uid,
        'customerName': user.displayName ?? 'Customer',
        'supplierId': widget.supplierId,
        'supplierName': widget.supplierName,
        'rating': _rating,
        'feedback': _feedbackController.text.trim(),
        'products': widget.products,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('ratings')
          .add(ratingData);

      // Update order documents to mark as rated
      // Note: orders are stored with auto-generated doc IDs; `orderId` is a field shared by all
      // item-level order docs created at checkout. We need to update all matching docs.
      final ordersQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('orderId', isEqualTo: widget.orderId)
          .where('buyerId', isEqualTo: user.uid)
          .get();

      if (ordersQuery.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in ordersQuery.docs) {
          batch.update(doc.reference, {'isRated': true});
        }
        await batch.commit();
      } else {
        // No matching order docs found; log but don't fail the rating creation
        // You may want to report this to analytics/logging.
      }

      if (!mounted) return;
      
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Thank you for your feedback!'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rate Your Experience',
              style: AppTextStyles.headline.copyWith(
                fontSize: screenWidth * 0.05,
              ),
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              'How was your experience with ${widget.supplierName}?',
              style: AppTextStyles.body.copyWith(
                fontSize: screenWidth * 0.035,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenWidth * 0.06),
            StarRatingWidget(
              rating: _rating,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
              size: screenWidth * 0.08,
            ),
            SizedBox(height: screenWidth * 0.06),
            Neumorphic(
              style: AppNeumorphic.inset,
              child: TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your feedback (optional)',
                  hintStyle: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(screenWidth * 0.04),
                ),
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
            ),
            SizedBox(height: screenWidth * 0.06),
            Row(
              children: [
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: Colors.grey[300],
                    ),
                    onPressed: _isSubmitting ? null : () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text(
                      'Skip',
                      style: AppTextStyles.button.copyWith(
                        fontSize: screenWidth * 0.035,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: NeumorphicButton(
                    style: AppNeumorphic.button.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: _isSubmitting ? null : _submitRating,
                    child: _isSubmitting
                        ? SizedBox(
                            width: screenWidth * 0.04,
                            height: screenWidth * 0.04,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit',
                            style: AppTextStyles.button.copyWith(
                              fontSize: screenWidth * 0.035,
                              color: Colors.white,
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
