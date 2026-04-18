import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../../../../shared/legacy/auth_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import 'oauth_webview_page.dart';
import '../../../../shared/routes/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final TokenStorageService _tokenStorageService = TokenStorageService();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  bool _isLoadingLink = false;
  bool _isSubmittingCode = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) => _handleIncomingUri(uri),
      onError: (_) {},
    );

    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (_) {}
  }

  String? _lastHandledCode;

  void _handleIncomingUri(Uri uri) {
    final oauthError = uri.queryParameters['error'];
    if (oauthError != null && oauthError.isNotEmpty) {
      final description = uri.queryParameters['error_description'];
      if (!mounted) return;
      setState(() {
        _errorMessage =
            (description != null && description.isNotEmpty) ? description : oauthError;
      });
      return;
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) return;

    if (_isSubmittingCode || _lastHandledCode == code) return;
    _lastHandledCode = code;
    _submitCode(code);
  }

  Future<void> _requestAuthorizationUrl() async {
    setState(() {
      _isLoadingLink = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final url = await _authService.fetchAuthorizationUrl();
      if (!mounted) return;
      setState(() {
        _infoMessage = 'Havola tayyor. Kirish oynasi ochilmoqda...';
      });
      await _openAuthorizationUrl(url);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _humanizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLink = false;
        });
      }
    }
  }

  Future<void> _openAuthorizationUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) return;
      setState(() {
        _infoMessage = 'Havola noto‘g‘ri formatda.';
      });
      return;
    }

    final callbackUri = await Navigator.of(context).push<Uri>(
      MaterialPageRoute(
        builder: (_) => OAuthWebViewPage(initialUri: uri),
      ),
    );

    if (!mounted) return;
    if (callbackUri != null) {
      _handleIncomingUri(callbackUri);
    } else {
      setState(() {
        _infoMessage = 'Kirish jarayoni bekor qilindi.';
      });
    }
  }

  Future<void> _submitCode(String code) async {
    setState(() {
      _isSubmittingCode = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final response = await _authService.exchangeCode(code);

      String? accessToken;
      String? refreshToken;

      void readTokensFromMap(Map<String, dynamic> source) {
        accessToken =
            accessToken ??
            source['access'] as String? ??
            source['access_token'] as String? ??
            source['token'] as String?;
        refreshToken =
            refreshToken ??
            source['refresh'] as String? ??
            source['refresh_token'] as String?;
      }

      readTokensFromMap(response);

      final rootTokens = response['tokens'];
      if (rootTokens is Map<String, dynamic>) {
        readTokensFromMap(rootTokens);
      }

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        readTokensFromMap(data);
        final dataTokens = data['tokens'];
        if (dataTokens is Map<String, dynamic>) {
          readTokensFromMap(dataTokens);
        }
      }

      if (accessToken?.isEmpty ?? true) {
        throw Exception('Token topilmadi. Iltimos, qayta urinib ko‘ring.');
      }
      final resolvedAccessToken = accessToken!;

      await _tokenStorageService.saveTokens(
        accessToken: resolvedAccessToken,
        refreshToken: refreshToken,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.homePage);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _humanizeError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingCode = false;
        });
      }
    }
  }

  String _humanizeError(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(textTheme),
                    const SizedBox(height: 28),
                    _buildLoginCard(theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: "Uyg'un ta'lim logotipi",
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "Uyg'un ta'lim",
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLoginCard(ThemeData theme) {
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'OAuth2 orqali kirish',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Kirish havolasini oling. Brauzerda avtorizatsiyadan so‘ng ilova avtomatik qaytadi.",
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _isLoadingLink ? null : _requestAuthorizationUrl,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            icon: _isLoadingLink
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.link),
            label: Text(_isLoadingLink
                ? 'Havola olinmoqda...'
                : 'Kirish havolasini olish'),
          ),
          const SizedBox(height: 16),
          if (_infoMessage != null) ...[
            _buildMessageBanner(
              theme: theme,
              text: _infoMessage!,
              backgroundColor: const Color(0xFFF0F9FF),
              icon: Icons.info_outline,
              iconColor: const Color(0xFF0A7AC2),
              textColor: const Color(0xFF0A7AC2),
            ),
            const SizedBox(height: 12),
          ],
          if (_errorMessage != null) ...[
            _buildMessageBanner(
              theme: theme,
              text: _errorMessage!,
              backgroundColor: const Color(0xFFFFF2F2),
              icon: Icons.error_outline,
              iconColor: const Color(0xFFD14343),
              textColor: const Color(0xFFD14343),
            ),
            const SizedBox(height: 12),
          ],
          if (_isSubmittingCode)
            const Center(
              child: SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMessageBanner({
    required ThemeData theme,
    required String text,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
