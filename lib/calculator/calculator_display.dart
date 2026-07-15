import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class CalculatorDisplay extends StatelessWidget {
  final String expression;
  final String result;

  const CalculatorDisplay({
    super.key,
    required this.expression,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.calcDisplayBg : AppColors.calcDisplayBgLight,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Title "Calculator" — long press on the parent GestureDetector activates bridge mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calculator',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black38,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Expression
          Text(
            expression,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black38,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          // Result
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              result,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 48,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}