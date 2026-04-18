import 'dart:convert';

import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showJsonInputDialog({
  required BuildContext context,
  required String title,
  String initialJson = '{}',
}) async {
  final controller = TextEditingController(text: initialJson);
  String? errorText;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              child: TextField(
                controller: controller,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '{"answers":[...]}',
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Bekor qilish'),
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    final decoded = jsonDecode(controller.text);
                    if (decoded is Map<String, dynamic>) {
                      Navigator.of(dialogContext).pop(decoded);
                    } else {
                      setState(() {
                        errorText = 'JSON obyekt bo‘lishi kerak.';
                      });
                    }
                  } catch (_) {
                    setState(() {
                      errorText = 'JSON formatini tekshiring.';
                    });
                  }
                },
                child: const Text('Yuborish'),
              ),
            ],
          );
        },
      );
    },
  );
}
