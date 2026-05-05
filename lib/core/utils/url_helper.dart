import '../constants/api_constants.dart';

class UrlHelper {
  UrlHelper._();
  static String normalizeMediaUrl(String source) {
    var url = source.trim();
    if (url.isEmpty) return '';

    if (url.startsWith('/')) {
      return '${ApiConstants.baseHost}$url';
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return '${ApiConstants.baseHost}/$url';
    }
    final httpHost = ApiConstants.baseHost.replaceFirst('https://', 'http://');
    if (url.startsWith('$httpHost/')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }
}
