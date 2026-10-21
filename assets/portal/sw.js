const CACHE='bellos-portal-public-v3';
self.addEventListener('install',e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(['./offline.html','./icons/app-192.png','./icons/app-512.png'])));self.skipWaiting()});
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith('bellos-portal-')&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())));
self.addEventListener('fetch',e=>{if(e.request.mode==='navigate'&&new URL(e.request.url).origin===location.origin)e.respondWith(fetch(e.request,{cache:'no-store'}).catch(()=>caches.match('./offline.html')))});
