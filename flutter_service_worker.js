'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"manifest.json": "bd6da19477b0f1cf53002f78ef0de334",
"index.html": "6afd0791d60222b206baf8f4cf074eb4",
"/": "6afd0791d60222b206baf8f4cf074eb4",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "b4afba52fc2f34f9368c1a79df8d1079",
"assets/assets/images/general_medicine.png": "336fc3a8faaad1633187a1f120887780",
"assets/assets/images/family%2520medicine.jpg": "7be71223e8032f0866922f617c5da914",
"assets/assets/images/sugar.jpg": "db001505225e4d6bd0bae1a712335bd9",
"assets/assets/images/pharmacy.png": "f868e715150c8d81cbb3d2c7c3c07a9b",
"assets/assets/images/nut.jpg": "9b439c1c25182c1b91433c9621cd1c98",
"assets/assets/images/sens.jpg": "9415259e5411361c6cfa26e1d64b57c3",
"assets/assets/images/heart.png": "3c0d30f8bd58480cbdb0a7542937dd9f",
"assets/assets/images/cardiothoracic.jpg": "3267cb1aec7d6538c970635ecf4cfae4",
"assets/assets/images/neurosurgery.png": "51a2819b4c39591696e607dcf2c0810f",
"assets/assets/images/kidney.PNG": "f4c027252bed6a38d46271a78ea15830",
"assets/assets/images/saqiya.jpg": "f4584354161b482bbbe1f38318f97e3c",
"assets/assets/images/gyna,obs.jpg": "56f3a25095f2f3f76748fdffb888ff7f",
"assets/assets/images/internal_medicine.png": "1afda1c76749ec3ce5486bdd8759bb90",
"assets/assets/images/brain.png": "9211470a3fbd2880b13babe1d319966f",
"assets/assets/images/pain.jpg": "b400f057f089a9dd54327d5f604d090b",
"assets/assets/images/eye.png": "1b8e05e386f6d9756f2108e4cb207933",
"assets/assets/images/onco.jpg": "5e88296f37f187da4388bd4e795ed1ca",
"assets/assets/images/hematology.png": "e527689c4e0cb87aa72787fcea5e40d2",
"assets/assets/images/images": "d41d8cd98f00b204e9800998ecf8427e",
"assets/assets/images/andrology.jpg": "7a1a0efc696788a61f7fb4d22d19e894",
"assets/assets/images/dermatology.png": "668759b0d3976477033939ac0c732e0a",
"assets/assets/images/urology.png": "b65eb798006a5f5929a0fbb9e23e0c9b",
"assets/assets/images/tooth.png": "5170f99ad26d913c74667f10d0562b84",
"assets/assets/images/chest.png": "5acab289622f734a28e026c05d37c713",
"assets/assets/images/physiotherapy.png": "a7b9438a24d64e8b4078ff38277c580f",
"assets/assets/images/ped.jpg": "6f9a5fade10b484e3c23a4c674afc31d",
"assets/assets/images/brainped.jpg": "6722e2876401fa093a4a9964d3993e1a",
"assets/assets/images/orthopedics.png": "438df2ad65e4332a6dc8a6e65278cc81",
"assets/assets/images/vascular%2520surgey.png": "d957fbbb698a9257c5b629517e368c1a",
"assets/assets/images/radiology.png": "cee5574990049039839e8214c7b6b0cc",
"assets/assets/images/dr%2520hefny.JPG": "80ecad870c38302cfe43a97b79d1d48e",
"assets/assets/images/lab.png": "868c3a14f79d9f7068b3ef6ea091e5e2",
"assets/assets/images/oncosurg.jpg": "6ba31172c7c060f9bed20e1f51264ae9",
"assets/assets/images/bloodbank.PNG": "d696396c009d3aed92a5fad08fcadbb8",
"assets/assets/images/maxillo.jpg": "377f3bbb9b3515b8c046f1f1d56fd8dd",
"assets/assets/images/caduceus.png": "a3a0e84485641f29f2d11602fcaf5d6f",
"assets/assets/images/obese.jpg": "a28af7a49eb7867b8be861609d795c14",
"assets/assets/images/digestive.PNG": "767739fd5e6ad97c4c964c8aaf5bf6f8",
"assets/assets/images/psychat.jpg": "94f27465c2d18b80bdacac8b88b3d835",
"assets/assets/images/surgery.png": "e9459aa8595a2542e3bd3e455863b755",
"assets/assets/images/pediatrics.png": "df1e58c5b89a77e6af6a1b9827fb8b27",
"assets/assets/images/roma.jpg": "fb8f37385cb06e3798091c514e1fb278",
"assets/assets/images/plastic.png": "ea70c95503b61e9652d8e6080f371a88",
"assets/assets/icon/app_icon.png": "b4f5b88d30687264dd763d70bc061fef",
"assets/fonts/MaterialIcons-Regular.otf": "3ca8b77ed6e0b91afba250d98ae41cfd",
"assets/NOTICES": "0505717751632db4b9bf76318eae2412",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Solid-900.otf": "758f46f814d482789fd6759c5638c5af",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Brands-Regular-400.otf": "d40c67ce9f52d4bf087e61453006393c",
"assets/packages/font_awesome_flutter/lib/fonts/Font-Awesome-7-Free-Regular-400.otf": "ab1dc6447045a4d1352a27708bc47ba3",
"assets/FontManifest.json": "c75f7af11fb9919e042ad2ee704db319",
"assets/AssetManifest.bin": "9f102c66e2daece61afba8d6c63bf01e",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter_bootstrap.js": "4596898cb5f5b341d6925f8b5794d120",
"version.json": "8ba89e5b1f8385f1d4677ef511633ac7",
"main.dart.js": "2b425c029d94c8c824e1784df5f1504d"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
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
        // Claim client to enable caching on first launch
        self.clients.claim();
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
      // Claim client to enable caching on first launch
      self.clients.claim();
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
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
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
