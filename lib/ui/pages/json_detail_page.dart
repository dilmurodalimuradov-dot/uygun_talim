import 'dart:convert';
import 'package:flutter/material.dart';

class JsonDetailPage extends StatelessWidget {
  const JsonDetailPage({
    super.key,
    required this.title,
    required this.data,
  });

  final String title;
  final Map<String, dynamic> data;

  static const Color _surfaceTint = Color(0xFFF8FAFC);
  static const Color _stroke = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final formattedJson = const JsonEncoder.withIndent('  ').convert(data);

    return Scaffold(
      backgroundColor: _surfaceTint,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _textPrimary),
        title: Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
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
              border: Border.all(color: _stroke),
              boxShadow: [
                BoxShadow(
                  color: _textPrimary.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                formattedJson,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 13,
                  color: _textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}