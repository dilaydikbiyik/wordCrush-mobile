import 'package:go_router/go_router.dart';
import '../ui/screens/splash_screen.dart';
import '../ui/screens/login_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/difficulty_screen.dart';
import '../ui/screens/game_screen.dart';
import '../ui/screens/score_screen.dart';
import '../ui/screens/market_screen.dart';

/// Named route paths — use these constants instead of raw strings.
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/home';
  static const String difficulty = '/difficulty';
  static const String game = '/game';
  static const String score = '/score';
  static const String market = '/market';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.difficulty,
      builder: (context, state) => const DifficultyScreen(),
    ),
    GoRoute(
      path: AppRoutes.game,
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: AppRoutes.score,
      builder: (context, state) => const ScoreScreen(),
    ),
    GoRoute(
      path: AppRoutes.market,
      builder: (context, state) => const MarketScreen(),
    ),
  ],
);
