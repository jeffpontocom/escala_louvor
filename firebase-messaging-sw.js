importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({    
  apiKey: "AIzaSyBp_lsWvNrPhSCKoW3eXS1uDoxXGdBBWns",
  authDomain: "escala-louvor-ipbfoz.firebaseapp.com",
  databaseURL: "https://escala-louvor-ipbfoz-default-rtdb.firebaseio.com",
  projectId: "escala-louvor-ipbfoz",
  storageBucket: "escala-louvor-ipbfoz.appspot.com",
  messagingSenderId: "420088880029",
  appId: "1:420088880029:web:7f20d85ded9fd777482d74",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((m) => {
    console.log("onBackgroundMessage", m);
  });

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
            return registration.showNotification("New Message");
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});