import 'package:flutter/material.dart';
import '../../../../shared/legacy/course_service_bridge.dart';
import '../../../../shared/legacy/payment_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../lessons/presentation/pages/lesson_page.dart';
import '../../../payments/presentation/pages/payment_checkout_page.dart';
import '../../../../shared/theme/app_colors.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({super.key, required this.course});

  final Course course;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with WidgetsBindingObserver {
  final CourseService _courseService = CourseService();
  final PaymentService _paymentService = PaymentService();
  final TokenStorageService _tokenStorageService = TokenStorageService();

  bool _isLoading = false;
  bool _isStarting = false;
  bool _isPaying = false;
  bool _shouldRefreshOnResumeAfterPayment = false;
  bool _isResumingRefresh = false;
  String? _errorMessage;
  Course? _course;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _course = widget.course;
    _loadDetail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_shouldRefreshOnResumeAfterPayment || _isResumingRefresh) return;

    _shouldRefreshOnResumeAfterPayment = false;
    _isResumingRefresh = true;
    _reloadAll().whenComplete(() {
      _isResumingRefresh = false;
    });
  }

  Future<void> _reloadAll() async {
    await _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorageService.readAccessToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Access token topilmadi.';
        });
        return;
      }

      final detail = await _courseService.fetchCourseDetail(token, widget.course.id);
      if (!mounted) return;
      setState(() {
        _course = detail;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Kurs maʼlumotlarini yuklashda xatolik yuz berdi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startCourse(Course course) async {
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
    });

    try {
      final token = await _tokenStorageService.readAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Access token topilmadi.');
      }
      await _courseService.startCourse(token, widget.course.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kurs boshlandi')),
      );
      await _loadDetail();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LessonPage(
            courseId: course.id,
            title: course.title.isNotEmpty ? course.title : 'Darslar',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    }
  }

  Future<void> _buyCourse(Course course) async {
    if (_isPaying) return;
    setState(() {
      _isPaying = true;
    });

    try {
      final token = await _tokenStorageService.readAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Access token topilmadi.');
      }

      final response = await _paymentService.createPayment(token, {
        'course_id': course.id,
      });

      final paymentUrl = _extractPaymentUrl(response);
      if (paymentUrl.isEmpty) {
        throw Exception('To‘lov havolasi kelmadi.');
      }

      if (Uri.tryParse(paymentUrl) == null || paymentUrl.trim().isEmpty) {
        throw Exception('To‘lov havolasi noto‘g‘ri.');
      }

      _shouldRefreshOnResumeAfterPayment = true;
      final opened = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentCheckoutPage(
            paymentUrl: paymentUrl,
            courseTitle: course.title,
          ),
        ),
      );
      if (opened != true) {
        _shouldRefreshOnResumeAfterPayment = false;
      }
    } catch (error) {
      _shouldRefreshOnResumeAfterPayment = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
      }
    }
  }

  Future<void> _handlePrimaryAction(Course course) async {
    if (_isStarting || _isPaying) return;
    final needsPayment = course.isPaid && (course.enrollment?.isPaid != true);
    if (needsPayment) {
      await _buyCourse(course);
      return;
    }
    await _startCourse(course);
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Kurs tafsiloti',
          style: TextStyle(
            color: Color(0xFF10233E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading && course == null
            ? const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              )
            : RefreshIndicator(
                onRefresh: _reloadAll,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (_errorMessage != null) ...[
                      _buildInfoBanner(_errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    if (course != null) ...[
                      _buildDetailCard(course),
                      const SizedBox(height: 14),
                      _buildMetaCard(course),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailCard(Course course) {
    final imageUrl = _normalizeImageUrl(course.image);
    final status = _statusText(course);
    final statusColor = _statusColor(course);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7F70), Color(0xFF0D5C63)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCourseImage(imageUrl, width: double.infinity, radius: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 21,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                if (course.category?.title.isNotEmpty == true)
                  Text(
                    course.category!.title,
                    style: const TextStyle(
                      color: Color(0xFFE5F4F2),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (course.subject.isNotEmpty)
                  Text(
                    'Fan: ${course.subject}',
                    style: const TextStyle(
                      color: Color(0xFFD1ECE8),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusChip(
                    text: status,
                    textColor: statusColor,
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                if (course.description.isNotEmpty)
                  Text(
                    course.description,
                    style: const TextStyle(
                      color: Color(0xFFF2FFFD),
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard(Course course) {
    final price = _priceText(course);
    final showBuyButton = course.isPaid && (course.enrollment?.isPaid != true);
    final isPrimaryLoading = _isStarting || _isPaying;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.payments_outlined,
                  label: 'Narx',
                  value: price,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.insights_outlined,
                  label: 'Progress',
                  value: '${course.progress}%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (showBuyButton)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isPrimaryLoading ? null : () => _startCourse(course),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isStarting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : const Text(
                            'Kursni boshlash',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isPrimaryLoading ? null : () => _buyCourse(course),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isPaying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sotib olish',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPrimaryLoading ? null : () => _startCourse(course),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: isPrimaryLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kursni boshlash',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF10233E),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseImage(
    String url, {
    double width = 96,
    double radius = 14,
  }) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.12),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: url.isEmpty
                ? const Icon(Icons.menu_book_rounded, color: Colors.white)
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip({
    required String text,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text, {bool isError = true}) {
    final color = isError ? const Color(0xFFD14343) : const Color(0xFF2C5B88);
    final backgroundColor = isError
        ? const Color(0xFFFFF3F3)
        : const Color(0xFFF1F6FD);
    final icon = isError ? Icons.error_outline : Icons.info_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _surfaceCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  String _normalizeImageUrl(String url) {
    if (url.startsWith('/')) {
      return 'https://api.uyguntalim.tsue.uz$url';
    }
    if (url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
      return 'https://api.uyguntalim.tsue.uz/$url';
    }
    if (url.startsWith('http://api.uyguntalim.tsue.uz/')) {
      return url.replaceFirst('http://', 'https://');
    }
    return url;
  }

  String _priceText(Course course) {
    if (!course.isPaid) return 'Bepul';
    final price = course.price.isNotEmpty ? course.price : '0';
    final currency = course.currency.isNotEmpty ? course.currency : '';
    return '$price $currency'.trim();
  }

  String _statusText(Course course) {
    final enrollment = course.enrollment;
    if (enrollment == null) return 'Sotib olinmagan';
    return enrollment.isPaid ? "To'langan" : "To'lanmagan";
  }

  Color _statusColor(Course course) {
    final enrollment = course.enrollment;
    if (enrollment == null) return const Color(0xFF9A6A00);
    return enrollment.isPaid ? const Color(0xFF0A7AC2) : const Color(0xFF9A6A00);
  }

  String _extractPaymentUrl(Map<String, dynamic> data) {
    const directKeys = ['url', 'payment_url', 'pay_url', 'checkout_url', 'deeplink'];
    for (final key in directKeys) {
      final value = data[key];
      if (value is String && _looksLikePaymentUrl(value)) {
        return value.trim();
      }
    }

    for (final value in data.values) {
      if (value is String && _looksLikePaymentUrl(value)) {
        return value.trim();
      }
      if (value is Map<String, dynamic>) {
        final nested = _extractPaymentUrl(value);
        if (nested.isNotEmpty) return nested;
      }
    }
    return '';
  }

  bool _looksLikePaymentUrl(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('payme://');
  }
}
