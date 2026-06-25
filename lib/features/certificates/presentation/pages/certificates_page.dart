import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../shared/legacy/certificate_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../../shared/theme/app_colors.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF57A57C),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        leading: Navigator.of(context).canPop()
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        )
            : null,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.certsTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              s.certsSubtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF57A57C), Color(0xFF3D8B67)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: const _CertificatesList(),
    );
  }
}

class _CertificatesList extends StatefulWidget {
  const _CertificatesList();

  @override
  State<_CertificatesList> createState() => _CertificatesListState();
}

class _CertificatesListState extends State<_CertificatesList> {
  static const _prefsKey = 'downloaded_certificate_paths';

  final _service = CertificateService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = false;
  String? _error;
  List<Certificate> _items = [];

  String? _downloadingId;
  final Map<String, double> _progress = {};
  final Map<String, String> _downloadedPaths = {};

  @override
  void initState() {
    super.initState();
    _restoreDownloads();
    _load();
  }

  Future<void> _restoreDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = prefs.getStringList(_prefsKey) ?? const [];
    final restored = <String, String>{};
    for (final e in entries) {
      final i = e.indexOf('|');
      if (i <= 0) continue;
      final id = e.substring(0, i);
      final path = e.substring(i + 1);
      if (await File(path).exists()) {
        restored[id] = path;
      }
    }
    if (mounted) setState(() => _downloadedPaths.addAll(restored));
  }

  Future<void> _persistDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final entries =
    _downloadedPaths.entries.map((e) => '${e.key}|${e.value}').toList();
    await prefs.setStringList(_prefsKey, entries);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        final s = AppStrings.forCode('uz');
        throw Exception(s.certsTokenNotFound);
      }
      final items = await _service.fetchCertificates(token);
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadCertificate(Certificate cert) async {
    final s = AppStrings.read(context);
    if (cert.fileUrl.isEmpty) {
      _snack(s.certsNoFile, Colors.orange);
      return;
    }

    setState(() {
      _downloadingId = cert.id;
      _progress[cert.id] = 0;
    });

    try {
      final url = UrlHelper.normalizeMediaUrl(cert.fileUrl);
      final token = await _tokenStorage.readAccessToken();
      final fileName = _generateFileName(cert);

      final dir = await getApplicationDocumentsDirectory();
      final certDir = Directory('${dir.path}/Sertifikatlar');
      if (!await certDir.exists()) {
        await certDir.create(recursive: true);
      }
      final filePath = '${certDir.path}/$fileName';

      final request = http.Request('GET', Uri.parse(url));
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.Client().send(request);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = File(filePath).openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0 && mounted) {
          setState(() => _progress[cert.id] = (received / total) * 100);
        }
      }
      await sink.close();

      if (!mounted) return;
      setState(() {
        _downloadingId = null;
        _progress.remove(cert.id);
        _downloadedPaths[cert.id] = filePath;
      });
      await _persistDownloads();
      _showSuccessSheet(fileName, filePath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadingId = null;
        _progress.remove(cert.id);
      });
      final msg = e.toString().replaceFirst('Exception: ', '');
      _snack('${s.certsDownload}: $msg', Colors.red);
    }
  }

  Future<void> _openFile(String filePath) async {
    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done && mounted) {
      _snack(result.message, Colors.orange);
    }
  }

  void _showSuccessSheet(String fileName, String filePath) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F7EE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sertifikat yuklab olindi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fileName,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openFile(filePath);
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text(
                    'Faylni ochish',
                    style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Yopish',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generateFileName(Certificate cert) {
    var base = cert.title.isNotEmpty ? cert.title : 'sertifikat';
    base = base.replaceAll(RegExp(r'[^\w\sЀ-ӿ]'), '');
    base = base.replaceAll(' ', '_');

    final lower = cert.fileUrl.toLowerCase();
    String ext;
    if (lower.endsWith('.pdf')) {
      ext = '.pdf';
    } else if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      ext = '.jpg';
    } else if (lower.endsWith('.png')) {
      ext = '.png';
    } else {
      final dot = cert.fileUrl.lastIndexOf('.');
      ext = (dot != -1 && dot < cert.fileUrl.length - 1)
          ? cert.fileUrl.substring(dot)
          : '.pdf';
    }
    return '$base$ext';
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    if (_isLoading && _items.isEmpty) return _buildLoading(s);
    if (_error != null && _items.isEmpty) return _buildError(s);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _items.isEmpty
          ? _buildEmpty(s)
          : ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _buildHowToCard(),
          const SizedBox(height: 14),
          ..._items.map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildCertificateCard(c, s),
          )),
        ],
      ),
    );
  }

  Widget _buildHowToCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sertifikatni telefonga saqlash uchun pastdagi '
                  '"Yuklab olish" tugmasini bosing. Yuklab olingach, '
                  '"Faylni ochish" tugmasi bilan ko\'rishingiz mumkin.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(Certificate cert, AppStrings s) {
    final isLoading = _downloadingId == cert.id;
    final progress = _progress[cert.id] ?? 0;
    final downloadedPath = _downloadedPaths[cert.id];
    final isDownloaded = downloadedPath != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.title.isNotEmpty ? cert.title : s.certsTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cert.issuedAt.isNotEmpty
                                ? cert.issuedAt
                                : s.certsUnknownDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (isLoading) ...[
              LinearProgressIndicator(
                value: progress > 0 ? progress / 100 : null,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text(
                progress > 0
                    ? 'Yuklab olinmoqda... ${progress.toInt()}%'
                    : 'Yuklab olinmoqda...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else if (isDownloaded) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openFile(downloadedPath),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: const Text(
                        'Faylni ochish',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _downloadCertificate(cert),
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Qayta yuklab olish',
                    style: IconButton.styleFrom(
                      backgroundColor:
                      AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadCertificate(cert),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text(
                    'Yuklab olish',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(AppStrings s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.certsLoading,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppStrings s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(s.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AppStrings s) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    s.certsNotFound,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.certsNotFoundSub,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}