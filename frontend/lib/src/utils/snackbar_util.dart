import 'package:flutter/material.dart';

enum SnackBarType { success, error, info }

void showCustomSnackBar(
  BuildContext context,
  String message, {
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final color = switch (type) {
    SnackBarType.success => Colors.green,
    SnackBarType.error => Colors.red,
    SnackBarType.info => Colors.blueGrey,
  };

  final icon = switch (type) {
    SnackBarType.success => Icons.check_circle_outline,
    SnackBarType.error => Icons.warning_amber_rounded,
    SnackBarType.info => Icons.info_outline,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}
