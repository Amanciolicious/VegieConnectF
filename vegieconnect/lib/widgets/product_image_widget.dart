import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/image_storage_service.dart';

class ProductImageWidget extends StatelessWidget {
  final String imagePath;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ProductImageWidget({
    super.key,
    required this.imagePath,
    this.width = 120,
    this.height = 120,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    // Check if it's a local path
    if (ImageStorageService.isLocalPath(imagePath)) {
      if (kIsWeb) {
        // Web doesn't support local file access, show placeholder
        return _buildPlaceholder();
      }
      
      final file = ImageStorageService.loadImageFromPath(imagePath);
      if (file != null) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      } else {
        return _buildErrorWidget();
      }
    }
    
    // Check if it's a network URL
    if (ImageStorageService.isNetworkUrl(imagePath)) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    }

    // Default placeholder for invalid paths
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) {
      return SizedBox(
        width: width,
        height: height,
        child: placeholder!,
      );
    }
    
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(
        Icons.camera_alt,
        size: 40,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) {
      return SizedBox(
        width: width,
        height: height,
        child: errorWidget!,
      );
    }
    
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(
        Icons.broken_image,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
} 