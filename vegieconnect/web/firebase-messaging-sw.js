/* Firebase Cloud Messaging Service Worker for Flutter Web */

/* Use compat builds for service worker support */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Initialize Firebase inside the service worker with the same options as the app
firebase.initializeApp({
  apiKey: 'AIzaSyDQQoWOIpRRe2tVISTfPHLZZZYlEZSPAoM',
  authDomain: 'vegieconnect-6bd73.firebaseapp.com',
  projectId: 'vegieconnect-6bd73',
  storageBucket: 'vegieconnect-6bd73.firebasestorage.app',
  messagingSenderId: '686566418513',
  appId: '1:686566418513:web:84f84c83127fe339547070',
  measurementId: 'G-0WZB3ZJ4N0'
});

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'New message';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {}
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});


