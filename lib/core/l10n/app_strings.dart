import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

class AppStrings {
  AppStrings._();

  static final _instances = <String, AppStrings>{
    'uz': _UzStrings(),
    'ru': _RuStrings(),
    'en': _EnStrings(),
  };

  /// Faqat build() ichida — locale o'zgarganda widget rebuild bo'ladi
  static AppStrings of(BuildContext context) {
    final code = context.watch<LocaleProvider>().locale.languageCode;
    return _instances[code] ?? _instances['uz']!;
  }

  /// onTap, async metodlar, initState uchun — listen: false, rebuild yo'q
  static AppStrings read(BuildContext context) {
    final code = context.read<LocaleProvider>().locale.languageCode;
    return _instances[code] ?? _instances['uz']!;
  }

  static AppStrings forCode(String code) {
    return _instances[code] ?? _instances['uz']!;
  }

  // ---- Bottom Nav ----
  String get navCourses => 'Kurslar';
  String get navExams => 'Imtihonlar';
  String get navProfile => 'Profil';

  // ---- Login ----
  String get loginTitle => "OAuth2 orqali kirish";
  String get loginDescription =>
      "Kirish havolasini oling. Brauzerda avtorizatsiyadan so'ng ilova avtomatik qaytadi.";
  String get loginGetLink => 'Kirish havolasini olish';
  String get loginLoadingLink => 'Havola olinmoqda...';
  String get loginLinkReady => 'Havola tayyor. Kirish oynasi ochilmoqda...';
  String get loginCancelled => 'Kirish jarayoni bekor qilindi.';
  String get loginTokenNotFound =>
      'Token topilmadi. Iltimos, qayta urinib ko\'ring.';
  String get loginBadLink => 'Havola noto\'g\'ri formatda.';

  // ---- OAuthWebView ----
  String get webviewTitle => 'Kirish';
  String get webviewPageError => 'Sahifani ochishda xatolik yuz berdi.';

  // ---- Profile ----
  String get profileTitle => 'Profil';
  String get profileLoading => 'Profil yuklanmoqda...';
  String get profileError => 'Profilni olishda xatolik yuz berdi.';
  String get profileStudent => 'Talaba';
  String get profileStudentId => 'Talaba ID';
  String get profileSettings => 'Sozlamalar';
  String get profileCopyToken => 'Access tokenni nusxalash';
  String get profileCertificates => 'Sertifikatlarim';
  String get profilePayments => 'To\'lovlarim';
  String get profileSupport => 'Texnik yordam';
  String get profileLogout => 'Chiqish';
  String get profileLogoutConfirmTitle => 'Chiqish';
  String get profileLogoutConfirmBody => 'Haqiqatan ham chiqmoqchimisiz?';
  String get profileTokenCopied => 'Token nusxalandi';
  String get profileTokenNotFound => 'Access token topilmadi.';
  String get profileUserFallback => 'Foydalanuvchi';
  String get profileSupportTitle => 'Texnik Yordam';
  String get profileSupportSubtitle =>
      'Savollar va muammolar uchun\nTelegram orqali bog\'laning';
  String get profileSupportAdmin => 'Admin';
  String get profileSupportUsername => '@uygun_talim_admin';
  String get profileSupportOpenTelegram => 'Telegram orqali yozish';
  String get profileSupportNoTelegram => 'Telegram ilovasi topilmadi';
  String get profileSupportUsernameCopied => 'Username nusxalandi';

  // ---- Courses ----
  String get coursesTitle => 'Kurslar';
  String get coursesSubtitle => 'Barcha kurslar';
  String get coursesNotFound => 'Kurslar topilmadi';
  String get coursesNotFoundSub => 'Hozircha kurslar mavjud emas';
  String get coursesLoadError => 'Kurslarni yuklashda xatolik';
  String get coursesTimeout =>
      'Server bilan bog\'lanish vaqti tugadi. Internetni tekshiring.';
  String get coursesTokenNotFound =>
      'Access token topilmadi. Iltimos, qayta kiring.';
  String get coursesFree => 'Bepul';
  String get coursesPurchased => 'Sotib olingan';
  String get coursesStart => 'Kursni boshlash';

  // ---- Course Detail ----
  String get courseDetailTitle => 'Kurs tafsiloti';
  String get coursesSubject => 'Fan';
  String get coursesPrice => 'Narx';
  String get coursesProgress => 'Progress';
  String get coursesBuy => 'Sotib olish';
  String get coursesPaid => "To'langan";
  String get coursesUnpaid => "To'lanmagan";
  String get coursesNotPurchased => 'Sotib olinmagan';
  String get coursesCourseStarted => 'Kurs boshlandi';
  String get coursesStartNow => 'Kursni boshlash';
  String get coursesPaymentSuccess => "To'lov muvaffaqiyatli amalga oshirildi";
  String get coursesPaymentFailed => "To'lov amalga oshmadi";
  String get coursesLoadingError => "Kurs ma'lumotlarini yuklashda xatolik";
  String get coursesBuyNow => "Hoziroq sotib olish";

  // ---- Exams ----
  String get examsTitle => 'Testlar';
  String get examsNotFound => 'Testlar topilmadi';
  String get examsNotFoundSub => 'Hozircha testlar mavjud emas';
  String get examsTokenNotFound => 'Access token topilmadi.';
  String get examsDuration => 'daqiqa';
  String get examsQuestions => 'ta savol';

  // ---- Certificates ----
  String get certsTitle => 'Sertifikatlar';
  String get certsLoading => 'Sertifikatlar yuklanmoqda...';
  String get certsNotFound => 'Sertifikatlar topilmadi';
  String get certsNotFoundSub =>
      'Siz hali hech qanday sertifikatga ega emassiz';
  String get certsTokenNotFound => 'Token topilmadi. Qayta kiring.';
  String get certsSaved => 'Sertifikat saqlandi';
  String get certsOpen => 'Ochish';
  String get certsDownload => 'Yuklash';
  String get certsNoFile => 'Fayl manzili mavjud emas';
  String get certsNoFolder => 'Papkani ochib bo\'lmadi';
  String get certsUnknownDate => 'Sana noma\'lum';
  String get certsPermissionTitle => 'Ruxsat kerak';
  String get certsPermissionBody =>
      'Sertifikatlarni yuklab olish uchun fayllarga kirish ruxsati kerak. Iltimos, sozlamalardan ruxsat bering.';
  String get certsGoSettings => 'Sozlamalarga o\'tish';
  String get certsNoPermission => 'Ruxsat yo\'q. Qayta kiring.';
  String get certsNoAccess => 'Sertifikatni yuklashga ruxsat yo\'q';
  String get certsFileNotFound => 'Fayl topilmadi';
  String get certsServerError => 'Server xatoligi';

  // ---- Settings ----
  String get settingsTitle => 'Sozlamalar';
  String get settingsLangTitle => 'Interfeys tili';
  String get settingsLangSubtitle => 'Ilovaning ko\'rinish tilini tanlang';
  String get settingsLangSavedUz => "Til saqlandi: O'zbek";
  String get settingsLangSavedRu => 'Язык сохранён: Русский';
  String get settingsLangSavedEn => 'Language saved: English';

  // ---- Lesson ----
  String get lessonTitle => 'Darslar';
  String get lessonCompleted => "Bajarildi";
  String get lessonInProgress => "Jarayonda";
  String get lessonNotStarted => "Boshlanmagan";
  String get lessonPrevLesson => "Oldingi dars";
  String get lessonNextLesson => "Keyingi dars";
  String get lessonMarkComplete => "Darsni tugallangan deb belgilash";
  String get lessonComplete => "Tugallangan";

  // ---- Errors ----
  String get errorTryAgain => 'Qayta urinib ko\'ring';
  String get errorCheckConnection => 'Internet aloqasini tekshiring';

  // ---- Common ----
  String get cancel => 'Bekor qilish';
  String get retry => 'Qayta urinish';
  String get logout => 'Chiqish';
  String get routeNotFound => 'Topilmadi';
  String get routeNotFoundMsg => 'Route topilmadi';

  // ---- Payments ----
  String get paymentsTitle => 'To\'lovlar';
  String get paymentsTabMine => 'Mening';
  String get paymentsTabSuccess => 'Muvaffaqiyatli';
  String get paymentsLoading => 'To\'lovlar yuklanmoqda...';
  String get paymentsTokenNotFound => 'Access token topilmadi.';
  String get paymentsNotFound => 'To\'lovlar topilmadi';
  String get paymentsSuccessNotFound => 'Muvaffaqiyatli to\'lovlar topilmadi';
  String get paymentsNotFoundHint =>
      'Yangi to\'lov yaratish uchun yuqoridagi tugmani bosing';
  String get paymentsSuccessNotFoundHint =>
      'Hali hech qanday muvaffaqiyatli to\'lov amalga oshirilmagan';
  String get paymentsCreate => 'To\'lov yaratish';
  String get paymentsCreating => 'Yaratilmoqda...';
  String get paymentsNoPendingCourses => 'To\'lanadigan kurslar topilmadi.';
  String get paymentsStatusTitle => 'To\'lov holati';
  String get paymentsPickCourse => 'Kursni tanlang';
  String get paymentsCourseFallback => 'Kurs';
  String get paymentsStatusSuccess => 'Muvaffaqiyatli';
  String get paymentsStatusCancelled => 'Bekor qilindi';
  String get paymentsStatusWaiting => 'Kutilmoqda';
  String get paymentsStatusPending => 'Jarayonda';
  String get paymentsStatusRefund => 'Qaytarildi';

  // ---- Payment Checkout ----
  String get checkoutTitle => 'To\'lov usuli';
  String get checkoutPaymeLabel => 'Payme';
  String get checkoutPaymeSubtitle => 'Payme ilovasi orqali to\'lash';
  String get checkoutBadUrl => 'To\'lov havolasi noto\'g\'ri.';
  String get checkoutPaymeError => 'Payme ilovasini ochib bo\'lmadi.';
}

class _UzStrings extends AppStrings {
  _UzStrings() : super._();
}

class _RuStrings extends AppStrings {
  _RuStrings() : super._();

  // ---- Bottom Nav ----
  @override
  String get navCourses => 'Курсы';
  @override
  String get navExams => 'Экзамены';
  @override
  String get navProfile => 'Профиль';

  // ---- Login ----
  @override
  String get loginTitle => 'Вход через OAuth2';
  @override
  String get loginDescription =>
      'Получите ссылку для входа. После авторизации в браузере приложение вернётся автоматически.';
  @override
  String get loginGetLink => 'Получить ссылку для входа';
  @override
  String get loginLoadingLink => 'Получение ссылки...';
  @override
  String get loginLinkReady => 'Ссылка готова. Открывается окно входа...';
  @override
  String get loginCancelled => 'Процесс входа отменён.';
  @override
  String get loginTokenNotFound =>
      'Токен не найден. Пожалуйста, попробуйте снова.';
  @override
  String get loginBadLink => 'Ссылка имеет неверный формат.';

  // ---- OAuthWebView ----
  @override
  String get webviewTitle => 'Вход';
  @override
  String get webviewPageError => 'Ошибка при открытии страницы.';

  // ---- Profile ----
  @override
  String get profileTitle => 'Профиль';
  @override
  String get profileLoading => 'Загрузка профиля...';
  @override
  String get profileError => 'Ошибка при получении профиля.';
  @override
  String get profileStudent => 'Студент';
  @override
  String get profileStudentId => 'ID студента';
  @override
  String get profileSettings => 'Настройки';
  @override
  String get profileCopyToken => 'Скопировать access token';
  @override
  String get profileCertificates => 'Мои сертификаты';
  @override
  String get profilePayments => 'Мои платежи';
  @override
  String get profileSupport => 'Техническая поддержка';
  @override
  String get profileLogout => 'Выйти';
  @override
  String get profileLogoutConfirmTitle => 'Выход';
  @override
  String get profileLogoutConfirmBody => 'Вы действительно хотите выйти?';
  @override
  String get profileTokenCopied => 'Токен скопирован';
  @override
  String get profileTokenNotFound => 'Access token не найден.';
  @override
  String get profileUserFallback => 'Пользователь';
  @override
  String get profileSupportTitle => 'Техподдержка';
  @override
  String get profileSupportSubtitle =>
      'По вопросам и проблемам\nсвяжитесь через Telegram';
  @override
  String get profileSupportAdmin => 'Администратор';
  @override
  String get profileSupportUsername => '@uygun_talim_admin';
  @override
  String get profileSupportOpenTelegram => 'Написать в Telegram';
  @override
  String get profileSupportNoTelegram => 'Telegram не установлен';
  @override
  String get profileSupportUsernameCopied => 'Имя пользователя скопировано';

  // ---- Courses ----
  @override
  String get coursesTitle => 'Курсы';
  @override
  String get coursesSubtitle => 'Все курсы';
  @override
  String get coursesNotFound => 'Курсы не найдены';
  @override
  String get coursesNotFoundSub => 'Пока курсов нет';
  @override
  String get coursesLoadError => 'Ошибка загрузки курсов';
  @override
  String get coursesTimeout =>
      'Соединение с сервером истекло. Проверьте интернет.';
  @override
  String get coursesTokenNotFound =>
      'Access token не найден. Пожалуйста, войдите снова.';
  @override
  String get coursesFree => 'Бесплатно';
  @override
  String get coursesPurchased => 'Куплен';
  @override
  String get coursesStart => 'Начать курс';

  // ---- Course Detail ----
  @override
  String get courseDetailTitle => 'Детали курса';
  @override
  String get coursesSubject => 'Предмет';
  @override
  String get coursesPrice => 'Цена';
  @override
  String get coursesProgress => 'Прогресс';
  @override
  String get coursesBuy => 'Купить';
  @override
  String get coursesPaid => 'Оплачено';
  @override
  String get coursesUnpaid => 'Не оплачено';
  @override
  String get coursesNotPurchased => 'Не куплено';
  @override
  String get coursesCourseStarted => 'Курс начат';
  @override
  String get coursesStartNow => 'Начать курс';
  @override
  String get coursesPaymentSuccess => 'Платеж успешно выполнен';
  @override
  String get coursesPaymentFailed => 'Платеж не выполнен';
  @override
  String get coursesLoadingError => 'Ошибка загрузки данных курса';
  @override
  String get coursesBuyNow => 'Купить сейчас';

  // ---- Exams ----
  @override
  String get examsTitle => 'Тесты';
  @override
  String get examsNotFound => 'Тесты не найдены';
  @override
  String get examsNotFoundSub => 'Пока тестов нет';
  @override
  String get examsTokenNotFound => 'Access token не найден.';
  @override
  String get examsDuration => 'минут';
  @override
  String get examsQuestions => 'вопросов';

  // ---- Certificates ----
  @override
  String get certsTitle => 'Сертификаты';
  @override
  String get certsLoading => 'Загрузка сертификатов...';
  @override
  String get certsNotFound => 'Сертификаты не найдены';
  @override
  String get certsNotFoundSub => 'У вас пока нет сертификатов';
  @override
  String get certsTokenNotFound => 'Токен не найден. Войдите снова.';
  @override
  String get certsSaved => 'Сертификат сохранён';
  @override
  String get certsOpen => 'Открыть';
  @override
  String get certsDownload => 'Скачать';
  @override
  String get certsNoFile => 'Адрес файла недоступен';
  @override
  String get certsNoFolder => 'Не удалось открыть папку';
  @override
  String get certsUnknownDate => 'Дата неизвестна';
  @override
  String get certsPermissionTitle => 'Необходимо разрешение';
  @override
  String get certsPermissionBody =>
      'Для загрузки сертификатов нужен доступ к файлам. Разрешите в настройках.';
  @override
  String get certsGoSettings => 'Перейти в настройки';
  @override
  String get certsNoPermission => 'Нет доступа. Войдите снова.';
  @override
  String get certsNoAccess => 'Нет разрешения на загрузку';
  @override
  String get certsFileNotFound => 'Файл не найден';
  @override
  String get certsServerError => 'Ошибка сервера';

  // ---- Settings ----
  @override
  String get settingsTitle => 'Настройки';
  @override
  String get settingsLangTitle => 'Язык интерфейса';
  @override
  String get settingsLangSubtitle => 'Выберите язык приложения';
  @override
  String get settingsLangSavedUz => "Язык сохранён: Узбекский";
  @override
  String get settingsLangSavedRu => 'Язык сохранён: Русский';
  @override
  String get settingsLangSavedEn => 'Язык сохранён: Английский';

  // ---- Lesson ----
  @override
  String get lessonTitle => 'Уроки';
  @override
  String get lessonCompleted => 'Завершено';
  @override
  String get lessonInProgress => 'В процессе';
  @override
  String get lessonNotStarted => 'Не начато';
  @override
  String get lessonPrevLesson => 'Предыдущий урок';
  @override
  String get lessonNextLesson => 'Следующий урок';
  @override
  String get lessonMarkComplete => 'Отметить урок как завершенный';
  @override
  String get lessonComplete => 'Завершено';

  // ---- Errors ----
  @override
  String get errorTryAgain => 'Попробуйте еще раз';
  @override
  String get errorCheckConnection => 'Проверьте интернет-соединение';

  // ---- Common ----
  @override
  String get cancel => 'Отмена';
  @override
  String get retry => 'Повторить';
  @override
  String get logout => 'Выйти';
  @override
  String get routeNotFound => 'Не найдено';
  @override
  String get routeNotFoundMsg => 'Маршрут не найден';

  // ---- Payments ----
  @override
  String get paymentsTitle => 'Платежи';
  @override
  String get paymentsTabMine => 'Мои';
  @override
  String get paymentsTabSuccess => 'Успешные';
  @override
  String get paymentsLoading => 'Загрузка платежей...';
  @override
  String get paymentsTokenNotFound => 'Access token не найден.';
  @override
  String get paymentsNotFound => 'Платежи не найдены';
  @override
  String get paymentsSuccessNotFound => 'Успешных платежей нет';
  @override
  String get paymentsNotFoundHint =>
      'Нажмите кнопку выше, чтобы создать новый платёж';
  @override
  String get paymentsSuccessNotFoundHint =>
      'Пока не было ни одного успешного платежа';
  @override
  String get paymentsCreate => 'Создать платёж';
  @override
  String get paymentsCreating => 'Создаётся...';
  @override
  String get paymentsNoPendingCourses => 'Нет курсов для оплаты.';
  @override
  String get paymentsStatusTitle => 'Статус платежа';
  @override
  String get paymentsPickCourse => 'Выберите курс';
  @override
  String get paymentsCourseFallback => 'Курс';
  @override
  String get paymentsStatusSuccess => 'Успешно';
  @override
  String get paymentsStatusCancelled => 'Отменён';
  @override
  String get paymentsStatusWaiting => 'Ожидание';
  @override
  String get paymentsStatusPending => 'В процессе';
  @override
  String get paymentsStatusRefund => 'Возврат';

  // ---- Payment Checkout ----
  @override
  String get checkoutTitle => 'Способ оплаты';
  @override
  String get checkoutPaymeLabel => 'Payme';
  @override
  String get checkoutPaymeSubtitle => 'Оплатить через приложение Payme';
  @override
  String get checkoutBadUrl => 'Ссылка на оплату недействительна.';
  @override
  String get checkoutPaymeError => 'Не удалось открыть Payme.';
}

class _EnStrings extends AppStrings {
  _EnStrings() : super._();

  // ---- Bottom Nav ----
  @override
  String get navCourses => 'Courses';
  @override
  String get navExams => 'Exams';
  @override
  String get navProfile => 'Profile';

  // ---- Login ----
  @override
  String get loginTitle => 'Sign in via OAuth2';
  @override
  String get loginDescription =>
      'Get a login link. After authorizing in the browser, the app will return automatically.';
  @override
  String get loginGetLink => 'Get login link';
  @override
  String get loginLoadingLink => 'Getting link...';
  @override
  String get loginLinkReady => 'Link ready. Opening login window...';
  @override
  String get loginCancelled => 'Login process cancelled.';
  @override
  String get loginTokenNotFound => 'Token not found. Please try again.';
  @override
  String get loginBadLink => 'Link has invalid format.';

  // ---- OAuthWebView ----
  @override
  String get webviewTitle => 'Sign in';
  @override
  String get webviewPageError => 'Failed to load page.';

  // ---- Profile ----
  @override
  String get profileTitle => 'Profile';
  @override
  String get profileLoading => 'Loading profile...';
  @override
  String get profileError => 'Error loading profile.';
  @override
  String get profileStudent => 'Student';
  @override
  String get profileStudentId => 'Student ID';
  @override
  String get profileSettings => 'Settings';
  @override
  String get profileCopyToken => 'Copy access token';
  @override
  String get profileCertificates => 'My certificates';
  @override
  String get profilePayments => 'My payments';
  @override
  String get profileSupport => 'Technical support';
  @override
  String get profileLogout => 'Log out';
  @override
  String get profileLogoutConfirmTitle => 'Log out';
  @override
  String get profileLogoutConfirmBody => 'Are you sure you want to log out?';
  @override
  String get profileTokenCopied => 'Token copied';
  @override
  String get profileTokenNotFound => 'Access token not found.';
  @override
  String get profileUserFallback => 'User';
  @override
  String get profileSupportTitle => 'Tech Support';
  @override
  String get profileSupportSubtitle =>
      'For questions and issues\ncontact us via Telegram';
  @override
  String get profileSupportAdmin => 'Admin';
  @override
  String get profileSupportUsername => '@uygun_talim_admin';
  @override
  String get profileSupportOpenTelegram => 'Message on Telegram';
  @override
  String get profileSupportNoTelegram => 'Telegram not installed';
  @override
  String get profileSupportUsernameCopied => 'Username copied';

  // ---- Courses ----
  @override
  String get coursesTitle => 'Courses';
  @override
  String get coursesSubtitle => 'All courses';
  @override
  String get coursesNotFound => 'No courses found';
  @override
  String get coursesNotFoundSub => 'No courses available yet';
  @override
  String get coursesLoadError => 'Error loading courses';
  @override
  String get coursesTimeout =>
      'Server connection timed out. Check your internet.';
  @override
  String get coursesTokenNotFound =>
      'Access token not found. Please sign in again.';
  @override
  String get coursesFree => 'Free';
  @override
  String get coursesPurchased => 'Purchased';
  @override
  String get coursesStart => 'Start course';

  // ---- Course Detail ----
  @override
  String get courseDetailTitle => 'Course Details';
  @override
  String get coursesSubject => 'Subject';
  @override
  String get coursesPrice => 'Price';
  @override
  String get coursesProgress => 'Progress';
  @override
  String get coursesBuy => 'Buy';
  @override
  String get coursesPaid => 'Paid';
  @override
  String get coursesUnpaid => 'Unpaid';
  @override
  String get coursesNotPurchased => 'Not purchased';
  @override
  String get coursesCourseStarted => 'Course started';
  @override
  String get coursesStartNow => 'Start course';
  @override
  String get coursesPaymentSuccess => 'Payment successful';
  @override
  String get coursesPaymentFailed => 'Payment failed';
  @override
  String get coursesLoadingError => 'Error loading course data';
  @override
  String get coursesBuyNow => 'Buy now';

  // ---- Exams ----
  @override
  String get examsTitle => 'Tests';
  @override
  String get examsNotFound => 'No tests found';
  @override
  String get examsNotFoundSub => 'No tests available yet';
  @override
  String get examsTokenNotFound => 'Access token not found.';
  @override
  String get examsDuration => 'min';
  @override
  String get examsQuestions => 'questions';

  // ---- Certificates ----
  @override
  String get certsTitle => 'Certificates';
  @override
  String get certsLoading => 'Loading certificates...';
  @override
  String get certsNotFound => 'No certificates found';
  @override
  String get certsNotFoundSub => 'You don\'t have any certificates yet';
  @override
  String get certsTokenNotFound => 'Token not found. Please sign in again.';
  @override
  String get certsSaved => 'Certificate saved';
  @override
  String get certsOpen => 'Open';
  @override
  String get certsDownload => 'Download';
  @override
  String get certsNoFile => 'File address unavailable';
  @override
  String get certsNoFolder => 'Could not open folder';
  @override
  String get certsUnknownDate => 'Unknown date';
  @override
  String get certsPermissionTitle => 'Permission required';
  @override
  String get certsPermissionBody =>
      'Storage access is needed to download certificates. Please allow it in settings.';
  @override
  String get certsGoSettings => 'Go to settings';
  @override
  String get certsNoPermission => 'No access. Please sign in again.';
  @override
  String get certsNoAccess => 'No permission to download';
  @override
  String get certsFileNotFound => 'File not found';
  @override
  String get certsServerError => 'Server error';

  // ---- Settings ----
  @override
  String get settingsTitle => 'Settings';
  @override
  String get settingsLangTitle => 'Interface language';
  @override
  String get settingsLangSubtitle => 'Choose the app language';
  @override
  String get settingsLangSavedUz => "Language saved: Uzbek";
  @override
  String get settingsLangSavedRu => 'Language saved: Russian';
  @override
  String get settingsLangSavedEn => 'Language saved: English';

  // ---- Lesson ----
  @override
  String get lessonTitle => 'Lessons';
  @override
  String get lessonCompleted => 'Completed';
  @override
  String get lessonInProgress => 'In progress';
  @override
  String get lessonNotStarted => 'Not started';
  @override
  String get lessonPrevLesson => 'Previous lesson';
  @override
  String get lessonNextLesson => 'Next lesson';
  @override
  String get lessonMarkComplete => 'Mark lesson as complete';
  @override
  String get lessonComplete => 'Complete';

  // ---- Errors ----
  @override
  String get errorTryAgain => 'Try again';
  @override
  String get errorCheckConnection => 'Check your internet connection';

  // ---- Common ----
  @override
  String get cancel => 'Cancel';
  @override
  String get retry => 'Retry';
  @override
  String get logout => 'Log out';
  @override
  String get routeNotFound => 'Not found';
  @override
  String get routeNotFoundMsg => 'Route not found';

  // ---- Payments ----
  @override
  String get paymentsTitle => 'Payments';
  @override
  String get paymentsTabMine => 'Mine';
  @override
  String get paymentsTabSuccess => 'Successful';
  @override
  String get paymentsLoading => 'Loading payments...';
  @override
  String get paymentsTokenNotFound => 'Access token not found.';
  @override
  String get paymentsNotFound => 'No payments found';
  @override
  String get paymentsSuccessNotFound => 'No successful payments found';
  @override
  String get paymentsNotFoundHint =>
      'Tap the button above to create a new payment';
  @override
  String get paymentsSuccessNotFoundHint =>
      'No successful payments have been made yet';
  @override
  String get paymentsCreate => 'Create payment';
  @override
  String get paymentsCreating => 'Creating...';
  @override
  String get paymentsNoPendingCourses => 'No courses available for payment.';
  @override
  String get paymentsStatusTitle => 'Payment status';
  @override
  String get paymentsPickCourse => 'Select a course';
  @override
  String get paymentsCourseFallback => 'Course';
  @override
  String get paymentsStatusSuccess => 'Successful';
  @override
  String get paymentsStatusCancelled => 'Cancelled';
  @override
  String get paymentsStatusWaiting => 'Waiting';
  @override
  String get paymentsStatusPending => 'Pending';
  @override
  String get paymentsStatusRefund => 'Refunded';

  // ---- Payment Checkout ----
  @override
  String get checkoutTitle => 'Payment method';
  @override
  String get checkoutPaymeLabel => 'Payme';
  @override
  String get checkoutPaymeSubtitle => 'Pay via Payme app';
  @override
  String get checkoutBadUrl => 'Payment link is invalid.';
  @override
  String get checkoutPaymeError => 'Could not open Payme.';
}