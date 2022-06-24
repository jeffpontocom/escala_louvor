importScripts("https://www.gstatic.com/firebasejs/9.8.3/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.8.3/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyBp_lsWvNrPhSCKoW3eXS1uDoxXGdBBWns",
  authDomain: "escala-louvor-ipbfoz.firebaseapp.com",
  databaseURL: "https://escala-louvor-ipbfoz-default-rtdb.firebaseio.com",
  projectId: "escala-louvor-ipbfoz",
  storageBucket: "escala-louvor-ipbfoz.appspot.com",
  messagingSenderId: "420088880029",
  appId: "1:420088880029:web:7f20d85ded9fd777482d74",
};

const app = firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging(app);

// Tratamento para mensagem recebida em background
messaging.onBackgroundMessage(function (message) {
  console.log('[FCM] Mensagem recebida em background', message);
  const promiseChain = clients
    .matchAll({
      type: "window",
      includeUncontrolled: true
    })
    .then(windowClients => {
      for (let i = 0; i < windowClients.length; i++) {
        const windowClient = windowClients[i];
        windowClient.postMessage(message);
      }
    })
    .then(() => {
      const title = message.notification.title;
      const options = { body: message.notification.body }
      return registration.showNotification(title, options);
    });
  return promiseChain;
});

// Tratamento para clique em mensagem recebida
self.addEventListener('notificationclick', function (event) {
  console.log('[FCM] Clique em notificação: ', event)
  const target = event.notification.data.click_action || '/';
  event.notification.close();

  event.waitUntil(clients.matchAll({
    type: 'window',
    includeUncontrolled: true
  }).then(function (clientList) {
    for (var i = 0; i < clientList.length; i++) {
      var client = clientList[i];
      if (client.url === target && 'focus' in client) {
        return client.focus();
      }
    }
    if (clients.openWindow) {
      return clients.openWindow(target);
    }
  }));
});
