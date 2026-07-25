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
- **Aşama 4 ✅** Per doğrulama (`MeldValidator`: seri, grup, okeyli per
  çözümleme, 12-13-1 sarma seçeneği), çift açma değerlendirmesi
  (`PairEvaluator`), 101 açılış puan hesabı (`OpeningScoreCalculator`) ve
  bunları birleştiren `MeldEngine` (per açma, masaya taş işleme, okey
  değiştirme).
- **Aşama 4.5 ✅** Bitirme motoru (`FinishEngine`: normal/okeyle/çiftten/
  elden bitiş) ve puanlama motoru (`ScoringEngine`: açılmamış oyuncu
  çarpanı, elde kalan okey/sahte okey cezaları, bitiş türü çarpanları,
  maxHandPenalty sınırı, deste tükenmesinde berabere/en düşük-el-kazanır
  senaryoları).
- **Aşama 5 ✅** Yapay zekâ (`domain/ai`): `AiVisibleStateMapper` (AI
  yalnızca görünür bilgiyle çalışır, rakip elleri asla görmez),
  `HandMeldFinder`/`MeldCombinationSearch` (olası per adayları ve sınırlı
  kombinasyon araması), `OpeningAttemptFinder`/`HandCoverageFinder`
  (açılış ve bitirme denemeleri), `DiscardAdvisor` (zorluk ve kişiliğe
  göre ağırlıklandırılmış taş atma kararı) ve bunları birleştiren
  `AiPlayerEngine` (tam bir AI turu: çekme, açma/işleme, bitirme denemesi,
  taş atma — hepsi TurnEngine/MeldEngine/FinishEngine üzerinden, AI için
  ayrı bir "arka kapı" olmadan).
- **Aşama 6+ ⏳** Kullanıcı arayüzü, kayıt/ayarlar sonraki aşamalarda
  eklenecektir.

Oyun motoru kararlı biçimde `domain/services` (taş/dağıtım), `domain/rules`
(tur/hamle doğrulama) ve `domain/ai` (yapay zekâ) katmanlarında, UI'dan
tamamen bağımsız geliştiriliyor.
