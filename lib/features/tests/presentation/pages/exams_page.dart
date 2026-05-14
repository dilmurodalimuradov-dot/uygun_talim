import 'package:flutter/material.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/utils/usecase.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../widgets/test_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_view.dart';
import 'test_detail_page.dart';
import '../../domain/entities/test_item.dart';
import '../../domain/usecases/test_usecases.dart';
import '../../../../core/di/service_locator.dart';

class ExamsPage extends StatefulWidget {
  const ExamsPage({super.key});

  @override
  State<ExamsPage> createState() => _ExamsPageState();
}

class _ExamsPageState extends State<ExamsPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const Color _pageBackground = Color(0xFFF5F7FA);

  bool _isLoading = false;
  String? _errorMessage;
  List<TestItem> _tests = [];
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);
    _loadTests();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadTests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ServiceLocator.getTests.call(const NoParams());

    if (!mounted) return;

    result.when(
      success: (tests) {
        setState(() {
          _tests = tests;
          _errorMessage = null;
          _isLoading = false;
        });
      },
      failure: (failure) {
        setState(() {
          _errorMessage = _getErrorMessage(failure);
          _tests = [];
          _isLoading = false;
        });
      },
    );
  }

  String _getErrorMessage(dynamic failure) {
    final s = AppStrings.of(context);
    if (failure is ServerFailure) return 'Server xatosi: ${failure.message}';
    if (failure is NetworkFailure) return 'Internet aloqasi yo\'q';
    if (failure is TimeoutFailure) return 'So\'rov vaqti tugadi';
    if (failure is UnauthorizedFailure) return s.examsTokenNotFound;
    if (failure is CacheFailure) return 'Kesh xatosi';
    return 'Xatolik yuz berdi: ${failure.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(s),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _loadTests,
                child: _buildBody(s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppStrings s) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.quiz_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.examsTitle,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tests.isEmpty
                      ? '0 ta test'
                      : '${_tests.length} ta test',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppStrings s) {
    if (_isLoading) {
      return ShimmerLoading(shimmerController: _shimmerController);
    }

    if (_errorMessage != null) {
      return ErrorView(
        errorMessage: _errorMessage!,
        onRetry: _loadTests,
      );
    }

    if (_tests.isEmpty) {
      return const EmptyView();
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _tests.length,
      itemBuilder: (context, index) => TestCard(
        test: _tests[index],
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  TestDetailPage(test: _tests[index]),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        },
      ),
    );
  }
}