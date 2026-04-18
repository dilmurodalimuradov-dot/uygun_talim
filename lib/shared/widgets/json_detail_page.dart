import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_colors.dart';

/// JSON'ni chiroyli ko'rsatuvchi utility sahifa.
/// Debug yoki ma'lumot ko'rish uchun.
class JsonDetailPage extends StatelessWidget {
  const JsonDetailPage({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final formattedJson = const JsonEncoder.withIndent('  ').convert(data);

    return Scaffold(
      backgroundColor: AppColors.surfaceTint,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.strokeLight),
            ),
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              formattedJson,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
