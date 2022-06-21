'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "assets/AssetManifest.json": "8564b176f235d2a9eafa6393c91bfa67",
"assets/assets/fonts/Offside-Regular.ttf": "37cc5e97dd9817746e5510afe29a5f1d",
"assets/assets/fonts/OpenSans_SemiCondensed-Bold.ttf": "0263aea0499c2422dfb70c6fa0034ca0",
"assets/assets/fonts/OpenSans_SemiCondensed-Light.ttf": "c6d6df27d3de5a815f6d4d8cf6313b45",
"assets/assets/fonts/OpenSans_SemiCondensed-Regular.ttf": "3a57029a9eaa845dec055cd9fd05b4dc",
"assets/assets/fonts/Ubuntu-Bold.ttf": "896a60219f6157eab096825a0c9348a8",
"assets/assets/fonts/Ubuntu-BoldItalic.ttf": "c16e64c04752a33fc51b2b17df0fb495",
"assets/assets/fonts/Ubuntu-Italic.ttf": "9f353a170ad1caeba1782d03dd8656b5",
"assets/assets/fonts/Ubuntu-Light.ttf": "c9d68f61bf89fde6a24da697bc45d6f9",
"assets/assets/fonts/Ubuntu-LightItalic.ttf": "b242f3fdf0e61d01f35f0dec0170b200",
"assets/assets/fonts/Ubuntu-Regular.ttf": "84ea7c5c9d2fa40c070ccb901046117d",
"assets/assets/icons/ic_disponivel.png": "18ae178291f7477646ce272690318371",
"assets/assets/icons/ic_escalado.png": "62a72260bc5c82b0425f22aeac90420f",
"assets/assets/icons/ic_indeciso.png": "2b6c2aec10a5dc1a3b72145777754bf8",
"assets/assets/icons/ic_launcher.png": "f61fabf2c2dd19ee5b99b9774bed3afa",
"assets/assets/icons/ic_restrito.png": "dcf521f39828dba9e0377f5e4dc12f96",
"assets/assets/icons/music_baixo.png": "cab8215278448c4a8cb4100f214bfb92",
"assets/assets/icons/music_bateria.png": "d028166b4e828157c31448d2e679f9b6",
"assets/assets/icons/music_coordenador.png": "9de937aac566188a4a884247bd38966f",
"assets/assets/icons/music_dirigente.png": "95600e0cbe155be6cf966be4c9e9adb7",
"assets/assets/icons/music_guitarra.png": "080666cb0a8f8c21df77d020c9d6163a",
"assets/assets/icons/music_percussao.png": "1ac11698bbf59939cdca72c1b736291e",
"assets/assets/icons/music_piano.png": "1d69c596f212e956cdefd1b1b287e361",
"assets/assets/icons/music_sonorizacao.png": "06dfd83a2ddbf6c1123316f5f25102cf",
"assets/assets/icons/music_sopro.png": "e52dda81892031d888bf4845012a8d54",
"assets/assets/icons/music_teclado.png": "916507d0ad89c78aa965494c433dbf03",
"assets/assets/icons/music_transmissao.png": "861bb95a423ef909781e181230d33932",
"assets/assets/icons/music_violao.png": "e6e25f8cc3cd126e2621b2f4941058a8",
"assets/assets/icons/music_voz.png": "24f0c4b6a28d17ca4dc04405f516588f",
"assets/assets/images/chat.png": "bb3d4b45b8df735301b60d182882e05b",
"assets/assets/images/church.png": "3244ed1fe3e156ff454b59776acb57b2",
"assets/assets/images/fail.png": "9186a7c1e067feb7ef38bbcdce9e716c",
"assets/assets/images/login.png": "2312a4310a3e38bc5f8f2806999ff1df",
"assets/assets/images/song.png": "e9e0d5d4d9f7135bfd477c1cfe119100",
"assets/dotenv.txt": "08dbd95bc9eb3f6cef2ccb70eb5547f5",
"assets/FontManifest.json": "b2a7fd1d935801592b4ca8eaceb8e255",
"assets/fonts/MaterialIcons-Regular.otf": "95db9098c58fd6db106f1116bae85a0b",
"assets/NOTICES": "53e64b5c9dfd7d3c0ad3db4d6ac12279",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "d1722d5cf2c7855862f68edb85e31f88",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "613e4cc1af0eb5148b8ce409ad35446d",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "dd3c4233029270506ecc994d67785a37",
"assets/packages/wakelock_web/assets/no_sleep.js": "7748a45cd593f33280669b29c2c8919a",
"favicon.png": "d9f0bfa8d2610aa0c02ab61c04f57df6",
"firebase-messaging-sw.js": "0af3c796d0888ddb71941901360469b9",
"icons/Icon-192.png": "701e43ae3eb8ad390c9b65537bc8a169",
"icons/Icon-512.png": "51cbe3b1cb0ac7ddd62f3833cba6f39a",
"icons/Icon-maskable-192.png": "701e43ae3eb8ad390c9b65537bc8a169",
"icons/Icon-maskable-512.png": "51cbe3b1cb0ac7ddd62f3833cba6f39a",
"index.html": "9a79bdf412766cc5e5bd87a6fc9a3327",
"/": "9a79bdf412766cc5e5bd87a6fc9a3327",
"main.dart.js": "828ba91c9d2d9c6134662ab510dcf248",
"manifest.json": "7051455cda8feb95c100f8203fb1431e",
"version.json": "de50d8718edadba767b2b58f08233069"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "main.dart.js",
"index.html",
"assets/NOTICES",
"assets/AssetManifest.json",
"assets/FontManifest.json"];
// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache.
        return response || fetch(event.request).then((response) => {
          cache.put(event.request, response.clone());
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}

// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}