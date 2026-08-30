/* Only Money - Service Worker
   Minimal: install/activate 즉시 통과. 외부 API(Anthropic, RSS 프록시 등)는 캐싱하지 않음.
   shell 파일만 stale-while-revalidate 패턴으로 캐시.
   PWA "설치 가능" 자격을 만들고, file:// 가 아닌 환경에서 오프라인 부팅 지원.
*/
const CACHE = 'onlymoney-v1.1.0';
const SHELL = [
  './',
  './index.html',
  './icon.svg',
  './manifest.json'
];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).catch(() => {}));
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);
  // Same-origin shell만 캐시 사용. 외부(API/RSS/TradingView)는 모두 네트워크 직행.
  if(url.origin !== self.location.origin){ return; }
  e.respondWith(
    caches.match(e.request).then(cached => {
      const network = fetch(e.request).then(res => {
        if(res && res.status === 200){
          const clone = res.clone();
          caches.open(CACHE).then(c => c.put(e.request, clone)).catch(() => {});
        }
        return res;
      }).catch(() => cached);
      return cached || network;
    })
  );
});
