// Web push service worker (Firebase Cloud Messaging).
//
// Runs in the background when the Easy Study tab is closed or hidden: shows
// the notification the server sent and opens the app when it is clicked.
// The config below is the PUBLIC web config from lib/firebase_options.dart
// (same values the page itself ships). The SDK version matches the one the
// firebase_core_web plugin loads in the page.
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAJySwXYdNO1GUdz_KsVdPd0ODvkf7wLbw',
  appId: '1:345172802163:web:eba1c1f72153d5d034c806',
  messagingSenderId: '345172802163',
  projectId: 'chinese-tracker',
  authDomain: 'chinese-tracker.firebaseapp.com',
  storageBucket: 'chinese-tracker.firebasestorage.app',
  measurementId: 'G-T3YQ23FKP8',
});

var messaging = firebase.messaging();
var APP_URL = self.location.origin + '/';

// Messages with a `notification` block are shown by the browser itself; this
// handler covers data-only messages so nothing is dropped silently.
messaging.onBackgroundMessage(function (payload) {
  if (payload.notification) return;
  var data = payload.data || {};
  var title = data.title || 'Easy Study';
  self.registration.showNotification(title, {
    body: data.body || '',
    icon: '/icons/Icon-192.png',
    data: { link: data.link || APP_URL },
  });
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  var link = (event.notification.data && event.notification.data.link) ||
    (event.notification.fcmOptions && event.notification.fcmOptions.link) ||
    APP_URL;
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function (list) {
      for (var i = 0; i < list.length; i++) {
        var client = list[i];
        if (client.url.indexOf(self.location.origin) === 0 && 'focus' in client) {
          return client.focus();
        }
      }
      return clients.openWindow(link);
    })
  );
});
