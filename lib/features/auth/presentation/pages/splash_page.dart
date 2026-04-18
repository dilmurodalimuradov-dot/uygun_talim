import 'package:flutter/material.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../../shared/routes/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TokenStorageService _tokenStorageService = TokenStorageService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _tokenStorageService.readAccessToken();
    if (!mounted) return;
    final targetRoute =
        (token != null && token.isNotEmpty) ? AppRoutes.homePage : AppRoutes.loginPage;
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: _buildLogo()),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo2.png',
      width: 300,
      height: 300,
      fit: BoxFit.contain,
    );
  }
}