import 'dart:developer';

import 'package:flutter/material.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/token_local_datasource.dart';
import '../../shared/routes/app_router.dart';
import '../../shared/routes/app_routes.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/domain/usecases/exchange_code_for_token.dart';
import '../../features/auth/domain/usecases/get_authorization_url.dart';
import '../../features/certificates/data/datasources/certificate_remote_datasource.dart';
import '../../features/certificates/data/repositories/certificate_repository_impl.dart';
import '../../features/certificates/domain/repositories/certificate_repository.dart';
import '../../features/certificates/domain/usecases/get_my_certificates.dart';
import '../../features/courses/data/datasources/course_remote_datasource.dart';
import '../../features/courses/data/repositories/course_repository_impl.dart';
import '../../features/courses/domain/repositories/course_repository.dart';
import '../../features/courses/domain/usecases/course_usecases.dart';
import '../../features/lessons/data/datasources/lesson_remote_datasource.dart';
import '../../features/lessons/data/repositories/lesson_repository_impl.dart';
import '../../features/lessons/domain/repositories/lesson_repository.dart';
import '../../features/lessons/domain/usecases/get_lessons.dart';
import '../../features/modules/data/datasources/module_remote_datasource.dart';
import '../../features/modules/data/repositories/module_repository_impl.dart';
import '../../features/modules/domain/repositories/module_repository.dart';
import '../../features/modules/domain/usecases/get_modules.dart';
import '../../features/payments/data/datasources/payment_remote_datasource.dart';
import '../../features/payments/data/repositories/payment_repository_impl.dart';
import '../../features/payments/domain/repositories/payment_repository.dart';
import '../../features/payments/domain/usecases/payment_usecases.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/get_profile.dart';
import '../../features/tests/data/datasources/test_remote_datasource.dart';
import '../../features/tests/data/repositories/test_repository_impl.dart';
import '../../features/tests/domain/repositories/test_repository.dart';
import '../../features/tests/domain/usecases/test_usecases.dart';
import '../network/api_client.dart';
import '../utils/result.dart';

class ServiceLocator {
  ServiceLocator._();

  // ==================== Core ====================
  static late final ApiClient apiClient;

  // ==================== Auth ====================
  static late final TokenLocalDataSource tokenLocal;
  static late final AuthRemoteDataSource authRemote;
  static late final AuthRepository authRepository;
  static late final GetAuthorizationUrl getAuthorizationUrl;
  static late final ExchangeCodeForToken exchangeCodeForToken;
  static late final CheckAuthStatus checkAuthStatus;
  static late final Logout logout;

  // ==================== Courses ====================
  static late final CourseRemoteDataSource courseRemote;
  static late final CourseRepository courseRepository;
  static late final GetCourses getCourses;
  static late final GetCourseDetail getCourseDetail;
  static late final StartCourse startCourse;
  static late final GetCourseProgress getCourseProgress;

  // ==================== Modules ====================
  static late final ModuleRemoteDataSource moduleRemote;
  static late final ModuleRepository moduleRepository;
  static late final GetModules getModules;

  // ==================== Lessons ====================
  static late final LessonRemoteDataSource lessonRemote;
  static late final LessonRepository lessonRepository;
  static late final GetLessons getLessons;

  // ==================== Tests ====================
  static late final TestRemoteDataSource testRemote;
  static late final TestRepository testRepository;
  static late final GetTests getTests;
  static late final GetTestDetail getTestDetail;
  static late final SubmitTest submitTest;

  // ==================== Payments ====================
  static late final PaymentRemoteDataSource paymentRemote;
  static late final PaymentRepository paymentRepository;
  static late final GetMyPayments getMyPayments;
  static late final GetSuccessPayments getSuccessPayments;
  static late final CreatePayment createPayment;

  // ==================== Certificates ====================
  static late final CertificateRemoteDataSource certificateRemote;
  static late final CertificateRepository certificateRepository;
  static late final GetMyCertificates getMyCertificates;

  // ==================== Profile ====================
  static late final ProfileRemoteDataSource profileRemote;
  static late final ProfileRepository profileRepository;
  static late final GetProfile getProfile;

  static bool _initialized = false;

  /// Barcha bog'liqliklarni qurish.
  /// Tartib muhim: avval core, keyin har feature'ning data → repo → usecase.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      log('ServiceLocator: Initialization started...');

      // ==================== Core ====================
      apiClient = ApiClient();

      // ==================== Auth ====================
      tokenLocal = TokenLocalDataSourceImpl();

      // ApiClient'ga token provider ulaymiz — har so'rovda token o'qiladi.
      apiClient.tokenProvider = tokenLocal.getAccessToken;

      // 401 bo'lganda tokenni tozalab login sahifasiga yo'naltirish.
      apiClient.onUnauthorized = () async {
        await tokenLocal.clearTokens();
        if (AppRouter.navigatorKey.currentContext != null) {
          AppRouter.navigatorKey.currentState?.pushNamedAndRemoveUntil(
            AppRoutes.loginPage,
                (route) => false,
          );
        }
      };

      authRemote = AuthRemoteDataSourceImpl(apiClient);
      authRepository = AuthRepositoryImpl(
        remoteDataSource: authRemote,
        localDataSource: tokenLocal,
      );
      getAuthorizationUrl = GetAuthorizationUrl(authRepository);
      exchangeCodeForToken = ExchangeCodeForToken(authRepository);
      checkAuthStatus = CheckAuthStatus(authRepository);
      logout = Logout(authRepository);

      log('ServiceLocator: Auth initialized');

      // ==================== Courses ====================
      courseRemote = CourseRemoteDataSourceImpl(apiClient);
      courseRepository = CourseRepositoryImpl(courseRemote);
      getCourses = GetCourses(courseRepository);
      getCourseDetail = GetCourseDetail(courseRepository);
      startCourse = StartCourse(courseRepository);
      getCourseProgress = GetCourseProgress(courseRepository);

      log('ServiceLocator: Courses initialized');

      // ==================== Modules ====================
      moduleRemote = ModuleRemoteDataSourceImpl(apiClient);
      moduleRepository = ModuleRepositoryImpl(moduleRemote);
      getModules = GetModules(moduleRepository);

      log('ServiceLocator: Modules initialized');

      // ==================== Lessons ====================
      lessonRemote = LessonRemoteDataSourceImpl(apiClient);
      lessonRepository = LessonRepositoryImpl(lessonRemote);
      getLessons = GetLessons(lessonRepository);

      log('ServiceLocator: Lessons initialized');

      // ==================== Tests ====================
      testRemote = TestRemoteDataSourceImpl(apiClient);
      testRepository = TestRepositoryImpl(testRemote);
      getTests = GetTests(testRepository);
      getTestDetail = GetTestDetail(testRepository);
      submitTest = SubmitTest(testRepository);

      log('ServiceLocator: Tests initialized');

      // ==================== Payments ====================
      paymentRemote = PaymentRemoteDataSourceImpl(apiClient);
      paymentRepository = PaymentRepositoryImpl(paymentRemote);
      getMyPayments = GetMyPayments(paymentRepository);
      getSuccessPayments = GetSuccessPayments(paymentRepository);
      createPayment = CreatePayment(paymentRepository);

      log('ServiceLocator: Payments initialized');

      // ==================== Certificates ====================
      certificateRemote = CertificateRemoteDataSourceImpl(apiClient);
      certificateRepository = CertificateRepositoryImpl(certificateRemote);
      getMyCertificates = GetMyCertificates(certificateRepository);

      log('ServiceLocator: Certificates initialized');

      // ==================== Profile ====================
      profileRemote = ProfileRemoteDataSourceImpl(apiClient);
      profileRepository = ProfileRepositoryImpl(profileRemote);
      getProfile = GetProfile(profileRepository);

      log('ServiceLocator: Profile initialized');

      _initialized = true;
      log('ServiceLocator: Initialization completed successfully');
    } catch (e, stackTrace) {
      log('ServiceLocator: Initialization failed - $e',
          error: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Faqat test uchun - initializatsiyani reset qilish
  static void resetForTesting() {
    _initialized = false;
  }

  /// Barcha resurslarni tozalash
  static Future<void> dispose() async {
    if (!_initialized) return;

    apiClient.dispose();
    _initialized = false;

    log('ServiceLocator: Disposed');
  }

  /// Initializatsiya holatini tekshirish
  static bool get isInitialized => _initialized;

  /// Token tokini tozalash (logout uchun)
  static Future<void> clearAuth() async {
    if (tokenLocal != null) {
      await tokenLocal.clearTokens();
    }
  }
}