# Rating & Feedback System Implementation

This document outlines the complete rating and feedback system for suppliers after customers place orders.

## 🎯 **Overview**

The rating system allows customers to:
- Rate suppliers with 1-5 stars after order delivery
- Provide optional feedback/reviews
- View their rating history
- See supplier average ratings

## 📱 **User Flow**

1. **Customer places order** → Digital receipt page
2. **Navigate to Order History** → Click "View Order History" button
3. **Find delivered orders** → Look for "Rate Supplier" button
4. **Rate supplier** → 5-star rating + optional feedback
5. **Submit rating** → Rating saved to database

## 🗄️ **Database Structure**

### 1. `order_ratings` Collection
```javascript
{
  "id": "rating123",
  "orderId": "order456",
  "supplierId": "supplier789",
  "buyerId": "buyer123",
  "rating": 5,
  "feedback": "Great service and fresh vegetables!",
  "orderNumber": "ORD-2024-001",
  "supplierName": "Fresh Farm",
  "timestamp": "2024-01-01T10:00:00Z"
}
```

### 2. Enhanced `orders` Collection
```javascript
{
  "id": "order456",
  "buyerId": "buyer123",
  "sellerId": "supplier789",
  "productName": "Fresh Tomatoes",
  "quantity": 5,
  "unit": "kg",
  "price": 250.00,
  "status": "delivered",
  "hasRating": true,
  "rating": 5,
  "ratingTimestamp": "2024-01-01T10:00:00Z",
  "createdAt": "2024-01-01T09:00:00Z"
}
```

### 3. Enhanced `suppliers` Collection
```javascript
{
  "id": "supplier789",
  "name": "Fresh Farm",
  "email": "freshfarm@email.com",
  "averageRating": 4.5,
  "ratingCount": 10,
  "lastRatingUpdate": "2024-01-01T10:00:00Z"
}
```

## 🔧 **Components Implemented**

### 1. **Digital Receipt Page** (`digital_receipt_page.dart`)
- ✅ Added "View Order History" button
- ✅ Navigates to order history page
- ✅ Replaced "Track Order" with "View Order History"

### 2. **Supplier Rating Dialog** (`widgets/supplier_rating_dialog.dart`)
- ✅ 5-star rating system
- ✅ Optional feedback text field
- ✅ Order and supplier information display
- ✅ Duplicate rating prevention
- ✅ Loading states and error handling
- ✅ Real-time supplier rating updates

### 3. **Order History Page** (`buyer_order_history_page.dart`)
- ✅ Rating button for delivered orders
- ✅ Visual indication of rated vs unrated orders
- ✅ Integration with rating dialog
- ✅ Real-time rating status updates

### 4. **Rating Service** (`services/rating_service.dart`)
- ✅ Submit ratings with validation
- ✅ Update supplier average ratings
- ✅ Check existing ratings
- ✅ Get supplier rating statistics
- ✅ Error handling and logging

## 🎨 **UI Features**

### **Rating Dialog**
```dart
// 5-star rating system
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: List.generate(5, (index) {
    return GestureDetector(
      onTap: () => setState(() => _rating = index + 1),
      child: Icon(
        index < _rating ? Icons.star : Icons.star_border,
        color: index < _rating ? Colors.amber : Colors.grey,
      ),
    );
  }),
)
```

### **Order History Rating Button**
```dart
// Shows different states based on rating status
TextButton.icon(
  icon: Icon(
    hasRated ? Icons.star : Icons.star_border,
    color: hasRated ? Colors.amber : AppColors.primaryGreen,
  ),
  label: Text(hasRated ? 'Rated' : 'Rate Supplier'),
  onPressed: hasRated ? null : () => showRatingDialog(),
)
```

## 📊 **Rating Logic**

### **Average Rating Calculation**
```dart
double totalRating = 0;
int ratingCount = 0;

for (var doc in ratingsSnapshot.docs) {
  final rating = doc['rating'] as int? ?? 0;
  if (rating > 0) {
    totalRating += rating;
    ratingCount++;
  }
}

final averageRating = totalRating / ratingCount;
```

### **Duplicate Prevention**
```dart
// Check if user already rated this order
final existingRating = await FirebaseFirestore.instance
    .collection('order_ratings')
    .where('orderId', isEqualTo: orderId)
    .where('buyerId', isEqualTo: user.uid)
    .limit(1)
    .get();

if (existingRating.docs.isNotEmpty) {
  throw Exception('You have already rated this order');
}
```

## 🚀 **Features**

### ✅ **Core Functionality**
- 5-star rating system
- Optional feedback/reviews
- Duplicate rating prevention
- Real-time supplier rating updates
- Order history integration

### ✅ **User Experience**
- Intuitive star rating interface
- Clear order and supplier information
- Loading states and error handling
- Success/error notifications
- Skip option for optional feedback

### ✅ **Data Management**
- Automatic supplier rating recalculation
- Order rating status tracking
- Comprehensive rating history
- Supplier statistics

### ✅ **Validation**
- Rating required (1-5 stars)
- User authentication check
- Duplicate rating prevention
- Order delivery status check

## 📋 **Setup Instructions**

### 1. **Database Collections**
Ensure these collections exist in Firestore:
- `order_ratings`
- `orders` (with rating fields)
- `suppliers` (with rating fields)

### 2. **Security Rules**
Add Firestore security rules for `order_ratings`:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /order_ratings/{ratingId} {
      allow read, write: if request.auth != null;
      allow create: if request.auth != null && 
        request.resource.data.buyerId == request.auth.uid;
    }
  }
}
```

### 3. **Testing**
1. Place an order as a customer
2. Navigate to digital receipt
3. Click "View Order History"
4. Find a delivered order
5. Click "Rate Supplier"
6. Submit a rating and feedback
7. Verify rating appears in order history

## 🎯 **Usage Examples**

### **Submit Rating**
```dart
final success = await RatingService.submitRating(
  orderId: 'order123',
  supplierId: 'supplier456',
  rating: 5,
  feedback: 'Excellent service!',
  orderNumber: 'ORD-2024-001',
  supplierName: 'Fresh Farm',
);
```

### **Check Rating Status**
```dart
final hasRated = await RatingService.hasUserRatedOrder('order123');
```

### **Get Supplier Rating**
```dart
final rating = await RatingService.getSupplierRating('supplier456');
print('Average: ${rating['averageRating']}');
print('Count: ${rating['ratingCount']}');
```

## 🔄 **Future Enhancements**

1. **Rating Analytics Dashboard** for suppliers
2. **Rating Notifications** when new ratings received
3. **Rating Response** system for suppliers
4. **Rating Filtering** by date, rating value
5. **Rating Export** functionality
6. **Rating Moderation** system

The rating system is now fully implemented and ready for use! 🎉 