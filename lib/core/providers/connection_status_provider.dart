import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// Ekranda ko'rsatiladigan xatolik turi.
enum ConnectionIssue {
  /// Hech qanday muammo yo'q.
  none,

  /// Qurilmada internet (Wi-Fi/mobil tarmoq) umuman yo'q.
  noInternet,

  /// Internet bor, lekin serverga ulanib bo'lmadi yoki server javob
  /// bermayapti / 5xx qaytaryapti.
  serverError,
}

/// Butun ilova bo'ylab internet va server holatini kuzatib turadigan
/// markaziy provider.
///
/// Ikki manbadan signal oladi:
///  1. `connectivity_plus` — qurilmaning tarmoq interfeysi holati
///     (Wi-Fi / mobil / yo'q). Bu "internet kabeli ulanganmi" degan savol,
///     lekin Wi-Fi'ga ulangan bo'lsa ham haqiqiy internet bo'lmasligi mumkin.
///  2. `ApiClient` orqali kelgan haqiqiy so'rov xatolari
///     (`reportNetworkFailure` / `reportSuccess`) — bu "so'rov haqiqatan
///     ham o'tdimi" degan savol va eng ishonchli signal hisoblanadi.
///
/// Shu ikkisini birlashtirib, `issue` qiymatini chiqaradi va shunga qarab
/// butun ilova ustiga "Internet yo'q / Server bilan bog'lanishda xatolik"
/// to'liq ekranini chiqarish mumkin.
class ConnectionStatusProvider extends ChangeNotifier {
  ConnectionStatusProvider({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _serverCheckDebounce;

  ConnectionIssue _issue = ConnectionIssue.none;
  ConnectionIssue get issue => _issue;

  bool get hasIssue => _issue != ConnectionIssue.none;

  bool _deviceHasNetwork = true;
  bool _checkingServer = false;
  bool get isChecking => _checkingServer;

  /// Server bilan oxirgi marta muvaffaqiyatli gaplashilgan vaqt.
  /// Splash va boshqa joylarda boshlang'ich tekshiruv uchun ishlatiladi.
  bool _initialCheckDone = false;
  bool get initialCheckDone => _initialCheckDone;

  Future<void> _init() async {
    // Boshlang'ich holatni tekshirish.
    final initialResults = await _connectivity.checkConnectivity();
    _deviceHasNetwork = _hasAnyConnection(initialResults);

    if (!_deviceHasNetwork) {
      _setIssue(ConnectionIssue.noInternet);
    } else {
      // Wi-Fi/mobil ulangandek ko'rinadi — lekin haqiqatan ham internet
      // ishlayotganini serverga bitta yengil so'rov yuborib tekshiramiz.
      await checkServerReachable(silent: true);
    }
    _initialCheckDone = true;
    notifyListeners();

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final hasNetwork = _hasAnyConnection(results);
      _deviceHasNetwork = hasNetwork;

      if (!hasNetwork) {
        _setIssue(ConnectionIssue.noInternet);
        return;
      }

      // Tarmoq qaytdi — lekin shunchaki "ulangan" degani internet
      // ishlayapti degani emas, shu sababli serverni qayta tekshiramiz.
      await checkServerReachable();
    });
  }

  bool _hasAnyConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// `ApiClient` haqiqiy tarmoq/server xatosiga uchraganda shu metodni
  /// chaqiradi. Bu eng ishonchli signal — chunki haqiqiy so'rov muvaffaqiyatsiz
  /// bo'lgan.
  void reportNetworkFailure() {
    if (!_deviceHasNetwork) {
      _setIssue(ConnectionIssue.noInternet);
    } else {
      _setIssue(ConnectionIssue.serverError);
    }
  }

  /// `ApiClient` muvaffaqiyatli javob olganda chaqiradi — agar hozir
  /// xatolik ekrani ko'rsatilayotgan bo'lsa, uni yashiradi.
  void reportSuccess() {
    if (_issue != ConnectionIssue.none) {
      _setIssue(ConnectionIssue.none);
    }
  }

  /// Serverga yengil so'rov yuborib, haqiqatan ham bog'lanish bor-yo'qligini
  /// tekshiradi. Foydalanuvchi "Qayta urinish" tugmasini bosganda ham
  /// shu metod chaqiriladi.
  ///
  /// Avval ilovaning o'z backend serveri (`ApiConstants.baseHost`) tekshiriladi
  /// — bu eng to'g'ri signal, chunki internet umuman ishlasa-da, ayni shu
  /// server vaqtincha ishlamay qolishi mumkin. Agar biror sababdan
  /// (masalan, backend health endpointi yo'q) bu so'rov tarmoq xatosiga
  /// uchramasdan rad etilsa, qo'shimcha tasdiq uchun umumiy internetni
  /// (`pingUrl`) ham tekshiramiz.
  Future<bool> checkServerReachable({
    String pingUrl = 'https://www.google.com',
    bool silent = false,
  }) async {
    if (_checkingServer) return !hasIssue;
    _checkingServer = true;
    if (!silent) notifyListeners();

    // Avval qurilmaning tarmoq holatini yangidan tekshiramiz.
    final results = await _connectivity.checkConnectivity();
    _deviceHasNetwork = _hasAnyConnection(results);

    if (!_deviceHasNetwork) {
      _checkingServer = false;
      _setIssue(ConnectionIssue.noInternet);
      return false;
    }

    // 1) Ilovaning o'z backend serverini tekshiramiz.
    final ownServerOk = await _pingOnce(ApiConstants.baseHost);
    if (ownServerOk) {
      _checkingServer = false;
      _setIssue(ConnectionIssue.none);
      return true;
    }

    // 2) Backend javob bermadi — bu internet umuman yo'qligidan ham,
    // faqat shu serverning vaqtincha ishlamay qolishidan ham bo'lishi
    // mumkin. Buni ajratish uchun umumiy internetni tekshiramiz.
    final generalInternetOk = await _pingOnce(pingUrl);
    _checkingServer = false;

    if (generalInternetOk) {
      // Internet bor, lekin bizning serverimiz javob bermadi.
      _setIssue(ConnectionIssue.serverError);
    } else {
      // Hatto umumiy internet ham ishlamadi.
      _setIssue(ConnectionIssue.noInternet);
    }
    return false;
  }

  Future<bool> _pingOnce(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      // 5xx — server ishlayapti, lekin xatolik qaytaryapti deb hisoblanadi
      // (manzilga yetib bordik, demak tarmoq/DNS ishlayapti).
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  void _setIssue(ConnectionIssue value) {
    if (_issue == value) return;
    _issue = value;
    notifyListeners();
  }

  /// Debounce qilingan tekshiruv — bir vaqtning o'zida juda ko'p marta
  /// chaqirilishini oldini olish uchun (masalan ApiClient'dan ketma-ket
  /// xatolar kelganda).
  void scheduleServerCheck() {
    _serverCheckDebounce?.cancel();
    _serverCheckDebounce = Timer(const Duration(milliseconds: 300), () {
      checkServerReachable(silent: true);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _serverCheckDebounce?.cancel();
    super.dispose();
  }
}
