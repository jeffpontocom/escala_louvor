importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({  
  apiKey: 'AIzaSyBp_lsWvNrPhSCKoW3eXS1uDoxXGdBBWns',
  appId: '1:420088880029:web:7f20d85ded9fd777482d74',
  messagingSenderId: '420088880029',
  projectId: 'escala-louvor-ipbfoz',
  authDomain: 'escala-louvor-ipbfoz.firebaseapp.com',
  storageBucket: 'escala-louvor-ipbfoz.appspot.com',
  //databaseURL: "https://escala-louvor-ipbfoz.firebaseio.com",
});
// Necessary to receive background messages:
const messaging = firebase.messaging();

// Optional:
messaging.onBackgroundMessage((m) => {
  console.log("onBackgroundMessage", m);
});