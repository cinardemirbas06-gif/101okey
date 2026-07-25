import 'package:okey_101_pro/features/game/domain/entities/player.dart';

/// Testlerde tekrar tekrar kurulmaması için standart 4 kişilik masa.
List<Player> buildTestPlayers() => const [
  Player(id: 'p1', name: 'Çınar', avatarId: 'avatar_1'),
  Player(id: 'p2', name: 'AI Ayşe', avatarId: 'avatar_2', isAI: true),
  Player(id: 'p3', name: 'AI Mehmet', avatarId: 'avatar_3', isAI: true),
  Player(id: 'p4', name: 'AI Zeynep', avatarId: 'avatar_4', isAI: true),
];
