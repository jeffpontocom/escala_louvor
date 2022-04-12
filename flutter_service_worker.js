'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "assets/AssetManifest.json": "46f950362711d74d88c908cf1156a6b4",
"assets/assets/fonts/Offside-Regular.ttf": "37cc5e97dd9817746e5510afe29a5f1d",
"assets/assets/icons/ic_launcher.png": "f61fabf2c2dd19ee5b99b9774bed3afa",
"assets/assets/icons/music_baixo.png": "cab8215278448c4a8cb4100f214bfb92",
"assets/assets/icons/music_bateria.png": "d028166b4e828157c31448d2e679f9b6",
"assets/assets/icons/music_coordenador.png": "9de937aac566188a4a884247bd38966f",
"assets/assets/icons/music_dirigente.png": "95600e0cbe155be6cf966be4c9e9adb7",
"assets/assets/icons/music_guitarra.png": "080666cb0a8f8c21df77d020c9d6163a",
"assets/assets/icons/music_percussao.png": "1ac11698bbf59939cdca72c1b736291e",
"assets/assets/icons/music_sonorizacao.png": "06dfd83a2ddbf6c1123316f5f25102cf",
"assets/assets/icons/music_sopro.png": "e52dda81892031d888bf4845012a8d54",
"assets/assets/icons/music_teclado.png": "916507d0ad89c78aa965494c433dbf03",
"assets/assets/icons/music_transmissao.png": "861bb95a423ef909781e181230d33932",
"assets/assets/icons/music_violao.png": "e6e25f8cc3cd126e2621b2f4941058a8",
"assets/assets/icons/music_voz.png": "24f0c4b6a28d17ca4dc04405f516588f",
"assets/assets/images/chat.png": "bb3d4b45b8df735301b60d182882e05b",
"assets/assets/images/church.png": "3244ed1fe3e156ff454b59776acb57b2",
"assets/assets/images/login.png": "2312a4310a3e38bc5f8f2806999ff1df",
"assets/assets/images/song.png": "e9e0d5d4d9f7135bfd477c1cfe119100",
"assets/FontManifest.json": "0ea9abdd987c9a26df71280858812560",
"assets/fonts/MaterialIcons-Regular.otf": "7e7a6cccddf6d7b20012a548461d5d81",
"assets/NOTICES": "4fbbb8f8c597ce66804f452778aa831b",
"canvaskit/canvaskit.js": "c2b4e5f3d7a3d82aed024e7249a78487",
"canvaskit/canvaskit.wasm": "4b83d89d9fecbea8ca46f2f760c5a9ba",
"canvaskit/profiling/canvaskit.js": "ae2949af4efc61d28a4a80fffa1db900",
"canvaskit/profiling/canvaskit.wasm": "95e736ab31147d1b2c7b25f11d4c32cd",
"favicon.png": "d9f0bfa8d2610aa0c02ab61c04f57df6",
"firebase-messaging-sw.js": "8d7ab76ed93c3126a337537c28e28c6a",
"icons/Icon-192.png": "701e43ae3eb8ad390c9b65537bc8a169",
"icons/Icon-512.png": "51cbe3b1cb0ac7ddd62f3833cba6f39a",
"icons/Icon-maskable-192.png": "701e43ae3eb8ad390c9b65537bc8a169",
"icons/Icon-maskable-512.png": "51cbe3b1cb0ac7ddd62f3833cba6f39a",
"index.html": "c9fc344a30cd9da5ff50c2c646b7197e",
"/": "c9fc344a30cd9da5ff50c2c646b7197e",
"main.dart.js": "5d9dbcdcfecb92b32fdc16407b140b03",
"manifest.json": "7051455cda8feb95c100f8203fb1431e",
"version.json": "44ffd15aadf4dba20e2e6b82e85b00e7"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "/",
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
