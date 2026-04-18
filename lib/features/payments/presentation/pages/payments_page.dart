import 'package:flutter/material.dart';
import '../../../../shared/legacy/payment_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../../shared/widgets/json_detail_page.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/json_input_dialog.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: AppColors.secondary,
          title: const Text('To‘lovlar',style: TextStyle(color: Colors.white),),
          bottom: const TabBar(
            dividerColor: Colors.white10,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black,
            tabs: [
              Tab(text: 'Mening'),
              Tab(text: 'Muvaffaqiyatli'),
            ],
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: const SafeArea(
            child: TabBarView(
              children: [
                _PaymentsList(mode: _PaymentMode.mine),
                _PaymentsList(mode: _PaymentMode.success),
              ],
            ),
          ),
        ),
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

class _PaymentsListState extends State<_PaymentsList> {
  final PaymentService _service = PaymentService();
  final TokenStorageService _tokenStorage = TokenStorageService();

  bool _isLoading = false;
  String? _errorMessage;
  List<Payment> _items = [];

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
        setState(() {
          _errorMessage = 'Access token topilmadi.';
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
    try {
      final token = await _tokenStorage.readAccessToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access token topilmadi.')),
        );
        return;
      }
      final detail = await _service.fetchPaymentStatus(token, payment.id);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JsonDetailPage(
            title: 'To‘lov holati',
            data: detail,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _createPayment() async {
    final token = await _tokenStorage.readAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access token topilmadi.')),
      );
      return;
    }

    final payload = await showJsonInputDialog(
      context: context,
      title: 'To‘lov yaratish (JSON)',
    );
    if (payload == null) return;

    try {
      final response = await _service.createPayment(token, payload);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JsonDetailPage(title: 'To‘lov javobi', data: response),
        ),
      );
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildInfoBanner(_errorMessage!),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, child: const Text('Qayta yuklash')),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildCreateButton(),
          const SizedBox(height: 12),
          if (_items.isEmpty) _buildInfoBanner('To‘lovlar topilmadi.'),
          ..._items.map(_buildPaymentCard),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    if (widget.mode != _PaymentMode.mine) {
      return const SizedBox.shrink();
    }
    return ElevatedButton.icon(
      onPressed: _createPayment,
      icon: const Icon(Icons.add),
      label: const Text('To‘lov yaratish'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final amount = payment.amount.isNotEmpty ? payment.amount : '—';
    final currency = payment.currency.isNotEmpty ? payment.currency : '';
    final status = payment.status.isNotEmpty ? payment.status : '—';
    final created = payment.createdAt.isNotEmpty ? payment.createdAt : '—';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          '$amount $currency',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('Status: $status\nSana: $created'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openStatus(payment),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}