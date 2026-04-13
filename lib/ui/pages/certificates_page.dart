import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pr/domain/services/certificate_service.dart';
import 'package:pr/domain/services/token_storage_service.dart';
import 'package:pr/ui/theme/app_colors.dart';

class CertificatesPage extends StatelessWidget {
  const CertificatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.secondary,
        title: const Text(
          'Sertifikatlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const SafeArea(
          child: _CertificatesList(),
        ),
      ),
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

  String _getCorrectUrl(String url) {
    if (url.startsWith('http://')) {
      return url.replaceFirst('http://', 'https://');
    }
    else if (url.startsWith('/')) {
      return 'https://api.uyguntalim.tsue.uz$url';
    }
    else if (!url.startsWith('https://')) {
      return 'https://api.uyguntalim.tsue.uz/$url';
    }
    return url;
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

      debugPrint('🔗 Yuklanmoqda: $fullUrl');

      String fileName = _generateFileName(cert);

      String? token = await _tokenStorage.readAccessToken();

      FileDownloader.downloadFile(
        url: fullUrl,
        name: fileName,
        headers: {
          'Authorization': 'Bearer $token',
        },
        onProgress: (fileName, progress) {
          debugPrint('📥 Yuklanmoqda: $progress%');
          if (mounted) {
            setState(() {
              _downloadProgress[cert.id] = progress;
            });
          }
        },
        onDownloadCompleted: (path) {
          debugPrint('✅ Yuklandi: $path');
          if (mounted) {
            setState(() {
              _downloadingId = null;
              _downloadProgress.remove(cert.id);
            });
            _snack('✅ Sertifikat saqlandi: Downloads/$fileName', Colors.green);
          }
        },
        onDownloadError: (errorMessage) {
          debugPrint('❌ Xatolik: $errorMessage');
          if (mounted) {
            setState(() {
              _downloadingId = null;
              _downloadProgress.remove(cert.id);
            });

            if (errorMessage.contains('401')) {
              _snack('❌ Ruxsat yo\'q. Qayta kiring.', Colors.red);
            } else if (errorMessage.contains('403')) {
              _snack('❌ Sertifikatni yuklashga ruxsat yo\'q', Colors.red);
            } else if (errorMessage.contains('404')) {
              _snack('❌ Fayl topilmadi', Colors.red);
            } else if (errorMessage.contains('500')) {
              _snack('❌ Server xatoligi', Colors.red);
            } else {
              _snack('❌ Yuklab bo\'lmadi: $errorMessage', Colors.red);
            }
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Umumiy xatolik: $e');
      if (mounted) {
        setState(() {
          _downloadingId = null;
          _downloadProgress.remove(cert.id);
        });
        _snack('❌ Xatolik: $e', Colors.red);
      }
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (Theme.of(context).platform == TargetPlatform.android) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;

        if (androidInfo.version.sdkInt >= 30) {
          if (await Permission.manageExternalStorage.isGranted) {
            debugPrint('✅ Android 11+ ruxsat bor');
            return true;
          }

          debugPrint('📢 Android 11+ ruxsat so\'ralmoqda');
          final status = await Permission.manageExternalStorage.request();
          debugPrint('📢 Ruxsat statusi: $status');
          return status.isGranted;
        } else {
          if (await Permission.storage.isGranted) {
            debugPrint('✅ Android <11 ruxsat bor');
            return true;
          }

          debugPrint('📢 Android <11 ruxsat so\'ralmoqda');
          final status = await Permission.storage.request();
          debugPrint('📢 Ruxsat statusi: $status');
          return status.isGranted;
        }
      } catch (e) {
        debugPrint('❌ Ruxsat tekshirish xatoligi: $e');
        return false;
      }
    }

    return true;
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ruxsat kerak'),
        content: const Text(
            'Sertifikatlarni yuklab olish uchun fayllarga kirish ruxsati kerak. '
                'Iltimos, sozlamalardan ruxsat bering.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
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

    return '${baseName}';
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _error != null
          ? _infoState(_error!, isError: true)
          : _items.isEmpty
          ? _infoState('Sertifikatlar mavjud emas')
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (_, i) => _card(_items[i]),
      ),
    );
  }

  Widget _card(Certificate item) {
    final isLoading = _downloadingId == item.id;
    final progress = _downloadProgress[item.id] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.workspace_premium, color: AppColors.primary),
            ),
            title: Text(
              item.title.isNotEmpty ? item.title : 'Sertifikat',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.issuedAt.isNotEmpty ? item.issuedAt : 'Sana noma\'lum',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  'Format: ${_getFileExtension(item.fileUrl)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
            trailing: isLoading
                ? SizedBox(
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
                      color: AppColors.primary,
                    ),
                  ),
                  if (progress > 0)
                    Text(
                      '${progress.toInt()}%',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            )
                : IconButton(
              icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 30),
              tooltip: 'Yuklab olish',
              onPressed: () => _downloadCertificate(item),
            ),
          ),
          if (isLoading && progress > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
        ],
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

  Widget _infoState(String text, {bool isError = false}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.info_outline,
                size: 48,
                color: isError ? Colors.red : AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              if (isError) ...[
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Qayta urinish'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}