# Real-Time Chat Implementation

## Overview

This document describes the comprehensive real-time chat system implemented in VegieConnect that enables seamless communication between suppliers and buyers.

## Features

### 🔄 Real-Time Messaging
- **Instant Message Delivery**: Messages are delivered in real-time using Firebase Firestore
- **Typing Indicators**: Shows when users are typing
- **Message Status**: Tracks sending, sent, delivered, and read status
- **Auto-scroll**: Automatically scrolls to new messages

### 💬 Chat Management
- **Supplier-Buyer Chat**: Dedicated chat system for supplier-customer communication
- **Chat History**: Persistent message history
- **Unread Message Count**: Tracks unread messages with badge notifications
- **Message Actions**: Copy, delete, and manage messages

### 🔔 Notifications
- **Push Notifications**: Firebase Cloud Messaging integration
- **In-App Notifications**: Real-time notification center
- **Chat Notifications**: Notify users of new messages
- **Unread Badges**: Visual indicators for unread messages

## Architecture

### Services

#### MessagingService (`lib/services/messaging_service.dart`)
Core service handling all chat functionality:

```dart
class MessagingService {
  // Real-time message streams
  Stream<List<ChatMessage>> getChatStream(String chatId)
  
  // Typing indicators
  Stream<Map<String, bool>> getTypingStream(String chatId)
  
  // Message operations
  Future<void> sendMessage({required String chatId, required String message})
  Future<void> startTyping(String chatId)
  Future<void> stopTyping(String chatId)
  
  // Chat management
  Future<String> createChatWithSupplier(String supplierId)
  Stream<List<ChatSummary>> getSupplierChats()
  Stream<List<ChatSummary>> getBuyerChats()
}
```

#### NotificationService (`lib/services/notification_service.dart`)
Handles push notifications and in-app notifications:

```dart
class NotificationService {
  // Notification streams
  Stream<NotificationData> get notificationStream
  
  // Send notifications
  void sendChatNotification({required String senderName, required String message})
  void sendOrderUpdateNotification({required String orderId, required String status})
}
```

### Models

#### ChatMessage
```dart
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final String? imageUrl;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String> readBy;
  final DateTime? readAt;
}
```

#### ChatSummary
```dart
class ChatSummary {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastSenderId;
  final String? lastSenderName;
  final Map<String, dynamic>? metadata;
}
```

## Implementation Details

### Real-Time Features

#### 1. Typing Indicators
- Uses Firestore real-time listeners to track typing status
- Automatically stops typing indicator after 2 seconds of inactivity
- Shows "typing..." in chat header when other user is typing

```dart
// Start typing
await _messagingService.startTyping(chatId);

// Stop typing (automatic after 2 seconds)
await _messagingService.stopTyping(chatId);
```

#### 2. Message Status Tracking
- **Sending**: Message is being sent to server
- **Sent**: Message successfully sent to server
- **Delivered**: Message delivered to recipient
- **Read**: Message read by recipient
- **Failed**: Message failed to send

#### 3. Unread Message Count
- Real-time counter for unread messages
- Badge notifications in app bar
- Automatic marking as read when chat is opened

### Chat Pages

#### Customer Chat Page (`lib/customer-side/chat_page.dart`)
- Lists all customer chats
- Shows last message and timestamp
- Unread message indicators
- Search functionality (planned)

#### Supplier Chat Page (`lib/supplier-side/supplier_chat_page.dart`)
- Dedicated page for suppliers to view customer messages
- Customer information display
- Chat history management
- Real-time message updates

#### Chat Conversation Page (`lib/customer-side/chat_conversation_page.dart`)
- Real-time message display
- Typing indicators
- Message actions (copy, delete)
- Auto-scroll to new messages

### Widgets

#### ChatBubble (`lib/widgets/chat_widgets.dart`)
- Displays individual messages
- Different styling for own vs other messages
- Message status indicators
- Image support
- Long press for actions

#### MessageInput (`lib/widgets/chat_widgets.dart`)
- Text input with send button
- Typing indicator integration
- Image attachment support (planned)
- Loading states

#### NotificationCenter (`lib/widgets/notification_center.dart`)
- Unread message badge
- Notification history
- Real-time notification updates

## Database Structure

### Firestore Collections

#### `chats/{chatId}`
```json
{
  "participants": ["userId1", "userId2"],
  "participantNames": {
    "userId1": "User Name",
    "userId2": "Supplier Name"
  },
  "chatType": "supplier_buyer",
  "lastMessage": "Hello!",
  "lastMessageTime": "2024-01-01T12:00:00Z",
  "lastSenderId": "userId1",
  "lastSenderName": "User Name",
  "typingUsers": {
    "userId1": true
  },
  "createdAt": "2024-01-01T12:00:00Z",
  "updatedAt": "2024-01-01T12:00:00Z"
}
```

#### `chats/{chatId}/messages/{messageId}`
```json
{
  "senderId": "userId1",
  "senderName": "User Name",
  "message": "Hello!",
  "imageUrl": null,
  "timestamp": "2024-01-01T12:00:00Z",
  "status": "sent",
  "readBy": ["userId2"],
  "readAt": "2024-01-01T12:01:00Z",
  "metadata": {}
}
```

## Usage Examples

### Starting a Chat with Supplier
```dart
final messagingService = MessagingService();
final chatId = await messagingService.createChatWithSupplier(supplierId);

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChatConversationPage(
      chatId: chatId,
      chatTitle: 'Supplier Name',
    ),
  ),
);
```

### Listening to Messages
```dart
_messagingService.getChatStream(chatId).listen((messages) {
  setState(() {
    _messages = messages;
  });
});
```

### Sending a Message
```dart
await _messagingService.sendMessage(
  chatId: chatId,
  message: 'Hello supplier!',
);
```

### Typing Indicators
```dart
// Start typing
await _messagingService.startTyping(chatId);

// Listen to typing indicators
_messagingService.getTypingStream(chatId).listen((typingUsers) {
  setState(() {
    _typingUsers = typingUsers;
  });
});
```

## Security Rules

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chat access rules
    match /chats/{chatId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    // Message access rules
    match /chats/{chatId}/messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    }
  }
}
```

## Performance Optimizations

### 1. Message Caching
- Local cache for recent messages
- Reduces Firestore reads
- Improves app responsiveness

### 2. Pagination
- Loads only recent messages (50 messages)
- Reduces initial load time
- Efficient memory usage

### 3. Typing Debouncing
- 2-second delay before stopping typing indicator
- Reduces Firestore writes
- Better user experience

### 4. Connection Management
- Automatic reconnection on network changes
- Graceful error handling
- Offline message queuing (planned)

## Future Enhancements

### Planned Features
1. **Image Sharing**: Support for sending images in chat
2. **Voice Messages**: Audio message support
3. **File Sharing**: Document and file sharing
4. **Message Reactions**: Emoji reactions to messages
5. **Message Search**: Search through chat history
6. **Chat Groups**: Group conversations
7. **Message Encryption**: End-to-end encryption
8. **Offline Support**: Message queuing when offline

### Technical Improvements
1. **WebSocket Integration**: For even faster real-time updates
2. **Message Compression**: Reduce bandwidth usage
3. **Advanced Caching**: More sophisticated caching strategies
4. **Analytics**: Chat usage analytics
5. **Moderation**: Message filtering and moderation tools

## Testing

### Unit Tests
- Message sending/receiving
- Typing indicators
- Chat creation
- Error handling

### Integration Tests
- End-to-end chat flow
- Real-time synchronization
- Notification delivery

### Performance Tests
- Message load times
- Memory usage
- Network efficiency

## Troubleshooting

### Common Issues

#### Messages Not Sending
1. Check internet connection
2. Verify Firebase configuration
3. Check Firestore security rules
4. Ensure user authentication

#### Typing Indicators Not Working
1. Verify Firestore permissions
2. Check real-time listeners
3. Ensure proper cleanup in dispose()

#### Notifications Not Showing
1. Check FCM configuration
2. Verify notification permissions
3. Test on physical device

### Debug Tools
- Firebase Console for real-time data
- Flutter Inspector for UI debugging
- Network profiler for performance analysis

## Conclusion

The real-time chat implementation provides a robust, scalable solution for supplier-buyer communication in VegieConnect. With features like typing indicators, message status tracking, and push notifications, it offers a modern chat experience comparable to popular messaging apps.

The architecture is designed for extensibility, allowing easy addition of new features like image sharing, voice messages, and group chats. The performance optimizations ensure smooth operation even with high message volumes. 