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
- **Aşama 6 ✅** Kullanıcı arayüzü: ana menü, kurallar ekranı, oyun
  kurulum ekranı (oyuncu adı, AI zorluğu, ev kuralı profili), tam
  fonksiyonel oyun masası (`GameTableScreen`: rakip panelleri, ortadaki
  alan, masaya açılmış perler, iki sıralı ıstaka) ve el sonucu ekranı.
  Taş taşıma/per açma/masaya işleme/okey değiştirme/taş atma
  **gerçek sürükle-bırak** (Flutter `Draggable`/`DragTarget`) ile
  çalışır; per açmak için birden çok taş grubu "hazırlama tepsisinde"
  toplanıp tek seferde gönderilir. `GameController` (Riverpod
  `StateNotifier`), tüm hamleleri her zaman
  `TurnEngine`/`MeldEngine`/`FinishEngine` üzerinden işler ve sıra AI'ya
  geldiğinde `AiPlayerEngine`'i otomatik olarak (gerçekçi bir "düşünme"
  gecikmesiyle) sırayla çalıştırır.
- **Aşama 7 ✅** Kalıcılık ve oyuncu deneyimi: Hive tabanlı
  `HiveStorageService` üzerine kurulu `GameSaveRepository` (şema sürümü
  kontrolü ve bozuk veri durumunda güvenli temizleme ile), her hamleden
  sonra otomatik kayıt ve ana menüde "Devam Et" ile kaldığı yerden devam
  etme; gerçekten bağlı `AppSettings`/`SettingsRepository`/
  `SettingsController` (dokunsal geri bildirim, animasyon hızı, geçerli
  bırakma alanı vurgusu, el sıralama modu, sıra süresi/otomatik zaman
  aşımı, büyük metin modu — hepsi gerçekten UI davranışını değiştirir);
  `PlayerStatistics` ile el/galibiyet/bitiş türü/açılış puanı/galibiyet
  serisi takibi; `AchievementEvaluator` ve 10 başarımlık katalog (ilk
  galibiyet, yüksek açılış, bitiş türleri, galibiyet serileri, Uzman
  AI'ı yenme, okeysiz kazanma, masaya 10 taş işleme); sıra süresi
  dolduğunda `DiscardAdvisor` kullanılarak otomatik çekme/atma; ve
  `TurnEngine.rearrangeHand` üzerinden gerçek "Sırala" özelliği.
- **Aşama 8 ✅** Test kapsamı genişletme, performans ve görsel cila:
  önceden test edilmeyen ekranlar (Ayarlar, İstatistikler, Başarımlar,
  Kurallar, El Sonucu) için widget testleri; motor katmanlarını
  (`GameSetupService` → `AiPlayerEngine` → `TurnEngine`/`MeldEngine`/
  `FinishEngine` → `ScoringEngine`) uçtan uca zincirleyen bir
  entegrasyon testi. Bu test yazılırken gerçek bir dayanıklılık açığı
  bulundu ve düzeltildi: `TurnEngine`'e `GameConstants.maxTurnsPerHand`
  güvenlik ağı eklendi — çekme destesi küçük olduğundan (~20 taş),
  oyuncular kapalı desteden hiç çekmeyip sürekli ortadaki açık taşı
  alırsa el, deste hiç tükenmeden teorik olarak sonsuza kadar sürebiliyordu;
  artık böyle bir durumda el, deste tükenmesindeki gibi sonuçsuz
  sayılarak güvenle sonlandırılıyor. Performans: `GameTableScreen`'deki
  saniyelik tur sayacı, tüm oyun masasını (ıstaka, masaya açılmış
  perler, sürükle-bırak hedefleri) her saniye yeniden çizdiren tek bir
  `Timer`'dan, yalnızca kendi küçük metnini yeniden çizen ayrı bir
  `_TurnCountdown` alt widget'ına taşındı. Görsel cila: merkezi
  `AppTheme` (tutarlı buton/kart/başlık/diyalog stilleri, yumuşak sayfa
  geçişleri), el sonucu ekranında kazanan için yaylanan kupa animasyonu
  ve puan kartları için kademeli (staggered) giriş animasyonu —
  tamamı "Animasyonlar" ayarı kapatıldığında anında (animasyonsuz)
  gösterime döner.

Planlanan 8 aşamanın tamamı tamamlandı. Oyun motoru kararlı biçimde
`domain/services` (taş/dağıtım), `domain/rules` (tur/hamle doğrulama) ve
`domain/ai` (yapay zekâ) katmanlarında, UI'dan tamamen bağımsız
geliştirildi; UI yalnızca `features/*/presentation` katmanında yaşar.

### Aşama 6 kapsam notları (bilinçli basitleştirmeler)

- **Ses efektleri eklenmedi**: `assets/audio/` klasörleri şu an boş;
  var olmayan ses dosyalarına referans veren "sahte" bir ses özelliği
  eklemek yerine, gerçek ses varlıkları sağlandığında eklenmesi daha
  doğru olacağından bu özellik ertelendi.
- **Taşlar ve avatarlar görsel varlık (PNG) kullanmaz**: gerçek taş
  görselleri yerine, tamamen widget kompozisyonuyla (renk/gölge/yuvarlak
  köşe) çizilen taşlar kullanılır; avatarlar için oyuncunun baş harfini
  gösteren dairesel bir simge kullanılır. Bu, var olmayan asset
  dosyalarına referans verip çalışma zamanında sessizce bozulan bir
  arayüz oluşturmamak için bilinçli bir tercihtir.
- **Çiftten açılış/bitiş için sürükle-bırak arayüzü henüz yok**: motor
  (Aşama 4) bunu tam destekler, ancak UI şu an yalnızca seri/grup
  tabanlı açılış ve normal/okeyle/elden bitişi kolayca destekliyor.

### Aşama 7 kapsam notları (bilinçli basitleştirmeler)

- **Ses seviyesi/tercih ayarları eklenmedi**: Aşama 6 notunda belirtildiği
  gibi henüz bir ses motoru/varlığı olmadığından, ayarlar ekranına var
  olmayan bir özelliği kontrol eden sahte bir ses düğmesi eklenmedi.
- **Bulut senkronizasyonu yok**: kayıt/istatistik/başarım verileri yalnızca
  cihaz üzerindeki Hive kutularında tutulur; bu, "tamamen offline
  oynanabilir" hedefiyle tutarlı bilinçli bir tercihtir.
- **Kayıt sistemi tek bir aktif oyunu destekler**: birden fazla kayıt
  yuvası (slot) yerine tek bir "devam eden oyun" kaydı tutulur, çünkü
  oyun kuralları tek seferde tek bir masa oturumunu varsayar.

### Aşama 8 kapsam notları (bilinçli basitleştirmeler)

- **Özel font (Google Fonts vb.) eklenmedi**: uygulamanın çevrimdışı
  çalışma hedefiyle çelişmemesi için (bazı font paketleri ilk açılışta
  ağdan dosya indirmeye çalışır) tipografi, Flutter'ın Material 3
  metin teması üzerinden (ağırlık/aralık ayarlarıyla) iyileştirildi;
  gerçekten yerleşik (bundled) bir font dosyası eklenmedi.
- **Sayfa geçiş animasyonları, "Animasyonlar" ayarına bağlı değil**:
  bu ayar bilinçli olarak yalnızca oyun masası içi geri bildirimleri
  (taş/per animasyonları, sürükleme vurguları) ve el sonucu ekranındaki
  kutlama animasyonlarını kapsar; ekranlar arası geçişler ayrı bir
  kaygı olarak görülüp her zaman açık bırakıldı.
