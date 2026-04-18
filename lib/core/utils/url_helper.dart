import '../constants/api_constants.dart';

/// Turli joylardan keladigan media URL'larni (rasm, video, fayl)
/// bitta to'g'ri ko'rinishga keltiradi.
class UrlHelper {
  UrlHelper._();

  /// `/media/...` → `https://api.uyguntalim.tsue.uz/media/...`
  /// `http://api...` → `https://api...`
  static String normalizeMediaUrl(String source) {
    var url = source.trim();
    if (url.isEmpty) return '';

    if (url.startsWith('/')) {
      return '${ApiConstants.baseHost}$url';
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = '${ApiConstants.baseHost}/$url';
    }
    if (url.startsWith('http://api.uyguntalim.tsue.uz/')) {
      url = url.replaceFirst('http://', 'https://');
    }
    return url;
  }
}
