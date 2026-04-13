import 'package:flutter/material.dart';
import 'package:pr/ui/pages/home_page.dart';
import 'package:pr/ui/pages/login_screen.dart';
import 'package:pr/ui/pages/profil.dart';
import 'package:pr/ui/pages/splash_screen.dart';
import 'package:pr/ui/routes/app_routes.dart';

class AppNavigator {
  static String initRoute = AppRoutes.splashScreen;

  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.splashScreen: (_) => const SplashScreen(),
      // AppRoutes.startScreen: (_) => const StartScreen(),
      AppRoutes.loginPage: (_) => const LoginPage(),
      AppRoutes.homePage: (_) => HomePage(),
      AppRoutes.profilePage: (_) => ProfilePage(),
      AppRoutes.myApplications: (_) => MyApplicationsPage(),
    };
  }
}
