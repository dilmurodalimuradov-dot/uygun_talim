import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/connection_status_provider.dart';
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
    // Avval ConnectionStatusProvider'ning boshlang'ich tarmoq/server
    // tekshiruvi tugashini kutamiz. Agar shu paytda internet yo'qligi
    // yoki server bilan bog'lanishda xatolik aniqlansa, `ConnectionGate`
    // (main.dart) avtomatik ravishda to'liq ekranli xatolik sahifasini
    // ko'rsatadi va u tuzalmaguncha turadi — splash esa orqa fonda kutib
    // turaveradi, hech qaysi sahifaga noto'g'ri o'tib ketmaydi.
    final connectionStatus = context.read<ConnectionStatusProvider>();
    while (!connectionStatus.initialCheckDone) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    // Muammo hal bo'lishini kutamiz (agar bor bo'lsa) — ConnectionGate
    // buni foydalanuvchiga ko'rsatib turadi, biz esa shu yerda kutamiz.
    while (connectionStatus.hasIssue) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
    }

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