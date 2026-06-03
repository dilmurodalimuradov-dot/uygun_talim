/// Demo rejim — Google Play reviewerlar va ichki test uchun.
/// Yoqilganda barcha API so'rovlar mock ma'lumotlar qaytaradi (tokensiz).
class DemoMode {
  DemoMode._();

  /// Demo rejim faolmi?
  static bool enabled = false;

  /// Demo video URL — kichik public sample MP4.
  static const String demoVideoUrl =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4';

  /// GET so'rovga mos mock javob qaytaradi yoki `null` (mock yo'q).
  static dynamic mockGet(String path, Map<String, String>? query) {
    // === Profil ===
    if (path.contains('/account/me')) {
      return {
        'id': 'demo-user-id',
        'first_name': 'Demo',
        'last_name': 'Student',
        'full_name': 'Demo Student',
        'email': 'demo@tsue.uz',
        'username': 'demo_student',
        'avatar': null,
        'group': 'DEMO-001',
        'student_id': 'DEMO12345',
      };
    }

    // === Kurslar ===
    if (path == '/courses/' || path == '/courses') {
      return _courses;
    }
    final courseMatch = RegExp(r'^/courses/([^/]+)/?$').firstMatch(path);
    if (courseMatch != null) {
      final id = courseMatch.group(1);
      return _courses.firstWhere(
        (c) => c['id'] == id,
        orElse: () => _courses.first,
      );
    }

    // === Modullar ===
    if (path == '/modules/' || path == '/modules') {
      return _modules;
    }

    // === Darslar ===
    if (path == '/lessons/' || path == '/lessons') {
      final moduleId = query?['module'];
      if (moduleId != null) {
        return _lessonsByModule[moduleId] ?? [];
      }
      return _lessonsByModule.values.expand((e) => e).toList();
    }
    final lessonMatch = RegExp(r'^/lessons/([^/]+)/?$').firstMatch(path);
    if (lessonMatch != null) {
      final id = lessonMatch.group(1);
      for (final list in _lessonsByModule.values) {
        final found = list.where((l) => l['id'] == id).toList();
        if (found.isNotEmpty) return found.first;
      }
      return _lessonsByModule.values.first.first;
    }

    // === Testlar ===
    if (path == '/tests/' || path == '/tests') {
      final moduleId = query?['module'];
      if (moduleId != null) {
        return _testsByModule[moduleId] ?? [];
      }
      return _testsByModule.values.expand((e) => e).toList();
    }
    final testMatch = RegExp(r'^/tests/([^/]+)/?$').firstMatch(path);
    if (testMatch != null) {
      final id = testMatch.group(1);
      for (final list in _testsByModule.values) {
        final found = list.where((t) => t['id'] == id).toList();
        if (found.isNotEmpty) return found.first;
      }
    }

    // === Sertifikatlar ===
    if (path.contains('/certificates/my') || path == '/certificates/') {
      return _certificates;
    }

    // === To'lovlar ===
    if (path.contains('/payments/my') || path.contains('/payments/success')) {
      return _payments;
    }

    // === Kategoriyalar ===
    if (path == '/categories/' || path == '/categories') {
      return _categories;
    }

    return {};
  }

  /// POST so'rovga mos mock javob qaytaradi.
  static dynamic mockPost(String path, dynamic body) {
    // === Test boshlash ===
    final startMatch = RegExp(r'^/tests/([^/]+)/start/?$').firstMatch(path);
    if (startMatch != null) {
      final testId = startMatch.group(1)!;
      final test = _findTest(testId);
      return {
        'attempt_id': 'demo-attempt-${DateTime.now().millisecondsSinceEpoch}',
        'questions': test?['questions'] ?? _demoQuestions,
      };
    }

    // === Test topshirish ===
    final submitMatch = RegExp(r'^/tests/([^/]+)/submit/?$').firstMatch(path);
    if (submitMatch != null) {
      return {
        'success': true,
        'passed': true,
        'attempts_left': 2,
      };
    }

    // === Dars progressi ===
    if (path == '/lesson-progress/') {
      return {
        'success': true,
        'last_position': 9999,
        'max_position': 9999,
        'is_fully_watched': true,
      };
    }

    return {'success': true};
  }

  static Map<String, dynamic>? _findTest(String id) {
    for (final list in _testsByModule.values) {
      for (final t in list) {
        if (t['id'] == id) return t;
      }
    }
    return null;
  }

  // ===========================================================================
  // Mock ma'lumotlar
  // ===========================================================================

  static final List<Map<String, dynamic>> _categories = [
    {'id': 'cat-1', 'name': 'Iqtisodiyot', 'description': 'Iqtisodiy fanlar'},
  ];

  static final List<Map<String, dynamic>> _courses = [
    {
      'id': 'demo-course-1',
      'title': 'Iqtisodiyot asoslari (Demo)',
      'description': 'Iqtisodiy nazariya va amaliyot bo\'yicha kirish kursi.',
      'thumbnail': null,
      'is_paid': false,
      'is_enrolled': true,
      'progress': 0.4,
      'category': 'cat-1',
    },
    {
      'id': 'demo-course-2',
      'title': 'Moliya bozorlari (Demo)',
      'description': 'Moliya bozorlari va investitsiyalar bo\'yicha kurs.',
      'thumbnail': null,
      'is_paid': false,
      'is_enrolled': true,
      'progress': 0.0,
      'category': 'cat-1',
    },
  ];

  static final List<Map<String, dynamic>> _modules = [
    {
      'id': 'demo-module-1',
      'title': '1-modul',
      'order': 1,
      'description': 'Iqtisodiyotning asosiy tushunchalari',
      'is_opened': true,
      'is_completed': false,
      'course': 'demo-course-1',
    },
    {
      'id': 'demo-module-2',
      'title': '2-modul',
      'order': 2,
      'description': 'Talab va taklif',
      'is_opened': true,
      'is_completed': false,
      'course': 'demo-course-1',
    },
  ];

  static final Map<String, List<Map<String, dynamic>>> _lessonsByModule = {
    'demo-module-1': [
      {
        'id': 'demo-lesson-1-1',
        'title': '1.1-dars (Demo)',
        'order': 1,
        'video_file': demoVideoUrl,
        'video_url': null,
        'content': 'Iqtisodiyotning mohiyati va tarmoqlari',
        'progress': {
          'last_position': 0,
          'max_position': 0,
          'is_completed': false,
          'is_fully_watched': false,
        },
        'has_test': true,
        'test_id': 'demo-test-1',
        'status': {'completed': false, 'passed': false},
        'module': 'demo-module-1',
      },
      {
        'id': 'demo-lesson-1-2',
        'title': '1.2-dars (Demo)',
        'order': 2,
        'video_file': demoVideoUrl,
        'video_url': null,
        'content': 'Bozor iqtisodiyoti tamoyillari',
        'progress': {
          'last_position': 0,
          'max_position': 0,
          'is_completed': false,
          'is_fully_watched': false,
        },
        'has_test': false,
        'test_id': null,
        'status': {'completed': false, 'passed': false},
        'module': 'demo-module-1',
      },
    ],
    'demo-module-2': [
      {
        'id': 'demo-lesson-2-1',
        'title': '2.1-dars (Demo)',
        'order': 1,
        'video_file': demoVideoUrl,
        'video_url': null,
        'content': 'Talab qonuni',
        'progress': {
          'last_position': 0,
          'max_position': 0,
          'is_completed': false,
          'is_fully_watched': false,
        },
        'has_test': true,
        'test_id': 'demo-test-2',
        'status': {'completed': false, 'passed': false},
        'module': 'demo-module-2',
      },
    ],
  };

  static final Map<String, List<Map<String, dynamic>>> _testsByModule = {
    'demo-module-1': [
      {
        'id': 'demo-test-1',
        'title': '1.1-dars uchun test (Demo)',
        'questions': _demoQuestions,
      },
    ],
    'demo-module-2': [
      {
        'id': 'demo-test-2',
        'title': '2.1-dars uchun test (Demo)',
        'questions': _demoQuestions,
      },
    ],
  };

  static final List<Map<String, dynamic>> _demoQuestions = [
    {
      'id': 'q-1',
      'text': 'Iqtisodiyot fani nimani o\'rganadi?',
      'options': [
        {'id': 'opt-1-a', 'text': 'Faqat pul muomalasini'},
        {'id': 'opt-1-b', 'text': 'Cheklangan resurslardan samarali foydalanishni'},
        {'id': 'opt-1-c', 'text': 'Faqat savdo operatsiyalarini'},
        {'id': 'opt-1-d', 'text': 'Tabiat hodisalarini'},
      ],
    },
    {
      'id': 'q-2',
      'text': 'Talab qonuniga ko\'ra:',
      'options': [
        {'id': 'opt-2-a', 'text': 'Narx oshsa, talab kamayadi'},
        {'id': 'opt-2-b', 'text': 'Narx oshsa, talab oshadi'},
        {'id': 'opt-2-c', 'text': 'Narx va talab bog\'liq emas'},
        {'id': 'opt-2-d', 'text': 'Talab faqat reklamaga bog\'liq'},
      ],
    },
    {
      'id': 'q-3',
      'text': 'Inflyatsiya nima?',
      'options': [
        {'id': 'opt-3-a', 'text': 'Narxlar darajasining umumiy pasayishi'},
        {'id': 'opt-3-b', 'text': 'Narxlar darajasining umumiy o\'sishi'},
        {'id': 'opt-3-c', 'text': 'Ish haqining oshishi'},
        {'id': 'opt-3-d', 'text': 'Bank foiz stavkasi'},
      ],
    },
  ];

  static final List<Map<String, dynamic>> _certificates = [];

  static final List<Map<String, dynamic>> _payments = [];
}
