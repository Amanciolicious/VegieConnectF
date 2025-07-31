# Dashboard Data Structure

This document outlines the Firestore collections and data structure needed for the dashboard functionality.

## Collections Required

### 1. `users` Collection
```javascript
{
  "uid": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "location": "Manila, Philippines",
  "favorites": ["product1", "product2"],
  "role": "customer"
}
```

### 2. `categories` Collection
```javascript
{
  "id": "category1",
  "name": "Vegetables",
  "icon": "eco",
  "order": 1,
  "isActive": true,
  "description": "Fresh vegetables from local farmers"
}
```

### 3. `promotions` Collection
```javascript
{
  "id": "promo1",
  "title": "Get 40% discount on your first order",
  "subtitle": "Shop Now",
  "icon": "local_offer",
  "isActive": true,
  "startDate": "2024-01-01",
  "endDate": "2024-12-31",
  "discountPercentage": 40,
  "minimumOrder": 100
}
```

### 4. `notifications` Subcollection (under users)
```javascript
{
  "id": "notif1",
  "title": "Order Status Update",
  "message": "Your order #12345 has been delivered",
  "type": "order_update",
  "isRead": false,
  "createdAt": "2024-01-01T10:00:00Z",
  "orderId": "order123"
}
```

### 5. `products` Collection (Enhanced)
```javascript
{
  "id": "product1",
  "name": "Fresh Tomatoes",
  "price": 50.00,
  "quantity": 100,
  "unit": "kg",
  "category": "Vegetables",
  "sellerId": "seller123",
  "supplierName": "Fresh Farm",
  "imageUrl": "https://example.com/tomato.jpg",
  "isActive": true,
  "status": "approved",
  "popularity": 10,
  "hasPromo": true,
  "promoPrice": 40.00,
  "description": "Fresh organic tomatoes"
}
```

## Setup Instructions

### 1. Create Categories
Add these categories to the `categories` collection:
```javascript
// Vegetables
{
  "name": "Vegetables",
  "icon": "eco",
  "order": 1,
  "isActive": true
}

// Fruits
{
  "name": "Fruits", 
  "icon": "local_florist",
  "order": 2,
  "isActive": true
}

// Herbs
{
  "name": "Herbs",
  "icon": "spa",
  "order": 3,
  "isActive": true
}
```

### 2. Create Sample Promotion
Add this to the `promotions` collection:
```javascript
{
  "title": "Get 40% discount on your first order from app",
  "subtitle": "Shop Now",
  "icon": "local_offer",
  "isActive": true,
  "startDate": "2024-01-01",
  "endDate": "2024-12-31"
}
```

### 3. Update User Profile
Make sure user documents in the `users` collection have:
- `name` field
- `location` field
- `favorites` array

### 4. Add Sample Notifications
Add notifications to user's subcollection:
```javascript
// Under users/{userId}/notifications
{
  "title": "Welcome to VegieConnect!",
  "message": "Start exploring fresh vegetables from local farmers",
  "type": "welcome",
  "isRead": false,
  "createdAt": "2024-01-01T10:00:00Z"
}
```

## Features Implemented

✅ **User Profile Data** - Real name, email, location
✅ **Search Functionality** - Working search bar with product filtering
✅ **Categories** - Dynamic categories from database
✅ **Notifications** - Real notification count and clickable icon
✅ **Promotional Banner** - Dynamic promotions from database
✅ **Popular Products** - Enhanced with real popularity data
✅ **Location Display** - Real user location
✅ **Drawer User Info** - Real user data in drawer

## Testing

1. **User Data**: Update a user document with name and location
2. **Categories**: Add categories to the `categories` collection
3. **Promotions**: Add a promotion to the `promotions` collection
4. **Notifications**: Add notifications to user's subcollection
5. **Products**: Ensure products have `hasPromo` field for promo filtering

The dashboard will now display real data from your Firestore database! 