# Roboto yazı tipi

Bu klasördeki `.ttf` dosyaları Google'ın **Roboto** yazı tipi ailesine
aittir ve **Apache License, Version 2.0** ile lisanslanmıştır
(https://github.com/googlefonts/roboto).

## Neden burada paketleniyor?

Flutter Web, uygulamaya bir font paketlenmediğinde varsayılan "Roboto"
yazı tipini çalışma zamanında `fonts.gstatic.com` üzerinden internetten
indirmeye çalışır. Bu, projenin "tamamen offline oynanabilir" temel
gereksinimiyle doğrudan çelişir: internet bağlantısı olmadan (veya bu
CDN'e erişim engellendiğinde) uygulama hiçbir metin/arayüz
gösteremeden **boş bir sayfa** olarak kalır. Roboto'yu burada gerçek
bir varlık (asset) olarak paketleyip `pubspec.yaml` içinde
tanımlayarak bu uzak bağımlılık tamamen ortadan kaldırılır.
