import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_radius.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: border ?? Border.all(color: const Color(0x0A000000), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}
