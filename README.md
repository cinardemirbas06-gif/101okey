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

- **Aşama 1-2 ✅** Mimari, klasör yapısı, temel domain modelleri (taş,
  oyuncu, per, oyun kuralları, oyun state'i, oyun hareketleri, skor
  modelleri).
- **Aşama 3 ✅** Taş üretimi (106 taş), karıştırma, gösterge/okey
  belirleme, kurallara uygun dağıtım (`GameSetupService`) ve tur akışı
  motoru (`TurnEngine`: taş çekme, ortadan alma, taş atma, ıstaka
  yeniden sıralama, deste tükenme politikaları).
- **Aşama 4+ ⏳** Per doğrulama (seri/grup/okeyli per, 101 açılış, çift
  açma), masaya taş işleme, yapay zekâ, kullanıcı arayüzü, kayıt/ayarlar
  sonraki aşamalarda eklenecektir.

Oyun motoru kararlı biçimde `domain/services` (taş/dağıtım) ve
`domain/rules` (tur/hamle doğrulama) katmanlarında, UI'dan tamamen
bağımsız geliştiriliyor.
