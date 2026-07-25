{{flutter_js}}
{{flutter_build_config}}

// 101 Okey Pro tamamen offline oynanabilir olmalıdır (bkz. proje
// gereksinimleri #1). Varsayılan Flutter web bootstrap'i, CanvasKit'i
// (yerel olarak `canvaskit/` klasöründe bulunmasına rağmen) uzak bir
// CDN'den (gstatic.com) indirmeye çalışır. Burada `canvasKitBaseUrl`
// ile her zaman uygulamayla birlikte paketlenen yerel CanvasKit
// dosyalarının kullanılmasını zorluyoruz.
_flutter.loader.load({
  config: {
    canvasKitBaseUrl: "canvaskit/",
  },
});
