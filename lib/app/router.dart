import 'package:go_router/go_router.dart';

import '../features/achievements/presentation/achievements_screen.dart';
import '../features/game/presentation/screens/game_setup_screen.dart';
import '../features/game/presentation/screens/game_table_screen.dart';
import '../features/game/presentation/screens/hand_result_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/rules_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/rules',
      builder: (context, state) => const RulesScreen(),
    ),
    GoRoute(
      path: '/setup',
      builder: (context, state) => const GameSetupScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameTableScreen(),
    ),
    GoRoute(
      path: '/result',
      builder: (context, state) => const HandResultScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (context, state) => const AchievementsScreen(),
    ),
  ],
);
