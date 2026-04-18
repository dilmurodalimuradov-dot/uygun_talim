/// Pure domain entity'lar. Hech qanday JSON, HTTP, package bog'liqligi yo'q.

class CourseCategory {
  const CourseCategory({
    required this.id,
    required this.title,
    required this.slug,
    required this.description,
  });

  final String id;
  final String title;
  final String slug;
  final String description;
}

class CourseAuthor {
  const CourseAuthor({
    required this.id,
    required this.firstName,
  });

  final String id;
  final String firstName;

  /// `null` so'zini tozalab beradi.
  String get displayName => firstName.replaceAll('null', '').trim();
}

class CourseEnrollment {
  const CourseEnrollment({
    required this.id,
    required this.isPaid,
    required this.paymentDate,
  });

  final String id;
  final bool isPaid;
  final String paymentDate;
}

class Course {
  const Course({
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

  /// Ko'rsatish logikasi entity ichida — UI'da hisoblanmaydi.
  bool get isPurchased => enrollment?.isPaid == true;

  String get priceText {
    if (!isPaid) return 'Bepul';
    final p = price.isNotEmpty ? price : '0';
    final c = currency.isNotEmpty ? currency : 'UZS';
    return '$p $c'.trim();
  }
}
