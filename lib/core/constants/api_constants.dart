/// Barcha API-ga tegishli konstantalar shu yerda jamlangan.
/// MUHIM: profile endpoints baseHost'ga nisbatan (prefix bor),
/// auth endpoints baseUrlV1'ga nisbatan (prefix yo'q).
class ApiConstants {
  ApiConstants._();

  static const String baseHost = 'https://api.uyguntalim.tsue.uz';
  static const String baseUrl = '$baseHost/api';
  static const String baseUrlV1 = '$baseHost/api-v1';

  // CSRF token — haqiqiy prodda .env fayldan o'qilishi kerak.
  static const String csrfToken =
      'x9Jv5GBLMZLVyTRu6rFmF2b8uORvppSDOHtWzbixuyB9RmgznaYKyNpuBDv3eOSb';

  // --- Auth (baseUrlV1'ga qo'shiladi) ---
  static const List<String> authorizationEndpoints = [
    '/authorization-mobil-student',
    '/authorization-mobil-student/',
  ];
  static const List<String> callbackEndpoints = [
    '/student-mobil-callback/',
    '/student-mobil-callback',
    '/student-callback/',
    '/student-callback',
  ];

  // Profile: baseHost'ga to'g'ridan-to'g'ri (prefix bilan).
  static const List<String> profileEndpoints = [
    '/api-v1/account/me/',
    '/api-v1/account/me',
    '/api/account/me/',
    '/api/account/me',
  ];

  // --- Courses ---
  static const String coursesPath = '/courses/';
  static String courseDetailPath(String id) => '/courses/$id/';
  static String courseStartPath(String id) => '/courses/$id/start/';
  static String courseProgressPath(String id) => '/courses/$id/progress/';

  // --- Categories ---
  static const String categoriesPath = '/categories/';
  static String categoryDetailPath(String id) => '/categories/$id/';

  // --- Modules / Lessons ---
  static const String modulesPath = '/modules/';
  static const String lessonsPath = '/lessons/';

  // --- Tests ---
  static const String testsPath = '/tests/';
  static String testDetailPath(String id) => '/tests/$id/';
  static String testSubmitPath(String id) => '/tests/$id/submit/';

  // --- Payments ---
  static const String myPaymentsPath = '/payments/my/';
  static const String successPaymentsPath = '/payments/success/';
  static const String createPaymentPath = '/payments/create/';
  static String paymentStatusPath(String id) => '/payments/$id/status/';

  // --- Certificates ---
  static const String certificatesPath = '/certificates/';
  static const String myCertificatesPath = '/certificates/my/';
  static String certificateDetailPath(String id) => '/certificates/$id/';

  // --- Timeouts ---
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
