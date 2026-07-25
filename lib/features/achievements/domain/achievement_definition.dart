/// Uygulamadaki tüm başarımların kimliği.
enum AchievementId {
  firstWin,
  highOpening150,
  okeyFinish,
  pairFinish,
  handFinish,
  winStreak3,
  winStreak10,
  beatExpertAi,
  noJokerWin,
  tenTilesToTable,
}

/// Bir başarımın statik (değişmeyen) tanımı: başlık ve açıklama.
final class AchievementDefinition {
  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
  });

  final AchievementId id;
  final String title;
  final String description;
}

/// Tüm başarımların tam kataloğu.
abstract final class AchievementCatalog {
  const AchievementCatalog._();

  static const List<AchievementDefinition> all = [
    AchievementDefinition(
      id: AchievementId.firstWin,
      title: 'İlk Galibiyet',
      description: 'İlk elini kazan.',
    ),
    AchievementDefinition(
      id: AchievementId.highOpening150,
      title: '150 Üzeri Açılış',
      description: 'Açılışta 150 veya üzeri puanla aç.',
    ),
    AchievementDefinition(
      id: AchievementId.okeyFinish,
      title: 'Okeyle Bitir',
      description: 'Bir eli okey atarak bitir.',
    ),
    AchievementDefinition(
      id: AchievementId.pairFinish,
      title: 'Çiftten Bitir',
      description: 'Bir eli çiftten bitir.',
    ),
    AchievementDefinition(
      id: AchievementId.handFinish,
      title: 'Elden Bitir',
      description: 'Bir eli hiç açmadan, elden bitir.',
    ),
    AchievementDefinition(
      id: AchievementId.winStreak3,
      title: 'Arka Arkaya 3 Galibiyet',
      description: 'Art arda 3 el kazan.',
    ),
    AchievementDefinition(
      id: AchievementId.winStreak10,
      title: 'Arka Arkaya 10 Galibiyet',
      description: 'Art arda 10 el kazan.',
    ),
    AchievementDefinition(
      id: AchievementId.beatExpertAi,
      title: 'Uzman AI\'ı Yen',
      description: 'Masada Uzman zorluğunda bir AI varken eli kazan.',
    ),
    AchievementDefinition(
      id: AchievementId.noJokerWin,
      title: 'Tek Elde Hiç Okey Kullanmadan Kazan',
      description: 'Perlerinde hiç okey/sahte okey kullanmadan bir el kazan.',
    ),
    AchievementDefinition(
      id: AchievementId.tenTilesToTable,
      title: 'Masaya 10 Taş İşle',
      description: 'Tek bir elde masadaki perlere 10 taş işle.',
    ),
  ];
}
