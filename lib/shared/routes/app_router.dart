import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static const String initialRoute = AppRoutes.splashScreen;

  static Map<String, WidgetBuilder> get routes => {
        AppRoutes.splashScreen: (_) => const SplashScreen(),
        AppRoutes.loginPage: (_) => const LoginPage(),
        AppRoutes.homePage: (_) => const HomePage(),
        AppRoutes.profilePage: (_) => const ProfilePage(),
        AppRoutes.myApplications: (_) => const MyApplicationsPage(),
      };

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Topilmadi')),
        body: Center(child: Text('Route topilmadi: ${settings.name}')),
      ),
    );
  }
}
