import '../../core/di/service_locator.dart';
import '../../core/utils/usecase.dart';
import '../../features/courses/domain/entities/course.dart' as domain;

class CourseCategory {
  CourseCategory({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
  });

  final String id;
  final String title;
  final String slug;
  final String description;

  factory CourseCategory.fromDomain(domain.CourseCategory c) => CourseCategory(
        id: c.id,
        title: c.title,
        slug: c.slug,
        description: c.description,
      );
}

class CourseAuthor {
  CourseAuthor({required this.id, required this.firstName});
  final String id;
  final String firstName;

  factory CourseAuthor.fromDomain(domain.CourseAuthor a) =>
      CourseAuthor(id: a.id, firstName: a.firstName);
}

class CourseEnrollment {
  CourseEnrollment({
    required this.id,
    required this.isPaid,
    required this.paymentDate,
  });

  final String id;
  final bool isPaid;
  final String paymentDate;

  factory CourseEnrollment.fromDomain(domain.CourseEnrollment e) =>
      CourseEnrollment(
        id: e.id,
        isPaid: e.isPaid,
        paymentDate: e.paymentDate,
      );
}

class Course {
  Course({
    required this.id,
    required this.title,
    required this.slug,
    required this.image,
    required this.description,
    required this.subject,
    required this.category,
    required this.author,
    required this.isPaid,
    required this.price,
    required this.currency,
    required this.progress,
    required this.isPublished,
    required this.modulesCount,
    required this.enrollment,
  });

  final String id;
  final String title;
  final String slug;
  final String image;
  final String description;
  final String subject;
  final CourseCategory? category;
  final CourseAuthor? author;
  final bool isPaid;
  final String price;
  final String currency;
  final int progress;
  final bool isPublished;
  final int modulesCount;
  final CourseEnrollment? enrollment;

  factory Course.fromDomain(domain.Course c) => Course(
        id: c.id,
        title: c.title,
        slug: c.slug,
        image: c.image,
        description: c.description,
        subject: c.subject,
        category:
            c.category == null ? null : CourseCategory.fromDomain(c.category!),
        author: c.author == null ? null : CourseAuthor.fromDomain(c.author!),
        isPaid: c.isPaid,
        price: c.price,
        currency: c.currency,
        progress: c.progress,
        isPublished: c.isPublished,
        modulesCount: c.modulesCount,
        enrollment: c.enrollment == null
            ? null
            : CourseEnrollment.fromDomain(c.enrollment!),
      );
}

class CourseService {
  Future<List<Course>> fetchCourses(String token) async {
    final result = await ServiceLocator.getCourses(const NoParams());
    return result.when(
      success: (list) => list.map(Course.fromDomain).toList(),
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Course> fetchCourseDetail(String token, String id) async {
    final result = await ServiceLocator.getCourseDetail(id);
    return result.when(
      success: Course.fromDomain,
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<void> startCourse(String token, String id) async {
    final result = await ServiceLocator.startCourse(id);
    return result.when(
      success: (_) {},
      failure: (f) => throw Exception(f.message),
    );
  }

  Future<Map<String, dynamic>> fetchCourseProgress(
    String token,
    String id,
  ) async {
    final result = await ServiceLocator.getCourseProgress(id);
    return result.when(
      success: (data) => data,
      failure: (f) => throw Exception(f.message),
    );
  }
}
