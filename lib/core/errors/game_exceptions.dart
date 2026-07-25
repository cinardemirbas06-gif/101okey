/// Oyun kurallar motorunun fırlattığı tüm hataların ortak tabanı.
///
/// UI katmanı bu hataları yakalayıp [userMessage] alanını kullanıcıya
/// gösterir; [debugDetail] yalnızca geliştirici loglarında kullanılır.
sealed class GameException implements Exception {
  const GameException(this.userMessage, {this.debugDetail});

  final String userMessage;
  final String? debugDetail;

  @override
  String toString() => 'GameException: $userMessage'
      '${debugDetail != null ? ' ($debugDetail)' : ''}';
}

/// Sırası olmayan bir oyuncu hamle yapmaya çalıştı.
final class NotPlayersTurnException extends GameException {
  const NotPlayersTurnException({String? debugDetail})
      : super('Şu anda sizin sıranız değil.', debugDetail: debugDetail);
}

/// Hamle, oyunun mevcut aşamasında geçerli değil.
final class InvalidGamePhaseException extends GameException {
  const InvalidGamePhaseException({String? debugDetail})
      : super('Bu işlem şu anda yapılamaz.', debugDetail: debugDetail);
}

/// Oyuncu elinde olmayan bir taşı oynamaya çalıştı.
final class TileNotInHandException extends GameException {
  const TileNotInHandException({String? debugDetail})
      : super('Bu taş elinizde bulunmuyor.', debugDetail: debugDetail);
}

/// Bir per (seri/grup) kural dışı.
final class InvalidMeldException extends GameException {
  const InvalidMeldException(super.userMessage, {super.debugDetail});
}

/// Oyuncu henüz açılmadan başka bir işlemi yapmaya çalıştı.
final class PlayerNotOpenedException extends GameException {
  const PlayerNotOpenedException({String? debugDetail})
      : super('Önce elinizi açmalısınız.', debugDetail: debugDetail);
}

/// Açılış toplamı gerekli eşiğin altında kaldı.
final class InsufficientOpeningScoreException extends GameException {
  const InsufficientOpeningScoreException({
    required this.currentScore,
    required this.requiredScore,
  }) : super(
          'Perlerinizin toplamı $currentScore. Açmak için '
          '${requiredScore - currentScore} puan daha gerekiyor.',
        );

  final int currentScore;
  final int requiredScore;
}

/// Çiftten açılış denemesinde gerekli çift sayısına ulaşılamadı.
final class InsufficientPairCountException extends GameException {
  const InsufficientPairCountException({
    required this.currentPairCount,
    required this.requiredPairCount,
  }) : super(
          'Şu an $currentPairCount çift var. Çiftten açmak için '
          '$requiredPairCount çift gerekiyor.',
        );

  final int currentPairCount;
  final int requiredPairCount;
}

/// Aynı fiziksel taş iki farklı perde kullanılmaya çalışıldı.
final class TileAlreadyUsedException extends GameException {
  const TileAlreadyUsedException({String? debugDetail})
      : super('Bu taş zaten başka bir perde kullanılıyor.',
            debugDetail: debugDetail);
}

/// Genel amaçlı geçersiz hamle hatası (spesifik alt tür yoksa kullanılır).
final class InvalidActionException extends GameException {
  const InvalidActionException(super.userMessage, {super.debugDetail});
}

/// Geçersiz bir bitiş denemesi yapıldı.
final class InvalidFinishException extends GameException {
  const InvalidFinishException(super.userMessage, {super.debugDetail});
}

/// Kayıtlı oyun verisi okunamadı veya bozulmuş.
final class SaveDataCorruptedException extends GameException {
  const SaveDataCorruptedException({String? debugDetail})
      : super('Kayıtlı oyun okunamadı, yeni bir oyun başlatılabilir.',
            debugDetail: debugDetail);
}

/// Kayıt şeması sürümü uygulama ile uyumsuz ve migrate edilemedi.
final class SaveVersionMismatchException extends GameException {
  const SaveVersionMismatchException({required this.savedVersion, required this.expectedVersion})
      : super('Kayıtlı oyun sürümü uyumsuz, yeni bir oyun başlatılabilir.',
            debugDetail: 'saved=$savedVersion expected=$expectedVersion');

  final int savedVersion;
  final int expectedVersion;
}

/// Yapay zekâ motoru güvenli bir hamle üretemedi (beklenmeyen durum).
final class AiDecisionFailedException extends GameException {
  const AiDecisionFailedException({String? debugDetail})
      : super('Yapay zekâ hamlesi oluşturulamadı.', debugDetail: debugDetail);
}
