importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging.js");

firebase.initializeApp({  
    apiKey: 'AIzaSyBp_lsWvNrPhSCKoW3eXS1uDoxXGdBBWns',
    appId: '1:420088880029:web:7f20d85ded9fd777482d74',
    messagingSenderId: '420088880029',
    projectId: 'escala-louvor-ipbfoz',
    authDomain: 'escala-louvor-ipbfoz.firebaseapp.com',
    databaseURL: 'https://escala-louvor-ipbfoz-default-rtdb.firebaseio.com',
    storageBucket: 'escala-louvor-ipbfoz.appspot.com',
});
// Necessary to receive background messages:
const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
  const promiseChain = clients
      .matchAll({
          type: "window",
          includeUncontrolled: true
      })
      .then(windowClients => {
          for (let i = 0; i < windowClients.length; i++) {
              const windowClient = windowClients[i];
              windowClient.postMessage(payload);
          }
      })
      .then(() => {
          return registration.showNotification("Nova mensagem");
      });
  return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
  console.log('notification received: ', event)
});

// Optional:
messaging.onBackgroundMessage((m) => {
  console.log("onBackgroundMessage", m);
});