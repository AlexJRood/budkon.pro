// web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

const firebaseConfig = {
  apiKey: 'AIzaSyBTcKfCA26Ho_DmzJzXRQL0DV8vg0fOAps',
  authDomain: 'hously-ai-5b29c.firebaseapp.com',
  projectId: 'hously-ai-5b29c',
  storageBucket: 'hously-ai-5b29c.firebasestorage.app',
  messagingSenderId: '456073729010',
  appId: '1:456073729010:web:99f132db8ff22053e8916b',
  measurementId: 'G-JPMK21YCCT',
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// FCM background messages (tab hidden / closed)
messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || payload.data?.title || 'Hously';
  const body  = payload.notification?.body  || payload.data?.body  || '';
  const icon  = '/icons/Icon-192.png';

  self.registration.showNotification(title, {
    body,
    icon,
    data: payload.data || {},
  });
});

// DevTools "Push" button test (not FCM-formatted)

///// PRODUCTION REMOVE /////
// self.addEventListener('push', (event) => {
//   const msg = event.data ? event.data.text() : 'DevTools push';
//   event.waitUntil(
//     self.registration.showNotification('Push event', { body: msg })
//   );
// });

// Focus/open app when user clicks notification
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const link = event.notification.data?.link || '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((list) => {
      for (const c of list) {
        if ('url' in c && c.url.includes(self.location.origin)) {
          return c.focus();
        }
      }
      return clients.openWindow(link);
    })
  );
});
