import 'package:flutter/material.dart';
import '../services/messaging_service.dart';
import '../services/chat_navigation_service.dart';
import '../widgets/unified_chat_widget.dart';
import '../theme.dart';

/// Example showing how to integrate chat functionality into existing pages
class ChatIntegrationExample extends StatefulWidget {
  const ChatIntegrationExample({super.key});

  @override
  State<ChatIntegrationExample> createState() => _ChatIntegrationExampleState();
}

class _ChatIntegrationExampleState extends State<ChatIntegrationExample> {
  final MessagingService _messagingService = MessagingService();
  final ChatNavigationService _chatNavigationService = ChatNavigationService();

  @override
  void initState() {
    super.initState();
    _messagingService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Integration Examples'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            '1. Product Page Chat Button',
            'Add a chat button to product detail pages',
            _buildProductChatExample(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            '2. Supplier Dashboard Chat',
            'Add chat access to supplier dashboard',
            _buildSupplierChatExample(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            '3. Buyer Chat List',
            'Add chat list to buyer dashboard',
            _buildBuyerChatExample(),
          ),
          const SizedBox(height: 24),
          _buildSection(
            '4. Chat Notifications',
            'Show unread message count',
            _buildChatNotificationsExample(0),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String description, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.headline,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  // Example 1: Product Page Chat Button
  Widget _buildProductChatExample() {
    return Column(
      children: [
        // Simulated product data
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              const Text(
                'Fresh Organic Tomatoes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Supplier: Green Valley Farms'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _startChatFromProduct(),
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Supplier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Code Example:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '''
ElevatedButton(
  onPressed: () => _startChatFromProduct(),
  child: Text('Chat with Supplier'),
)

void _startChatFromProduct() {
  final chatNavigationService = ChatNavigationService();
  chatNavigationService.startChatWithSupplier(
    context,
    {
      'sellerId': product['sellerId'],
      'supplierName': product['supplierName'],
    },
  );
}
            ''',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Example 2: Supplier Dashboard Chat
  Widget _buildSupplierChatExample() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _openSupplierChat(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Open Supplier Chat Dashboard'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Code Example:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '''
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const UnifiedChatWidget(userRole: 'supplier'),
  ),
);
            ''',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Example 3: Buyer Chat List
  Widget _buildBuyerChatExample() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _openBuyerChat(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Open Buyer Chat List'),
        ),
        const SizedBox(height: 16),
        const Text(
          'Code Example:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '''
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const UnifiedChatWidget(userRole: 'buyer'),
  ),
);
            ''',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Example 4: Chat Notifications
  Widget _buildChatNotificationsExample(dynamic unreadCount) {
    return Column(
      children: [
        StreamBuilder<int>(
          stream: _messagingService.getUnreadMessageCount(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openChatWithBadge(),
                  icon: const Icon(Icons.chat),
                  label: Text('Chat ($unreadCount)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unreadCount > 0 
                        ? AppColors.accentRed 
                        : AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Code Example:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '''
StreamBuilder<int>(
  stream: messagingService.getUnreadMessageCount(),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;
    return Badge(
      label: Text('$unreadCount'),
      child: IconButton(
        icon: Icon(Icons.chat),
        onPressed: () => _openChatPage(),
      ),
    );
  },
)
            ''',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  // Navigation methods
  void _startChatFromProduct() {
    // Simulate product data
    final product = {
      'sellerId': 'supplier123',
      'supplierName': 'Green Valley Farms',
    };

    // Validate user can chat
    if (!_chatNavigationService.canChatWithSupplier(product['sellerId']!)) {
      final error = _chatNavigationService.getChatValidationError(product['sellerId']!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Cannot start chat')),
      );
      return;
    }

    // Start chat
    _chatNavigationService.startChatWithSupplier(context, product);
  }

  void _openSupplierChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UnifiedChatWidget(userRole: 'supplier'),
      ),
    );
  }

  void _openBuyerChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UnifiedChatWidget(userRole: 'buyer'),
      ),
    );
  }

  void _openChatWithBadge() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UnifiedChatWidget(userRole: 'buyer'),
      ),
    );
  }
}

/// Example of integrating chat into a product detail page
class ProductDetailPageExample extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPageExample({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product'),
        backgroundColor: AppColors.primaryGreen,
      ),
      body: Column(
        children: [
          // Product details would go here
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Product image, description, price, etc.
                const Text('Product details...'),
              ],
            ),
          ),
          // Chat button at bottom
          Container(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _startChatWithSupplier(context),
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Supplier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startChatWithSupplier(BuildContext context) {
    final chatNavigationService = ChatNavigationService();
    
    // Validate user can chat
    if (!chatNavigationService.canChatWithSupplier(product['sellerId'])) {
      final error = chatNavigationService.getChatValidationError(product['sellerId']);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Cannot start chat')),
      );
      return;
    }
    
    // Start chat
    chatNavigationService.startChatWithSupplier(context, product);
  }
}

/// Example of integrating chat into a supplier dashboard
class SupplierDashboardExample extends StatelessWidget {
  const SupplierDashboardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Dashboard'),
        backgroundColor: AppColors.primaryGreen,
        actions: [
          // Chat notification badge
          StreamBuilder<int>(
            stream: MessagingService().getUnreadMessageCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () => _openChat(context),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accentRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Supplier dashboard content...'),
      ),
    );
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const UnifiedChatWidget(userRole: 'supplier'),
      ),
    );
  }
} 