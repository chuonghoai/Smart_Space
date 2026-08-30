importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBnfQ1Eo6hfJ1rEnO3i4JOObGT_O8Iw1ak",
  authDomain: "smart-space-36687.firebaseapp.com",
  projectId: "smart-space-36687",
  storageBucket: "smart-space-36687.firebasestorage.app",
  messagingSenderId: "481022634874",
  appId: "1:481022634874:web:1d27ccf373ebbfde0ac4c3"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Background message:', payload);
  const { title, body } = payload.notification;
  self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png'
  });
});
