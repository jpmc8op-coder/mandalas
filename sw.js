/* Service worker de Mandalas.
   Objetivo: que la app abra sin internet y que, aun así, una versión nueva
   llegue al usuario sin que tenga que borrar datos del navegador.

   Por eso hay DOS estrategias, no una:
   - index.html va por RED PRIMERO, con la caché como respaldo. Si sirviéramos
     el HTML desde caché, cualquier corrección quedaría enterrada hasta que el
     usuario reinstalara: toda la app vive en ese único archivo.
   - iconos y manifiesto van por CACHÉ PRIMERO. No cambian y no vale la pena
     esperar por la red.

   Al subir una versión, cambiar VERSION: eso deja obsoleta la caché anterior y
   `activate` la borra. */
const VERSION = 'mandalas-v21';
const RECURSOS = [
  './',
  './index.html',
  './manifest.json',
  './icon.svg',
  './privacidad.html',
  './icon-192.png',
  './icon-512.png',
  './apple-touch-icon.png'
];

self.addEventListener('install', e => {
  // addAll falla entero si un recurso falla; se piden de a uno para que un 404
  // en un icono no deje la app sin caché.
  e.waitUntil(
    caches.open(VERSION)
      .then(c => Promise.all(RECURSOS.map(r => c.add(r).catch(() => null))))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== VERSION).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);
  if (url.origin !== location.origin) return;      // nada externo que cachear

  const esDocumento = req.mode === 'navigate' || url.pathname.endsWith('.html');

  if (esDocumento){
    e.respondWith(
      fetch(req)
        .then(res => {
          const copia = res.clone();
          caches.open(VERSION).then(c => c.put(req, copia));
          return res;
        })
        .catch(() => caches.match(req).then(r => r || caches.match('./index.html')))
    );
    return;
  }

  e.respondWith(
    caches.match(req).then(r => r || fetch(req).then(res => {
      const copia = res.clone();
      caches.open(VERSION).then(c => c.put(req, copia));
      return res;
    }).catch(() => r))
  );
});
