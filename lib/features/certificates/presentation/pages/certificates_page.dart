import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/utils/url_helper.dart';
import '../../../../shared/legacy/certificate_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../../shared/theme/app_colors.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Sertifikatlar',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
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
  final _service = CertificateService();
  final _tokenStorage = TokenStorageService();

  bool _isLoading = false;
  String? _error;
  List<Certificate> _items = [];

  String? _downloadingId;
  Map<String, double> _downloadProgress = {};
  String? _lastDownloadedPath;

  @override
  void initState() {
    super.initState();
    _load();
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
        throw Exception('Token topilmadi. Qayta kiring.');
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

  String _getCorrectUrl(String url) => UrlHelper.normalizeMediaUrl(url);

  Future<void> _openFolder(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        // Agar faylni ochib bo'lmasa, papkani ochishga harakat qilamiz
        final directory = filePath.substring(0, filePath.lastIndexOf('/'));
        await OpenFilex.open(directory);
      }
    } catch (e) {
      debugPrint('Papka ochishda xatolik: $e');
      _snack('Papkani ochib bo\'lmadi', Colors.orange);
    }
  }

  Future<void> _downloadCertificate(Certificate cert) async {
    if (cert.fileUrl.isEmpty) {
      _snack('Fayl manzili mavjud emas', Colors.orange);
      return;
    }

    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      _showPermissionDialog();
      return;
    }

    setState(() {
      _downloadingId = cert.id;
      _downloadProgress[cert.id] = 0;
    });

    try {
      final fullUrl = _getCorrectUrl(cert.fileUrl);

      debugPrint('Yuklanmoqda: $fullUrl');

      String fileName = _generateFileName(cert);

      String? token = await _tokenStorage.readAccessToken();

      FileDownloader.downloadFile(
        url: fullUrl,
        name: fileName,
        headers: {
          'Authorization': 'Bearer $token',
        },
        onProgress: (fileName, progress) {
          debugPrint('Yuklanmoqda: $progress%');
          if (mounted) {
            setState(() {
              _downloadProgress[cert.id] = progress;
            });
          }
        },
        onDownloadCompleted: (path) {
          debugPrint('Yuklandi: $path');
          if (mounted) {
            setState(() {
              _downloadingId = null;
              _downloadProgress.remove(cert.id);
              _lastDownloadedPath = path;
            });

            _showDownloadSuccessSnackBar(fileName, path);
          }
        },
        onDownloadError: (errorMessage) {
          debugPrint('Xatolik: $errorMessage');
          if (mounted) {
            setState(() {
              _downloadingId = null;
              _downloadProgress.remove(cert.id);
            });

            if (errorMessage.contains('401')) {
              _snack('Ruxsat yo\'q. Qayta kiring.', Colors.red);
            } else if (errorMessage.contains('403')) {
              _snack('Sertifikatni yuklashga ruxsat yo\'q', Colors.red);
            } else if (errorMessage.contains('404')) {
              _snack('Fayl topilmadi', Colors.red);
            } else if (errorMessage.contains('500')) {
              _snack('Server xatoligi', Colors.red);
            } else {
              _snack('Yuklab bo\'lmadi: $errorMessage', Colors.red);
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Umumiy xatolik: $e');
      if (mounted) {
        setState(() {
          _downloadingId = null;
          _downloadProgress.remove(cert.id);
        });
        _snack('Xatolik: $e', Colors.red);
      }
    }
  }

  void _showDownloadSuccessSnackBar(String fileName, String filePath) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sertifikat saqlandi',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              fileName,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Ochish',
          textColor: Colors.white,
          onPressed: () => _openFolder(filePath),
        ),
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 30) {
          if (await Permission.manageExternalStorage.isGranted) {
            debugPrint('Android 11+ ruxsat bor');
            return true;
          }

          debugPrint('Android 11+ ruxsat so\'ralmoqda');
          final status = await Permission.manageExternalStorage.request();
          debugPrint('Ruxsat statusi: $status');
          return status.isGranted;
        } else {
          if (await Permission.storage.isGranted) {
            debugPrint('Android <11 ruxsat bor');
            return true;
          }

          debugPrint('Android <11 ruxsat so\'ralmoqda');
          final status = await Permission.storage.request();
          debugPrint('Ruxsat statusi: $status');
          return status.isGranted;
        }
      } catch (e) {
        debugPrint('Ruxsat tekshirish xatoligi: $e');
        return false;
      }
    }

    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ruxsat kerak'),
        content: const Text(
          'Sertifikatlarni yuklab olish uchun fayllarga kirish ruxsati kerak. '
              'Iltimos, sozlamalardan ruxsat bering.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Bekor qilish',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sozlamalarga o\'tish'),
          ),
        ],
      ),
    );
  }

  String _generateFileName(Certificate cert) {
    String baseName = cert.title.isNotEmpty ? cert.title : 'sertifikat';
    baseName = baseName.replaceAll(RegExp(r'[^\w\s\u0400-\u04FF]'), '');
    baseName = baseName.replaceAll(' ', '_');

    final date = cert.issuedAt.isNotEmpty
        ? cert.issuedAt.replaceAll('-', '')
        : DateTime.now().toIso8601String().split('T').first.replaceAll('-', '');

    String extension = '';
    String lowerUrl = cert.fileUrl.toLowerCase();

    if (lowerUrl.endsWith('.pdf')) {
      extension = '.pdf';
    } else if (lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg')) {
      extension = '.jpg';
    } else if (lowerUrl.endsWith('.png')) {
      extension = '.png';
    } else if (lowerUrl.endsWith('.doc')) {
      extension = '.doc';
    } else if (lowerUrl.endsWith('.docx')) {
      extension = '.docx';
    } else {
      int lastDot = cert.fileUrl.lastIndexOf('.');
      if (lastDot != -1 && lastDot < cert.fileUrl.length - 1) {
        extension = cert.fileUrl.substring(lastDot);
      } else {
        extension = '.pdf';
      }
    }

    return '$baseName$extension';
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
    if (_isLoading && _items.isEmpty) {
      return _buildLoadingView();
    }

    if (_error != null && _items.isEmpty) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 40,
      child: _items.isEmpty
          ? _buildEmptyView()
          : ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length,
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildCertificateCard(_items[i]),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
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
            'Sertifikatlar yuklanmoqda...',
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
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
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: _load,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Qayta urinish',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
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
                  color: AppColors.primary.withOpacity(0.1),
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
                'Sertifikatlar topilmadi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Siz hali hech qanday sertifikatga ega emassiz',
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
    );
  }

  Widget _buildCertificateCard(Certificate item) {
    final isLoading = _downloadingId == item.id;
    final progress = _downloadProgress[item.id] ?? 0;
    final fileExt = _getFileExtension(item.fileUrl);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : () => _downloadCertificate(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title.isNotEmpty ? item.title : 'Sertifikat',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.issuedAt.isNotEmpty ? item.issuedAt : 'Sana noma\'lum',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isLoading)
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                            if (progress > 0)
                              Text(
                                '${progress.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Yuklash',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (isLoading && progress > 0) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_rounded,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fileExt,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFileExtension(String url) {
    String lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) return 'PDF';
    if (lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg')) return 'Rasm (JPG)';
    if (lowerUrl.endsWith('.png')) return 'Rasm (PNG)';
    if (lowerUrl.endsWith('.doc')) return 'DOC';
    if (lowerUrl.endsWith('.docx')) return 'DOCX';
    return 'Fayl';
  }
}