# Content Filtering System

## Overview

The Content Filtering System is an intelligent verification system that automatically approves products with clean content and flags products with potentially inappropriate content for manual admin review. This ensures a safe and professional marketplace while reducing admin workload.

## Features

### 🔍 **Automatic Content Detection**
- **Offensive Word Filtering**: Detects inappropriate language and offensive terms
- **Suspicious Pattern Detection**: Identifies potentially problematic content patterns
- **Pricing Validation**: Flags suspicious pricing (too low or too high)
- **Category Verification**: Ensures product categories are appropriate

### ✅ **Smart Approval System**
- **Auto-Approval**: Clean content from trusted suppliers is automatically approved
- **Manual Review**: Flagged content requires admin review
- **Trusted Supplier Recognition**: Verified suppliers get faster approval
- **Content Severity Levels**: Different levels of content issues

### 🛡️ **Admin Control Panel**
- **Filter Views**: Separate views for pending, flagged, approved, and rejected products
- **Content Issue Display**: Shows specific content problems for each product
- **Trusted Supplier Badges**: Visual indicators for verified suppliers
- **Bulk Actions**: Efficient admin workflow

## How It Works

### 1. **Product Submission Process**

When a supplier submits a product:

```dart
// Content filtering check
final contentCheck = contentFilterService.checkProductContent(
  productName: name,
  description: description,
  supplierId: supplierId,
  category: category,
  price: price,
);

// Auto-approval logic
if (contentCheck.isApproved && isTrustedSupplier) {
  status = 'approved';
  isVerified = true;
  autoApproved = true;
} else if (contentCheck.issues.isNotEmpty) {
  contentFlagged = true;
  status = 'pending';
  isVerified = false;
}
```

### 2. **Content Filtering Criteria**

#### **Offensive Words Detection**
- Profanity and inappropriate language
- Hate speech and discriminatory terms
- Drug-related terminology
- Illegal activity references

#### **Suspicious Patterns**
- "Get rich quick" schemes
- Adult content references
- Weapon-related terms
- Scam indicators

#### **Pricing Validation**
- Products priced at ₱0 or below
- Products priced above ₱10,000
- Suspicious pricing patterns

### 3. **Trusted Supplier System**

Trusted suppliers get automatic approval for clean content:

```dart
static const List<String> _trustedSuppliers = [
  'organic_farm_verified',
  'fresh_veggies_certified',
  'local_farm_trusted',
  'green_garden_verified',
  'farm_fresh_certified',
];
```

## Database Schema

### **Products Collection**
```json
{
  "sellerId": "string",
  "supplierName": "string",
  "name": "string",
  "description": "string",
  "price": "number",
  "quantity": "number",
  "unit": "string",
  "category": "string",
  "isActive": "boolean",
  "isVerified": "boolean",
  "status": "string", // 'pending', 'approved', 'rejected'
  "contentFlagged": "boolean",
  "autoApproved": "boolean",
  "contentIssues": ["array"],
  "contentSeverity": "string", // 'low', 'medium', 'high', 'critical'
  "isTrustedSupplier": "boolean",
  "rejectionReason": "string",
  "verifiedBy": "string",
  "verificationDate": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Admin Interface

### **Filter Views**

#### **All Products**
- Shows all products in the system
- Default view for comprehensive overview

#### **Pending Review**
- Products awaiting admin verification
- Includes both new submissions and flagged content

#### **Content Flagged**
- Products with detected content issues
- Red badges indicate specific problems
- Detailed issue descriptions

#### **Approved Products**
- Successfully verified products
- Green badges for trusted suppliers
- Auto-approved products marked

#### **Rejected Products**
- Products rejected by admin
- Includes rejection reasons
- Can be resubmitted after fixes

### **Product Cards**

Each product card shows:

1. **Content Status Badges**
   - 🚨 **Content Flagged**: Red badge for problematic content
   - ✅ **Trusted Supplier**: Green badge for verified suppliers

2. **Product Information**
   - Product image, name, price, stock
   - Supplier information
   - Product description

3. **Content Issues Section**
   - Specific content problems detected
   - Severity level indicators
   - Detailed issue descriptions

4. **Action Buttons**
   - **Approve**: Accept the product
   - **Reject**: Reject with reason

## Content Filtering Service

### **Core Functions**

```dart
class ContentFilterService {
  // Check if content contains offensive words
  bool containsOffensiveContent(String text)
  
  // Check if supplier is trusted
  bool isTrustedSupplier(String supplierId)
  
  // Comprehensive content check
  ContentCheckResult checkProductContent({
    required String productName,
    required String description,
    required String supplierId,
    String? category,
    double? price,
  })
  
  // External API integration (optional)
  Future<ContentCheckResult> checkContentWithAPI(String text)
}
```

### **Content Check Result**

```dart
class ContentCheckResult {
  final bool isApproved;
  final List<String> issues;
  final ContentSeverity severity;
  final bool isTrustedSupplier;
  final bool requiresManualReview;
}
```

### **Severity Levels**

- **Low**: Minor issues, can be auto-approved
- **Medium**: Moderate concerns, manual review recommended
- **High**: Significant problems, requires admin review
- **Critical**: Severe violations, immediate rejection

## Implementation Examples

### **Supplier Product Submission**

```dart
// When supplier adds a product
final contentCheck = contentFilterService.checkProductContent(
  productName: "Fresh Organic Tomatoes",
  description: "Locally grown organic tomatoes",
  supplierId: "organic_farm_verified",
  category: "Vegetables",
  price: 150.0,
);

// Result: Auto-approved (clean content + trusted supplier)
if (contentCheck.isApproved && contentCheck.isTrustedSupplier) {
  // Product automatically goes live
  status = 'approved';
  isVerified = true;
  autoApproved = true;
}
```

### **Admin Review Process**

```dart
// Admin sees flagged product
if (product['contentFlagged'] == true) {
  // Show content issues
  for (final issue in product['contentIssues']) {
    // Display specific problems
  }
  
  // Admin can approve or reject
  await approveProduct(productId);
  // or
  await rejectProduct(productId, reason);
}
```

## Benefits

### **For Suppliers**
- **Faster Approval**: Clean content from trusted suppliers is approved instantly
- **Clear Guidelines**: Specific feedback on content issues
- **Fair Process**: Transparent review system

### **For Admins**
- **Reduced Workload**: Automatic approval for clean content
- **Focused Review**: Only problematic content requires manual review
- **Better Control**: Detailed filtering and categorization

### **For Buyers**
- **Safe Marketplace**: Inappropriate content is filtered out
- **Quality Products**: Only verified products are displayed
- **Professional Experience**: Clean, appropriate product listings

## Configuration

### **Adding Offensive Words**

```dart
contentFilterService.addOffensiveWord('new_offensive_word');
```

### **Adding Suspicious Patterns**

```dart
contentFilterService.addSuspiciousPattern('new_suspicious_pattern');
```

### **Adding Trusted Suppliers**

```dart
contentFilterService.addTrustedSupplier('new_trusted_supplier_id');
```

### **External API Integration**

```dart
// Integrate with external content moderation services
final result = await contentFilterService.checkContentWithAPI(text);
```

## Future Enhancements

### **Planned Features**
1. **Machine Learning**: AI-powered content analysis
2. **Image Filtering**: Detect inappropriate images
3. **Context Analysis**: Understand content context better
4. **Custom Rules**: Admin-defined filtering rules
5. **Analytics**: Content filtering statistics

### **External API Integration**
- Google Cloud Content Moderation
- Amazon Comprehend
- Microsoft Azure Content Moderator
- Perspective API

## Security Considerations

### **Data Privacy**
- Content analysis is performed locally when possible
- External API calls are optional and configurable
- No sensitive data is stored unnecessarily

### **Accuracy**
- Multiple validation layers
- Human review for borderline cases
- Continuous improvement of filtering rules

### **Transparency**
- Clear feedback on content issues
- Appeal process for rejected products
- Detailed admin audit trail

## Troubleshooting

### **Common Issues**

#### **False Positives**
- Review and adjust offensive word lists
- Add context-specific exceptions
- Implement whitelist for trusted content

#### **False Negatives**
- Update suspicious pattern lists
- Add new offensive terms
- Improve pattern matching algorithms

#### **Performance Issues**
- Optimize content checking algorithms
- Implement caching for repeated checks
- Use batch processing for bulk operations

### **Admin Tools**
- Content filter statistics dashboard
- Manual override capabilities
- Bulk approval/rejection tools
- Content analysis reports

## Conclusion

The Content Filtering System provides a robust, scalable solution for maintaining a safe and professional marketplace. By automatically approving clean content and flagging problematic content for review, it reduces admin workload while ensuring quality control.

The system is designed to be:
- **Accurate**: Minimizes false positives and negatives
- **Efficient**: Reduces manual review workload
- **Transparent**: Clear feedback for all parties
- **Scalable**: Handles growing product volumes
- **Configurable**: Adaptable to changing requirements

This creates a win-win situation where suppliers get faster approvals for good content, admins focus on problematic cases, and buyers enjoy a safe, professional marketplace. 