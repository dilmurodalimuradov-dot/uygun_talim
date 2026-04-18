import '../../../../core/utils/json_parser.dart';
import '../../domain/entities/course.dart';

class CourseCategoryModel extends CourseCategory {
  const CourseCategoryModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.description,
  });

  factory CourseCategoryModel.fromJson(Map<String, dynamic> json) {
    return CourseCategoryModel(
      id: JsonParser.parseString(json['id']),
      title: JsonParser.parseString(json['title']),
      slug: JsonParser.parseString(json['slug']),
      description: JsonParser.parseString(json['description']),
    );
  }
}

class CourseAuthorModel extends CourseAuthor {
  const CourseAuthorModel({required super.id, required super.firstName});

  factory CourseAuthorModel.fromJson(Map<String, dynamic> json) {
    return CourseAuthorModel(
      id: JsonParser.parseString(json['id']),
      firstName: JsonParser.parseString(json['first_name']),
    );
  }
}

class CourseEnrollmentModel extends CourseEnrollment {
  const CourseEnrollmentModel({
    required super.id,
    required super.isPaid,
    required super.paymentDate,
  });

  factory CourseEnrollmentModel.fromJson(Map<String, dynamic> json) {
    return CourseEnrollmentModel(
      id: JsonParser.parseString(json['id']),
      isPaid: JsonParser.parseBool(json['is_paid']),
      paymentDate: JsonParser.parseString(json['payment_date']),
    );
  }
}

class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.image,
    required super.description,
    required super.subject,
    required super.category,
    required super.author,
    required super.isPaid,
    required super.price,
    required super.currency,
    required super.progress,
    required super.isPublished,
    required super.modulesCount,
    required super.enrollment,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'];
    final authorRaw = json['author'];
    final enrollmentRaw = json['enrollment'];

    return CourseModel(
      id: JsonParser.parseString(json['id']),
      title: JsonParser.parseString(json['title']),
      slug: JsonParser.parseString(json['slug']),
      image: JsonParser.parseString(json['image']),
      description: JsonParser.parseString(json['description']),
      subject: JsonParser.parseString(json['subject']),
      category: categoryRaw is Map<String, dynamic>
          ? CourseCategoryModel.fromJson(categoryRaw)
          : null,
      author: authorRaw is Map<String, dynamic>
          ? CourseAuthorModel.fromJson(authorRaw)
          : null,
      isPaid: JsonParser.parseBool(json['is_paid']),
      price: JsonParser.parseString(json['price']),
      currency: JsonParser.parseString(json['currency']),
      progress: JsonParser.parseInt(json['progress']),
      isPublished: JsonParser.parseBool(json['is_published']),
      modulesCount: JsonParser.parseInt(json['modules_count']),
      enrollment: enrollmentRaw is Map<String, dynamic>
          ? CourseEnrollmentModel.fromJson(enrollmentRaw)
          : null,
    );
  }
}
