import 'package:flutter/material.dart';
import '/../../core/theme/app_colors.dart';
import '/../../core/theme/app_text_styles.dart';

enum TransactionStatus { selesai, pending, cancelled }

class StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor;
    String label;

    switch (status) {
      case TransactionStatus.selesai:
        bg = AppColors.successContainer;
        textColor = AppColors.successText;
        label = 'SELESAI';
        break;
      case TransactionStatus.pending:
        bg = AppColors.warningContainer;
        textColor = AppColors.warningText;
        label = 'PENDING';
        break;
      case TransactionStatus.cancelled:
        bg = AppColors.errorContainer;
        textColor = AppColors.errorText;
        label = 'DIBATALKAN';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(color: textColor),
      ),
    );
  }
}