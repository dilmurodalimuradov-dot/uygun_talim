import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
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
  };

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        final s = AppStrings.of(context);
        return Scaffold(
          appBar: AppBar(title: Text(s.routeNotFound)),
          body: Center(child: Text('${s.routeNotFoundMsg}: ${settings.name}')),
        );
      },
    );
  }
}