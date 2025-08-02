# Chat Integration Guide

This guide explains how to integrate the unified chat system between suppliers and buyers in the VegieConnect app.

## Overview

The chat system has been enhanced to provide seamless communication between suppliers and buyers with the following features:

- **Real-time messaging** with typing indicators
- **Unified chat interface** for both suppliers and buyers
- **Enhanced metadata** for better user experience
- **Caching system** for improved performance
- **Error handling** and validation

## Key Components

### 1. MessagingService (`lib/services/messaging_service.dart`)

The core service that handles all chat functionality:

```dart
// Initialize the service
final messagingService = MessagingService();
await messagingService.initialize();

// Create a chat with a supplier
String chatId = await messagingService.createChatWithSupplier(supplierId);

// Send a message
await messagingService.sendMessage(
  chatId: chatId,
  message: "Hello, I'm interested in your products!",
);

// Get chat stream
Stream<List<ChatMessage>> messages = messagingService.getChatMessages(chatId);

// Get user chats
Stream<List<ChatSummary>> chats = messagingService.getRealCustomerSupplierChats();
```

### 2. ChatNavigationService (`lib/services/chat_navigation_service.dart`)

Handles navigation between chat screens:

```dart
// Start a new chat with supplier
await chatNavigationService.startChatWithSupplierById(
  context,
  supplierId,
  supplierName,
);

// Open existing chat
await chatNavigationService.openExistingChat(
  context,
  chatId,
  chatTitle,
);
```

### 3. UnifiedChatWidget (`lib/widgets/unified_chat_widget.dart`)

A unified widget that works for both suppliers and buyers:

```dart
// For suppliers
UnifiedChatWidget(userRole: 'supplier')

// For buyers
UnifiedChatWidget(userRole: 'buyer')
```

## Integration Steps

### For Suppliers

1. **Replace the existing supplier chat page** with the unified widget:

```dart
// In supplier dashboard or navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const UnifiedChatWidget(userRole: 'supplier'),
  ),
);
```

2. **Add chat notifications** to your supplier dashboard:

```dart
StreamBuilder<int>(
  stream: messagingService.getUnreadMessageCount(),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data ?? 0;
    return Badge(
      label: Text('$unreadCount'),
      child: IconButton(
        icon: const Icon(Icons.chat),
        onPressed: () => _openChatPage(),
      ),
    );
  },
)
```

### For Buyers

1. **Add chat functionality to product pages**:

```dart
// In product detail page
ElevatedButton(
  onPressed: () => _startChatWithSupplier(),
  child: const Text('Chat with Supplier'),
)

void _startChatWithSupplier() {
  final chatNavigationService = ChatNavigationService();
  chatNavigationService.startChatWithSupplier(
    context,
    {
      'sellerId': product['sellerId'],
      'supplierName': product['supplierName'],
    },
  );
}
```

2. **Add chat access to buyer dashboard**:

```dart
// In buyer navigation
UnifiedChatWidget(userRole: 'buyer')
```

## Data Structure

### Chat Document Structure

```json
{
  "id": "user1_user2",
  "participants": ["user1", "user2"],
  "participantNames": {
    "user1": "John Doe",
    "user2": "Jane Supplier"
  },
  "chatType": "supplier_buyer",
  "lastMessage": "Hello, I'm interested in your products!",
  "lastMessageTime": "2024-01-15T10:30:00Z",
  "lastSenderId": "user1",
  "lastSenderName": "John Doe",
  "createdAt": "2024-01-15T10:00:00Z",
  "updatedAt": "2024-01-15T10:30:00Z",
  "typingUsers": {},
  "metadata": {
    "participantNames": {
      "user1": "John Doe",
      "user2": "Jane Supplier"
    },
    "chatType": "supplier_buyer",
    "createdBy": "user1"
  }
}
```

### Message Document Structure

```json
{
  "id": "message_id",
  "senderId": "user1",
  "senderName": "John Doe",
  "message": "Hello, I'm interested in your products!",
  "timestamp": "2024-01-15T10:30:00Z",
  "status": "sent",
  "readBy": ["user2"],
  "metadata": {}
}
```

## Features

### Real-time Messaging
- Messages are sent and received in real-time
- Typing indicators show when someone is typing
- Message status tracking (sending, sent, delivered, read, failed)

### Enhanced User Experience
- Participant names are cached and displayed properly
- Chat titles are automatically generated
- Unread message counts
- Message timestamps and status indicators

### Error Handling
- Network error recovery
- Invalid chat session handling
- User authentication validation
- Graceful fallbacks for missing data

### Performance Optimizations
- Message caching for faster loading
- User data caching
- Efficient Firestore queries
- Stream management for memory efficiency

## Usage Examples

### Starting a Chat from Product Page

```dart
void startChatFromProduct(BuildContext context, Map<String, dynamic> product) {
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
```

### Displaying Chat List

```dart
StreamBuilder<List<ChatSummary>>(
  stream: messagingService.getRealCustomerSupplierChats(),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget('Error loading chats');
    }
    
    final chats = snapshot.data ?? [];
    
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          chat: chat,
          onTap: () => _openChat(chat),
          unreadCount: _getUnreadCount(chat),
        );
      },
    );
  },
)
```

### Sending Messages

```dart
Future<void> sendMessage(String chatId, String message) async {
  try {
    await messagingService.sendMessage(
      chatId: chatId,
      message: message,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error sending message: $e')),
    );
  }
}
```

## Troubleshooting

### Common Issues

1. **Chat not appearing in list**
   - Check if chat has `lastMessage` field
   - Verify user is in `participants` array
   - Ensure chat is not in deleted chats list

2. **Messages not sending**
   - Verify user authentication
   - Check network connectivity
   - Validate chat ID format

3. **Real-time updates not working**
   - Check Firestore security rules
   - Verify stream subscriptions
   - Check for error logs

### Debug Information

Enable debug logging to troubleshoot issues:

```dart
// In messaging service
debugPrint('Creating chat with supplier: $supplierId');
debugPrint('Chat created successfully: $chatId');
debugPrint('Message sent successfully: ${docRef.id}');
```

## Security Considerations

1. **Firestore Security Rules**
   - Users can only access chats they participate in
   - Messages are protected by chat-level permissions
   - User data is protected by user-level permissions

2. **Data Validation**
   - All inputs are validated before processing
   - User authentication is required for all operations
   - Chat IDs are validated before use

3. **Privacy**
   - Messages are only visible to chat participants
   - User data is cached locally for performance
   - Deleted chats are tracked per user

## Performance Tips

1. **Use caching effectively**
   - User data is cached for better performance
   - Chat messages are cached locally
   - Stream subscriptions are managed efficiently

2. **Optimize queries**
   - Use compound indexes for chat queries
   - Limit message history to recent messages
   - Use pagination for large chat lists

3. **Handle errors gracefully**
   - Provide fallback UI for errors
   - Retry failed operations
   - Show user-friendly error messages

## Future Enhancements

1. **Message search functionality**
2. **File and image sharing**
3. **Push notifications**
4. **Message reactions**
5. **Group chats**
6. **Message encryption**

This integration provides a robust, scalable chat system that works seamlessly between suppliers and buyers in the VegieConnect app. 