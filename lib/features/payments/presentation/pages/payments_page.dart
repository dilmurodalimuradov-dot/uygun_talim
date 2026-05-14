import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/legacy/course_service_bridge.dart';
import '../../../../shared/legacy/payment_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../../shared/widgets/json_detail_page.dart';
import '../../../../shared/theme/app_colors.dart';
import '/core/l10n/app_strings.dart';
import 'payment_checkout_page.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  static const Color _pageBackground = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: Text(
          s.paymentsTitle,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(30),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: s.paymentsTabMine),
                Tab(text: s.paymentsTabSuccess),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PaymentsList(mode: _PaymentMode.mine),
                _PaymentsList(mode: _PaymentMode.success),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PaymentMode { mine, success }

class _PaymentsList extends StatefulWidget {
  const _PaymentsList({required this.mode});
  final _PaymentMode mode;

  @override
  State<_PaymentsList> createState() => _PaymentsListState();
}

class _PaymentsListState extends State<_PaymentsList> with AutomaticKeepAliveClientMixin {
  final PaymentService _service = PaymentService();
  final CourseService _courseService = CourseService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  bool _isLoading = false;
  bool _isCreating = false;
  String? _errorMessage;
  List<Payment> _items = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        final s = AppStrings.read(context);
        setState(() {
          _errorMessage = s.paymentsTokenNotFound;
          _items = [];
        });
        return;
      }

      final items = widget.mode == _PaymentMode.mine
          ? await _service.fetchMyPayments(token)
          : await _service.fetchSuccessPayments(token);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _items = [];
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openStatus(Payment payment) async {
    final s = AppStrings.read(context);
    try {
      final token = await _tokenStorage.readAccessToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.paymentsTokenNotFound)),
        );
        return;
      }
      final detail = await _service.fetchPaymentStatus(token, payment.id);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JsonDetailPage(title: s.paymentsStatusTitle, data: detail),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _createPayment() async {
    final s = AppStrings.read(context);
    final token = await _tokenStorage.readAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.paymentsTokenNotFound)),
      );
      return;
    }

    setState(() => _isCreating = true);

    List<Course> unpaidCourses = [];
    try {
      final allCourses = await _courseService.fetchCourses(token);
      unpaidCourses = allCourses
          .where(
            (c) => c.isPaid && (c.enrollment == null || !c.enrollment!.isPaid),
      )
          .toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
      setState(() => _isCreating = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (unpaidCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.paymentsNoPendingCourses)),
      );
      return;
    }

    final selectedCourse = await showModalBottomSheet<Course>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CoursePickerSheet(courses: unpaidCourses),
    );
    if (selectedCourse == null || !mounted) return;

    setState(() => _isCreating = true);
    try {
      final paymentUrl = await _service.createPaymentAndGetUrl(
        token,
        selectedCourse.id,
      );
      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentCheckoutPage(
            paymentUrl: paymentUrl,
            courseTitle: selectedCourse.title,
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading && _items.isEmpty) {
      return _buildLoadingView();
    }

    if (_errorMessage != null && _items.isEmpty) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 40,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (widget.mode == _PaymentMode.mine) _buildCreateButton(),
                if (widget.mode == _PaymentMode.mine) const SizedBox(height: 12),
                if (_items.isEmpty) _buildEmptyView(),
                ..._items.map((payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildPaymentCard(payment),
                )),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    final s = AppStrings.read(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.paymentsLoading,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final s = AppStrings.read(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: _load,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        s.retry,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    final s = AppStrings.read(context);
    final isMine = widget.mode == _PaymentMode.mine;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.payments_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isMine ? s.paymentsNotFound : s.paymentsSuccessNotFound,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMine ? s.paymentsNotFoundHint : s.paymentsSuccessNotFoundHint,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final s = AppStrings.read(context);
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: (_isLoading || _isCreating) ? null : _createPayment,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isCreating)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(Icons.add, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                _isCreating ? s.paymentsCreating : s.paymentsCreate,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final s = AppStrings.read(context);
    final amount = payment.amount.isNotEmpty ? payment.amount : '—';
    final currency = payment.currency.isNotEmpty ? payment.currency : 'UZS';
    final isSuccess = payment.status.toLowerCase() == 'success';
    final statusLabel = isSuccess ? s.paymentsStatusSuccess : _localizeStatus(s, payment.status);
    final courseTitle = payment.courseTitle.isNotEmpty
        ? payment.courseTitle
        : s.paymentsCourseFallback;
    final date = _formatDate(
      payment.paidAt.isNotEmpty ? payment.paidAt : payment.createdAt,
    );

    return GestureDetector(
      onTap: () => _openStatus(payment),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openStatus(payment),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? const Color(0xFFE6F4EA)
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSuccess
                              ? Icons.check_circle_rounded
                              : Icons.payments_rounded,
                          size: 20,
                          color: isSuccess
                              ? const Color(0xFF2E7D32)
                              : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              courseTitle,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$amount $currency',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? const Color(0xFFE6F4EA)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSuccess
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _localizeStatus(AppStrings s, String status) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return s.paymentsStatusCancelled;
      case 'waiting':
        return s.paymentsStatusWaiting;
      case 'pending':
        return s.paymentsStatusPending;
      case 'refund':
        return s.paymentsStatusRefund;
      default:
        return status;
    }
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _CoursePickerSheet extends StatelessWidget {
  const _CoursePickerSheet({required this.courses});
  final List<Course> courses;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.paymentsPickCourse,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: courses.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.stroke,
              ),
              itemBuilder: (ctx, i) {
                final c = courses[i];
                final price =
                c.price.isNotEmpty ? '${c.price} ${c.currency}'.trim() : '';
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(ctx).pop(c),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (price.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    price,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}