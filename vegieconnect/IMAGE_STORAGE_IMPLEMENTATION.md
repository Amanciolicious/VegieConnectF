# Local Image Storage Implementation

This document describes the implementation of local image storage for product images in the VegieConnect Flutter app.

## Overview

The app now stores product images locally on the device instead of uploading them to external services (except for web platform which still uses imgbb.com as a fallback). This provides better performance, offline access, and reduces dependency on external services.

## Architecture

### File Structure
```
vegieconnect/
├── assets/
│   └── images/
│       └── products/          # Placeholder for static product images
├── lib/
│   ├── services/
│   │   └── image_storage_service.dart  # Core image storage logic
│   └── widgets/
│       └── product_image_widget.dart   # Reusable image display widget
```

### Local Storage Location
- **Mobile**: `{app_documents_directory}/product_images/`
- **Web**: Not supported (falls back to imgbb.com)

## Key Components

### 1. ImageStorageService
Located at `lib/services/image_storage_service.dart`

**Key Methods:**
- `saveImageFromFile(File imageFile, String productId)` - Save image from file
- `saveImageFromBytes(Uint8List imageBytes, String productId)` - Save image from bytes
- `pickImageFromGallery()` - Pick image from device gallery
- `pickImageFromWeb()` - Pick image on web platform
- `loadImageFromPath(String imagePath)` - Load image from local path
- `deleteImage(String imagePath)` - Delete local image
- `isLocalPath(String imagePath)` - Check if path is local
- `isNetworkUrl(String imagePath)` - Check if path is network URL

### 2. ProductImageWidget
Located at `lib/widgets/product_image_widget.dart`

A reusable widget that can display images from:
- Local file paths
- Network URLs
- Shows appropriate placeholders for missing images

## Implementation Details

### Image Naming Convention
Local images are saved with the format: `{productId}_{timestamp}.jpg`

Example: `abc123_1703123456789.jpg`

### Platform Support

#### Mobile (Android/iOS)
- Images are stored locally in the app's documents directory
- Full offline support
- Automatic cleanup when products are deleted

#### Web
- Local storage not supported due to browser limitations
- Falls back to imgbb.com for image hosting
- Images are uploaded to external service and URLs are stored

### Database Schema
The Firestore `products` collection now stores image paths instead of URLs:

```json
{
  "imageUrl": "/data/user/0/com.example.vegieconnect/app_flutter/product_images/abc123_1703123456789.jpg"
}
```

For web platform, it still stores imgbb URLs:
```json
{
  "imageUrl": "https://i.ibb.co/example/image.jpg"
}
```

## Usage Examples

### Adding a Product with Image
```dart
// In AddProductPage
final imagePath = await _saveImageLocally(productId);
if (imagePath != null) {
  await docRef.update({'imageUrl': imagePath});
}
```

### Displaying Product Images
```dart
// Using ProductImageWidget
ProductImageWidget(
  imagePath: product['imageUrl'] ?? '',
  width: 120,
  height: 120,
  placeholder: Icon(Icons.shopping_basket),
)
```

### Deleting Product Images
```dart
// In SupplierDashboard
if (ImageStorageService.isLocalPath(imageUrl)) {
  await ImageStorageService.deleteImage(imageUrl);
}
```

## Benefits

1. **Performance**: Faster image loading, no network requests for local images
2. **Offline Support**: Images work without internet connection
3. **Cost Savings**: No external image hosting costs
4. **Privacy**: Images stay on user's device
5. **Reliability**: No dependency on external services

## Limitations

1. **Web Platform**: Still requires external hosting (imgbb.com)
2. **Storage Space**: Images consume device storage
3. **Cross-Device**: Images don't sync across devices
4. **Backup**: Images aren't automatically backed up

## Migration Notes

### Existing Products
- Products with existing imgbb URLs will continue to work
- New products will use local storage (mobile) or imgbb (web)
- No automatic migration of existing images

### Cleanup
The system automatically cleans up local images when:
- Products are deleted
- Images are replaced during product updates

## Future Enhancements

1. **Image Compression**: Implement automatic image compression to save space
2. **Cloud Sync**: Add option to sync images to cloud storage
3. **Multiple Images**: Support for multiple images per product
4. **Image Caching**: Implement caching for network images
5. **Batch Operations**: Optimize bulk image operations

## Troubleshooting

### Common Issues

1. **Images not displaying on mobile**
   - Check if image path is valid
   - Verify file exists in local storage
   - Check app permissions

2. **Images not displaying on web**
   - Verify imgbb API key is valid
   - Check network connectivity
   - Review browser console for errors

3. **Storage space issues**
   - Implement image compression
   - Add storage cleanup functionality
   - Monitor app storage usage

### Debug Commands
```dart
// List all product images
final images = await ImageStorageService.getProductImages(productId);
print('Product images: $images');

// Clear all product images (for testing)
await ImageStorageService.clearAllProductImages();
``` 