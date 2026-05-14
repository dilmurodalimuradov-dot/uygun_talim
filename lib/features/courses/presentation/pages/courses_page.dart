import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Qo'shildi
import '../../../../core/l10n/app_strings.dart'; // Qo'shildi
import '../../../../core/providers/locale_provider.dart'; // Qo'shildi
import '../../../../core/utils/url_helper.dart';
import '../../../../shared/legacy/course_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import 'course_detail_page.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> with TickerProviderStateMixin {
  final CourseService _courseService = CourseService();
  final TokenStorageService _tokenStorageService = TokenStorageService();

  static const Color _pageBackground = Color(0xFFF5F7FA);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _stroke = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _brand = Color(0xFF57A57C);
  static const Color _brandDark = Color(0xFF3D8B67);
  static const Color _brandSoft = Color(0xFFE8F3EE);
  static const Color _brandLight = Color(0xFFD1E9DD);

  bool _isLoading = false;
  String? _errorMessage;
  List<Course> _courses = [];
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);

    // Kontekst tayyor bo'lishi bilan darslarni yuklash
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCourses());
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _courses = [];
    });

    // Tilga mos stringlarni olish uchun vaqtinchalik 's'
    final s = AppStrings.forCode(context.read<LocaleProvider>().locale.languageCode);

    try {
      final token = await _tokenStorageService.readAccessToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = s.coursesTokenNotFound;
            _isLoading = false;
          });
        }
        return;
      }

      final courses = await _courseService.fetchCourses(token).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(s.coursesTimeout);
        },
      );

      if (!mounted) return;

      setState(() {
        _courses = courses;
        _isLoading = false;
        _errorMessage = null;
      });

    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _errorMessage = s.coursesTimeout;
        _isLoading = false;
        _courses = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '${s.coursesLoadError}: ${e.toString()}';
        _isLoading = false;
        _courses = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Matnlarni lug'atdan olish va til o'zgarganda rebuild bo'lish
    final s = AppStrings.of(context);
    context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _pageBackground,
              _pageBackground.withValues(alpha: 0.95),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(s), // 's' uzatildi
              Expanded(
                child: RefreshIndicator(
                  color: _brandDark,
                  backgroundColor: Colors.white,
                  onRefresh: _loadCourses,
                  child: _buildBody(s), // 's' uzatildi
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _stroke.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: _textPrimary.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _brand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: _brand,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.coursesTitle, // 'Kurslar'
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.coursesSubtitle, // 'Barcha kurslar'
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _brandSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${_courses.length} ta',
                style: const TextStyle(
                  color: _brandDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppStrings s) {
    if (_isLoading) {
      return _buildShimmerLoading();
    }

    if (_errorMessage != null) {
      return _buildErrorView(s); // 's' uzatildi
    }

    if (_courses.isEmpty) {
      return _buildEmptyView(s); // 's' uzatildi
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width >= 760) {
          final crossAxisCount = width >= 1120 ? 3 : 2;
          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: _courses.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 400,
            ),
            itemBuilder: (context, index) => _buildCourseCard(_courses[index], s),
          );
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: _courses.length,
          itemBuilder: (context, index) => _buildCourseCard(_courses[index], s),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _stroke),
            boxShadow: [
              BoxShadow(
                color: _textPrimary.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: _stroke.withOpacity(0.5),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _stroke.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 150,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _stroke.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorView(AppStrings s) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _stroke),
          boxShadow: [
            BoxShadow(
              color: _textPrimary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              onPressed: _loadCourses,
              label: s.retry, // 'Qayta urinish'
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(AppStrings s) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _stroke),
          boxShadow: [
            BoxShadow(
              color: _textPrimary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _brandSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: _brand,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.coursesNotFound, // 'Kurslar topilmadi'
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
  }) {
    return Material(
      color: _brand,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Course course, AppStrings s) {
    final imageUrl = _normalizeImageUrl(course.image);
    final price = _priceText(course, s);
    final categoryTitle = (course.category?.title ?? '').trim();
    final subject = course.subject.trim();
    final authorName = (course.author?.firstName ?? '')
        .replaceAll('null', '')
        .trim();
    final isPurchased = course.enrollment?.isPaid == true;

    return Material(
        color: Colors.transparent,
        child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openCourse(course),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _stroke),
                boxShadow: [
                  BoxShadow(
                    color: _textPrimary.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourseImage(
                    url: imageUrl,
                    categoryTitle: categoryTitle,
                    subject: subject,
                    fallbackLabel: s.coursesTitle, // 'Kurs' o'rniga
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: _textPrimary,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (authorName.isNotEmpty)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _brandSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: _brand,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authorName,
                                  style: const TextStyle(
                                    color: _textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _brandSoft,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                price,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _brandDark,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (isPurchased)
                              _buildStatusPill(
                                s.coursesPurchased, // 'Sotib olingan'
                                _brandDark,
                                Icons.check_circle_outline,
                              )
                            else
                              _buildCartAction(),
                          ],
                        ),
                        if (isPurchased) ...[
                          const SizedBox(height: 16),
                          _buildOpenButton(course, s), // 's' uzatildi
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }

  Widget _buildCourseImage({
    required String url,
    required String categoryTitle,
    required String subject,
    required String fallbackLabel,
  }) {
    final imageBadge = subject.isNotEmpty
        ? subject
        : (categoryTitle.isNotEmpty ? categoryTitle : fallbackLabel);
    return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _brandSoft,
                  _brandLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _brand,
                        ),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Icon(
                      Icons.menu_book_rounded,
                      color: _brand.withOpacity(0.5),
                      size: 40,
                    ),
                  )
                else
                  Icon(
                    Icons.menu_book_rounded,
                    color: _brand.withOpacity(0.5),
                    size: 40,
                  ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      imageBadge.toLowerCase(),
                      style: const TextStyle(
                        color: _brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildOpenButton(Course course, AppStrings s) {
    return Material(
        color: _brand,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openCourse(course),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  s.coursesStart, // 'Kursni boshlash'
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildCartAction() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_brand, _brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _brand.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.shopping_cart_outlined,
        size: 20,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _openCourse(Course course) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            CourseDetailPage(course: course),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  String _normalizeImageUrl(String url) => UrlHelper.normalizeMediaUrl(url);

  String _priceText(Course course, AppStrings s) {
    if (!course.isPaid) return s.coursesFree; // 'Bepul'
    final price = course.price.isNotEmpty ? course.price : '0';
    final currency = course.currency.isNotEmpty ? course.currency : 'UZS';
    return '$price $currency'.trim();
  }
}