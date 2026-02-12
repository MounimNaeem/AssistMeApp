import 'package:flutter/material.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/food/food_screen.dart';
import '../../screens/gym/gym_screen.dart';
import '../../screens/health_metrics/health_metrics_screen.dart';
import '../../screens/notification_settings/notification_settings_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/settings/update_password_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/basketball/basketball_screen.dart';

class AppRouter {
  static const String login = '/';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String food = '/food';
  static const String gym = '/gym';
  static const String settings = '/settings';
  static const String updatePassword = '/settings/password';
  
  static const String notificationSettings = '/notification-settings';

  // Placeholders
  static const String study = '/study';
  static const String calendar = '/calendar';
  static const String basketball = '/basketball';
  static const String assistant = '/assistant';
  static const String healthMetrics = '/health-metrics';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case food:
        return MaterialPageRoute(builder: (_) => const FoodScreen());
      case gym:
        return MaterialPageRoute(builder: (_) => const GymScreen());
      case AppRouter.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case updatePassword:
        return MaterialPageRoute(builder: (_) => const UpdatePasswordScreen());
      case healthMetrics:
        return MaterialPageRoute(builder: (_) => const HealthMetricsScreen());
      case notificationSettings:
        return MaterialPageRoute(
          builder: (_) => const NotificationSettingsScreen(),
        );

      case calendar:
        return MaterialPageRoute(builder: (_) => const CalendarScreen());

      case basketball:
        return MaterialPageRoute(builder: (_) => const BasketballScreen());

      // Placeholders
      case study:
      case assistant:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(settings.name ?? 'Feature')),
            body: const Center(child: Text('Coming Soon')),
          ),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
