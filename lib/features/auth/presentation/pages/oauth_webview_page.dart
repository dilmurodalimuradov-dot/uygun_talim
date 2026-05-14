import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '/core/l10n/app_strings.dart';

class OAuthWebViewPage extends StatefulWidget {
  const OAuthWebViewPage({super.key, required this.initialUri});

  final Uri initialUri;

  @override
  State<OAuthWebViewPage> createState() => _OAuthWebViewPageState();
}

class _OAuthWebViewPageState extends State<OAuthWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri != null && _isRedirectUri(uri)) {
              Navigator.of(context).pop(uri);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _isLoading = false;
              _errorMessage = AppStrings.of(context).webviewPageError;
            });
          },
        ),
      )
      ..loadRequest(widget.initialUri);
  }

  bool _isRedirectUri(Uri uri) {
    final path = uri.path.toLowerCase();
    final isRedirectPath =
        path == '/redirect' ||
            path == '/rederict' ||
            path.startsWith('/redirect/');

    if (uri.scheme == 'uyguntalim' && uri.host == 'redirect') {
      return true;
    }

    if (uri.scheme == 'com.uyguntalim' &&
        (uri.host == 'redirect' || isRedirectPath)) {
      return true;
    }

    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host == 'com.uyguntalim' &&
        isRedirectPath) {
      return true;
    }

    return uri.scheme == 'https' &&
        uri.host == 'uyguntalim.tsue.uz' &&
        uri.path.startsWith('/redirect');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.webviewTitle),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          if (_errorMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFD14343)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}