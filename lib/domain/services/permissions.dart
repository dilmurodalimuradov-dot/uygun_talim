import 'package:flutter/foundation.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

void downloadFile() {
  FileDownloader.downloadFile(
    url: "https://api.uyguntalim.tsue.uz/media/certificates/4.1_dars._Test.docx",
    name: "4.1_dars._Test.docx",
    onProgress: (String? fileName, double progress) {
      debugPrint("📥 Yuklanmoqda: $fileName - ${progress.toStringAsFixed(1)}%");
    },
    onDownloadCompleted: (String path) {
      debugPrint("✅ Yuklandi: $path");
    },
    onDownloadError: (String error) {
      debugPrint("❌ Xatolik: $error");
    },
  );
}