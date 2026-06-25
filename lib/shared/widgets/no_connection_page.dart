import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/providers/connection_status_provider.dart';
import '../theme/app_colors.dart';

/// Internet yo'qligi yoki serverga ulanib bo'lmasligi sodir bo'lganda
/// butun ilova ustiga chiqariladigan to'liq ekranli sahifa.
///
/// `ConnectionStatusProvider.issue` qiymati `ConnectionIssue.none`ga
/// qaytguncha shu ekran ko'rinib turadi — ya'ni internet/server tuzalmaguncha
/// foydalanuvchi asosiy ilova bilan ishlay olmaydi. Tuzalgan zahoti
/// ekran avtomatik yopiladi va foydalanuvchi to'xtagan joyiga qaytadi.
///
/// Bu widget `ConnectionGate` orqali avtomatik chaqiriladi, lekin
/// xohlasangiz to'g'ridan-to'g'ri ham ishlatish mumkin.
class NoConnectionPage extends StatefulWidget {
  const NoConnectionPage({super.key});

  @override
  State<NoConnectionPage> createState() => _NoConnectionPageState();
}

class _NoConnectionPageState extends State<NoConnectionPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onRetry(ConnectionStatusProvider status) async {
    if (_isRetrying) return;
    HapticFeedback.mediumImpact();
    setState(() => _isRetrying = true);
    await status.checkServerReachable();
    if (mounted) {
      setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final status = context.watch<ConnectionStatusProvider>();
    final isServerIssue = status.issue == ConnectionIssue.serverError;

    final title = isServerIssue ? s.serverErrorTitle : s.noInternetTitle;
    final message = isServerIssue ? s.serverErrorMessage : s.noInternetMessage;
    final icon = isServerIssue
        ? Icons.dns_rounded
        : Icons.wifi_off_rounded;

    return PopScope(
      // Foydalanuvchi orqaga tugmasi bilan bu ekrandan chiqib ketolmaydi —
      // muammo hal bo'lmaguncha shu sahifada qoladi.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPulsingIcon(icon),
                  const SizedBox(height: 36),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _buildRetryButton(s, status),
                  const SizedBox(height: 16),
                  _buildStatusHint(s, status),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingIcon(IconData icon) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.08);
        final opacity = 0.10 + (_pulseController.value * 0.08);
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: scale,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withOpacity(opacity),
                ),
              ),
            ),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.strokeLight, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textDark.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 42, color: AppColors.error),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRetryButton(AppStrings s, ConnectionStatusProvider status) {
    final busy = _isRetrying || status.isChecking;
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: busy ? null : () => _onRetry(status),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                busy ? s.connectionChecking : s.connectionRetryButton,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHint(AppStrings s, ConnectionStatusProvider status) {
    if (!status.isChecking && !_isRetrying) return const SizedBox.shrink();
    return Text(
      s.connectionChecking,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textMuted,
      ),
    );
  }
}
