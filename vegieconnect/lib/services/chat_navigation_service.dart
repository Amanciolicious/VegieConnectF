import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messaging_service.dart';
import '../customer-side/chat_conversation_page.dart';
import '../theme.dart';

class ChatNavigationService {
  static final ChatNavigationService _instance = ChatNavigationService._internal();
  factory ChatNavigationService() => _instance;
  ChatNavigationService._internal();

  final MessagingService _messagingService = MessagingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Start a chat with a supplier from product details
  Future<void> startChatWithSupplier(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Validate user authentication
      final user = _auth.currentUser;
      if (user == null) {
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, 'Please log in to start a chat');
        return;
      }

      // Validate supplier information
      final supplierId = product['sellerId'];
      if (supplierId == null || supplierId.toString().isEmpty) {
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, 'Invalid supplier information');
        return;
      }

      // Prevent self-chatting
      if (supplierId == user.uid) {
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, 'You cannot chat with yourself');
        return;
      }

      // Get supplier details for better chat metadata
      String supplierName = 'Supplier';
      try {
        final supplierDoc = await _firestore.collection('users').doc(supplierId.toString()).get();
        if (supplierDoc.exists) {
          supplierName = supplierDoc.data()?['displayName'] ?? 
                        supplierDoc.data()?['email'] ?? 
                        product['supplierName'] ?? 
                        'Supplier';
        }
      } catch (e) {
        debugPrint('Error fetching supplier details: $e');
        supplierName = product['supplierName'] ?? 'Supplier';
      }

      // Create or get chat
      debugPrint('Creating chat with supplier: $supplierId');
      final chatId = await _messagingService.createChatWithSupplier(supplierId.toString());
      debugPrint('Chat created successfully: $chatId');
      
      // Verify chat was created properly
      if (chatId.isEmpty) {
        throw Exception('Failed to create chat - empty chat ID returned');
      }

      // Close loading dialog
      _closeLoadingDialog(context);

      // Navigate to chat conversation
      if (context.mounted) {
        debugPrint('Navigating to chat conversation: $chatId with title: $supplierName');
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationPage(
              chatId: chatId,
              chatTitle: supplierName,
            ),
          ),
        );

        // Show success message when returning
        _showSuccessSnackBar(context, 'Chat session ended');
      }
    } catch (e) {
      debugPrint('Chat navigation error: $e');
      _closeLoadingDialog(context);
      _showErrorSnackBar(context, 'Error starting chat: ${e.toString()}');
    }
  }

  /// Start a chat with a supplier using supplier ID and name
  Future<void> startChatWithSupplierById(
    BuildContext context,
    String supplierId,
    String supplierName,
  ) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Validate user authentication
      final user = _auth.currentUser;
      if (user == null) {
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, 'Please log in to start a chat');
        return;
      }

      // Validate supplier ID
      if (supplierId.isEmpty) {
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, 'Invalid supplier information');
        return;
      }

      // Prevent self-chatting
      if (supplierId == user.uid) {
        _closeLoadingDialog(context);
        _showErrorSnackBar(context, 'You cannot chat with yourself');
        return;
      }

      // Create or get chat
      debugPrint('Creating chat with supplier: $supplierId');
      final chatId = await _messagingService.createChatWithSupplier(supplierId);
      debugPrint('Chat created successfully: $chatId');
      
      // Verify chat was created properly
      if (chatId.isEmpty) {
        throw Exception('Failed to create chat - empty chat ID returned');
      }

      // Close loading dialog
      _closeLoadingDialog(context);

      // Navigate to chat conversation
      if (context.mounted) {
        debugPrint('Navigating to chat conversation: $chatId with title: $supplierName');
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationPage(
              chatId: chatId,
              chatTitle: supplierName,
            ),
          ),
        );

        // Show success message when returning
        _showSuccessSnackBar(context, 'Chat session ended');
      }
    } catch (e) {
      debugPrint('Chat navigation error: $e');
      _closeLoadingDialog(context);
      _showErrorSnackBar(context, 'Error starting chat: ${e.toString()}');
    }
  }

  /// Open an existing chat conversation
  Future<void> openExistingChat(
    BuildContext context,
    String chatId,
    String chatTitle,
  ) async {
    try {
      // Validate chat ID
      if (chatId.isEmpty) {
        _showErrorSnackBar(context, 'Invalid chat session');
        return;
      }

      // Navigate to chat conversation
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatConversationPage(
              chatId: chatId,
              chatTitle: chatTitle,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening existing chat: $e');
      _showErrorSnackBar(context, 'Error opening chat: ${e.toString()}');
    }
  }

  /// Close loading dialog safely
  void _closeLoadingDialog(BuildContext context) {
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
  }

  /// Show success snackbar
  void _showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  /// Check if user can chat with supplier
  bool canChatWithSupplier(String supplierId) {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (supplierId.isEmpty) return false;
    if (supplierId == user.uid) return false;
    return true;
  }

  /// Get chat validation error message
  String? getChatValidationError(String supplierId) {
    final user = _auth.currentUser;
    if (user == null) return 'Please log in to start a chat';
    if (supplierId.isEmpty) return 'Invalid supplier information';
    if (supplierId == user.uid) return 'You cannot chat with yourself';
    return null;
  }
} 