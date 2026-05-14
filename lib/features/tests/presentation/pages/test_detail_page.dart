import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/json_detail_page.dart';
import '../../../../shared/widgets/json_input_dialog.dart';
import '../../domain/entities/test_item.dart';
import '../../domain/usecases/test_usecases.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/failures.dart';

class TestDetailPage extends StatefulWidget {
  const TestDetailPage({super.key, required this.test});

  final TestItem test;

  @override
  State<TestDetailPage> createState() => _TestDetailPageState();
}

class _TestDetailPageState extends State<TestDetailPage> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ServiceLocator.getTestDetail.call(widget.test.id);

    if (!mounted) return;

    // TUZATILDI: fold metodining to'g'ri ishlatilishi
    result.fold(
      onFailure: (failure) {
        setState(() {
          _errorMessage = _getErrorMessage(failure);
          _isLoading = false;
        });
      },
      onSuccess: (detail) {
        setState(() {
          _detail = detail;
          _errorMessage = null;
          _isLoading = false;
        });
      },
    );
  }

  String _getErrorMessage(dynamic failure) {
    if (failure is ServerFailure) return 'Server xatosi: ${failure.message}';
    if (failure is NetworkFailure) return 'Internet aloqasi yo\'q';
    if (failure is TimeoutFailure) return 'So\'rov vaqti tugadi';
    if (failure is UnauthorizedFailure) return 'Ruxsat yo\'q';
    if (failure is CacheFailure) return 'Kesh xatosi';
    return 'Xatolik yuz berdi: ${failure.toString()}';
  }

  Future<void> _submitTest() async {
    final payload = await showJsonInputDialog(
      context: context,
      title: 'Testni yuborish (JSON)',
    );
    if (payload == null) return;

    final result = await ServiceLocator.submitTest.call(
      SubmitTestParams(id: widget.test.id, payload: payload),
    );

    if (!mounted) return;

    // TUZATILDI: fold metodining to'g'ri ishlatilishi
    result.fold(
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getErrorMessage(failure))),
        );
      },
      onSuccess: (response) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JsonDetailPage(
              title: 'Test javobi',
              data: response,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _detail == null
        ? ''
        : const JsonEncoder.withIndent('  ').convert(_detail);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.test.title.isNotEmpty ? widget.test.title : 'Test'),
        actions: [
          IconButton(
            onPressed: _submitTest,
            icon: const Icon(Icons.send),
            tooltip: 'Testni yuborish',
          ),
        ],
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
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              if (_isLoading)
                const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                )
              else if (_errorMessage != null)
                _buildInfoBanner(_errorMessage!)
              else if (_detail == null)
                  _buildInfoBanner('Maʼlumot topilmadi.')
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),  // TUZATILDI: withOpacity -> withValues
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SelectableText(
                      formatted,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        height: 1.35,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _submitTest,
                icon: const Icon(Icons.send),
                label: const Text('Testni yuborish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),  // TUZATILDI: withOpacity -> withValues
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}