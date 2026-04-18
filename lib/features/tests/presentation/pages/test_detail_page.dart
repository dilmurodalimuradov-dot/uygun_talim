import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../shared/legacy/test_service_bridge.dart';
import '../../../../shared/legacy/token_storage_bridge.dart';
import '../../../../shared/widgets/json_detail_page.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/json_input_dialog.dart';

class TestDetailPage extends StatefulWidget {
  const TestDetailPage({super.key, required this.test});

  final TestItem test;

  @override
  State<TestDetailPage> createState() => _TestDetailPageState();
}

class _TestDetailPageState extends State<TestDetailPage> {
  final TestService _service = TestService();
  final TokenStorageService _tokenStorage = TokenStorageService();

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

    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _errorMessage = 'Access token topilmadi.';
        });
        return;
      }
      final detail = await _service.fetchTest(token, widget.test.id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitTest() async {
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
      title: 'Testni yuborish (JSON)',
    );
    if (payload == null) return;

    try {
      final response = await _service.submitTest(token, widget.test.id, payload);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JsonDetailPage(
            title: 'Test javobi',
            data: response,
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
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
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
