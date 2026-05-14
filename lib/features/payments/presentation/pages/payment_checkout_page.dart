import 'package:flutter/material.dart';
import '../../../../shared/theme/app_colors.dart';
import '/core/l10n/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentCheckoutPage extends StatefulWidget {
  const PaymentCheckoutPage({
    super.key,
    required this.paymentUrl,
    this.courseTitle,
  });

  final String paymentUrl;
  final String? courseTitle;

  @override
  State<PaymentCheckoutPage> createState() => _PaymentCheckoutPageState();
}

class _PaymentCheckoutPageState extends State<PaymentCheckoutPage> {
  bool _isLaunching = false;

  Future<void> _openPayme() async {
    if (_isLaunching) return;
    final s = AppStrings.read(context);

    final raw = widget.paymentUrl.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.checkoutBadUrl)),
      );
      return;
    }

    setState(() => _isLaunching = true);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception(s.checkoutPaymeError);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F5F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          s.checkoutTitle,
          style: const TextStyle(
            color: Color(0xFF10233E),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _MerchantCard(
              title: s.checkoutPaymeLabel,
              subtitle: s.checkoutPaymeSubtitle,
              icon: Icons.account_balance_wallet_outlined,
              accent: AppColors.primary,
              onTap: _isLaunching ? null : _openPayme,
              trailing: _isLaunching
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              )
                  : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantCard extends StatelessWidget {
  const _MerchantCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
    this.trailing,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? const Color(0xFFE2E8E6)
                  : const Color(0xFFEDF1F0),
            ),
            boxShadow: enabled
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: enabled ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled
                            ? const Color(0xFF10233E)
                            : const Color(0xFF7D8892),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: enabled
                            ? const Color(0xFF5D6B79)
                            : const Color(0xFF9AA5AE),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    enabled
                        ? Icons.arrow_forward_ios_rounded
                        : Icons.lock_outline_rounded,
                    size: 16,
                    color: enabled
                        ? const Color(0xFF7B8794)
                        : const Color(0xFFB5BDC4),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}