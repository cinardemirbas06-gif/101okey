# 101 Okey Pro

Tamamen offline oynanabilir, 4 kişilik (1 gerçek + 3 yapay zekâ) masa için
geliştirilen profesyonel kalitede bir 101 Okey oyunu.

Proje, Clean Architecture ilkeleriyle feature-first bir klasör yapısında,
oyun motoru UI'dan tamamen bağımsız olacak şekilde geliştiriliyor. Detaylı
mimari kararlar, geliştirme yol haritası ve aşama planı proje geliştirme
sürecinde paylaşılmıştır.

## Geliştirme ortamı

- Flutter 3.44+ (stable channel), Dart 3.12+
- Bu proje `freezed`, `json_serializable` ve `riverpod_generator` ile kod
  üretimi kullanır.

### Kurulum

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

> `**/*.freezed.dart` ve `**/*.g.dart` dosyaları depoya eklenmez
> (`.gitignore`). Projeyi klonladıktan veya model dosyalarını
> değiştirdikten sonra yukarıdaki `build_runner` komutunu çalıştırmanız
> gerekir.

### Çalıştırma

```bash
flutter run
```

### Analiz ve testler

```bash
flutter analyze
flutter test
```

## Proje durumu

Şu anda **Aşama 2: Temel domain modelleri** tamamlandı (taş, oyuncu, per,
oyun kuralları, oyun state'i, oyun hareketleri, skor modelleri). Oyun
motoru, kural doğrulama, yapay zekâ ve kullanıcı arayüzü sonraki
aşamalarda eklenecektir.
