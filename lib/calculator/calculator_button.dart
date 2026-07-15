import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

class CalculatorButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final ButtonType type;
  final double? height;

  const CalculatorButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = ButtonType.number,
    this.height,
  });

  @override
  State<CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<CalculatorButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    Color textColor;

    switch (widget.type) {
      case ButtonType.number:
        bgColor = isDark ? AppColors.calcNumberBtn : AppColors.calcNumberBtnLight;
        textColor = isDark ? Colors.white : AppColors.calcNumberTextLight;
        break;
      case ButtonType.operator:
        bgColor = isDark ? AppColors.calcOperatorBtn : AppColors.calcOperatorBtnLight;
        textColor = Colors.white;
        break;
      case ButtonType.function:
        bgColor = AppColors.calcFunctionBtn;
        textColor = Colors.white70;
        break;
      case ButtonType.equals:
        // Will use gradient
        bgColor = Colors.transparent;
        textColor = Colors.white;
        break;
    }

    Widget buttonChild = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        color: widget.type == ButtonType.equals ? null : bgColor,
        borderRadius: BorderRadius.circular(12),
        gradient: widget.type == ButtonType.equals
            ? LinearGradient(
                colors: isDark
                    ? [AppColors.calcEqualsStart, AppColors.calcEqualsEnd]
                    : [AppColors.calcEqualsStartLight, AppColors.calcEqualsEndLight],
              )
            : null,
      ),
      child: Center(
        child: Text(
          widget.label,
          style: TextStyle(
            color: textColor,
            fontSize: widget.label.length > 3 ? 16 : 22,
            fontWeight: widget.type == ButtonType.operator ||
                    widget.type == ButtonType.equals
                ? FontWeight.bold
                : FontWeight.w500,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _scale = 0.95);
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: Transform.scale(
        scale: _scale,
        child: Container(
          height: widget.height,
          margin: const EdgeInsets.all(4),
          child: buttonChild,
        ),
      ),
    );
  }
}

enum ButtonType { number, operator, function, equals }