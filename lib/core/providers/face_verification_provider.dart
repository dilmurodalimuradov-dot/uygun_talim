import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceVerificationProvider extends ChangeNotifier {
  static final FaceVerificationProvider _instance =
  FaceVerificationProvider._internal();

  factory FaceVerificationProvider() => _instance;

  FaceVerificationProvider._internal();

  bool _isVerified = false;
  bool _isLoading = false;
  String? _error;
  SharedPreferences? _prefs;

  bool get isVerified => _isVerified;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialization
  Future<void> init() async {
    await _initPrefs();
    await loadVerification();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Load verification status
  Future<void> loadVerification() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      await _initPrefs();
      _isVerified = _prefs?.getBool('isFaceVerified') ?? false;
    } catch (e) {
      _setError('Yuklashda xatolik: ${e.toString()}');
      _isVerified = false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Set verification status
  Future<void> setVerified(bool value) async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      await _initPrefs();
      await _prefs?.setBool('isFaceVerified', value);
      _isVerified = value;
    } catch (e) {
      _setError('Saqlashda xatolik: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Reset verification
  Future<void> resetVerification() async {
    await setVerified(false);
  }

  // Clear all data
  Future<void> clearAllData() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      await _initPrefs();
      await _prefs?.remove('isFaceVerified');
      _isVerified = false;
    } catch (e) {
      _setError('Tozalashda xatolik: ${e.toString()}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Toggle verification (for testing)
  Future<void> toggleVerification() async {
    await setVerified(!_isVerified);
  }

  // Private helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _prefs = null;
    super.dispose();
  }
}