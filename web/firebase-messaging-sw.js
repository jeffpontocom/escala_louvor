import { initializeApp } from "firebase/app";
import { getMessaging } from "firebase/messaging";

//importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
//importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

const firebaseConfig = {    
  apiKey: "AIzaSyBp_lsWvNrPhSCKoW3eXS1uDoxXGdBBWns",
  authDomain: "escala-louvor-ipbfoz.firebaseapp.com",
  databaseURL: "https://escala-louvor-ipbfoz-default-rtdb.firebaseio.com",
  projectId: "escala-louvor-ipbfoz",
  storageBucket: "escala-louvor-ipbfoz.appspot.com",
  messagingSenderId: "420088880029",
  appId: "1:420088880029:web:7f20d85ded9fd777482d74",
};

//firebase.initializeApp(firebaseConfig);
//const messaging = firebase.messaging();

const app = initializeApp(firebaseConfig);
const messaging = getMessaging(app);

messaging.setBackgroundMessageHandler(function (payload) {
  payload.data.data = JSON.parse(JSON.stringify(payload.data));
  return self.registration.showNotification(payload.data.title, payload.data);

    /* const promiseChain = clients
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
            return registration.showNotification("New Message");
        });
    return promiseChain; */
});

self.addEventListener('notificationclick', function (event) {
  console.log('notification received: ', event)
  const target = event.notification.data.click_action || '/';
  event.notification.close();

  // This looks to see if the current is already open and focuses if it is
  event.waitUntil(clients.matchAll({
    type: 'window',
    includeUncontrolled: true
  }).then(function(clientList) {
    // clientList always is empty?!
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