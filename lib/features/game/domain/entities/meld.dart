import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/meld_type.dart';
import 'meld_tile.dart';

part 'meld.freezed.dart';
part 'meld.g.dart';

/// Masaya açılmış (veya bir oyuncunun kendi açılışında tuttuğu) geçerli
/// taş kombinasyonu: seri, grup veya çift.
///
/// Per doğrulama mantığı bu sınıfta bulunmaz; `MeldValidatorService`
/// (rules engine) tarafından üretilir/doğrulanır. [Meld] yalnızca
/// doğrulanmış bir sonucu taşıyan bir veri yapısıdır.
@freezed
class Meld with _$Meld {
  const Meld._();

  const factory Meld({
    required String id,
    required MeldType type,

    /// Bu peri ilk açan oyuncunun kimliği (istatistik ve UI göstergeleri
    /// için); masaya açıldıktan sonra tüm açılmış oyuncular tarafından
    /// düzenlenebilir.
    required String openedByPlayerId,
    required List<MeldTile> tiles,

    /// Ev kuralına göre perin yeniden düzenlenmesi/bölünmesi kilitlenmiş mi.
    @Default(false) bool isLocked,
  }) = _Meld;

  factory Meld.fromJson(Map<String, dynamic> json) => _$MeldFromJson(json);

  int get tileCount => tiles.length;
}

/// Masadaki bir peri tanımlamak için kullanılan takma ad; AI ve UI
/// katmanlarında "rakiplere açık, herkesin görebildiği per" anlamını
/// vurgulamak için tercih edilir.
typedef OpenMeld = Meld;
