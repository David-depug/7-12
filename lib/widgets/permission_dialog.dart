import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PermissionDialog extends StatelessWidget {
  final VoidCallback? onGranted;
  final VoidCallback? onDenied;

  const PermissionDialog({
    Key? key,
    this.onGranted,
    this.onDenied,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Permissions Required',
        style: TextStyle(color: Colors.black),
      ),
      content: const Text(
        'This app needs permission to block other apps and show notifications. Please grant the required permissions to use the focus blocking feature.',
        style: TextStyle(color: Colors.grey),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDenied?.call();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onGranted?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Grant Permissions'),
        ),
      ],
    );
  }
}









