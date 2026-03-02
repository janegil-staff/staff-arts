import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Upload — coming soon',
        style: TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}