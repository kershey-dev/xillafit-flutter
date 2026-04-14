import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

class TrackingStepData {
  final String label;
  final bool done;
  final bool active;
  final String? date;

  const TrackingStepData({
    required this.label,
    this.done = false,
    this.active = false,
    this.date,
  });
}

class TrackingStepper extends StatelessWidget {
  final List<TrackingStepData> steps;

  const TrackingStepper({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        final circleSize = compact ? 18.0 : 22.0;
        final labelFontSize = compact ? 8.0 : 9.0;
        final dateFontSize = compact ? 7.0 : 8.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;
            final circleColor = step.done
                ? AppColors.success
                : step.active
                    ? AppColors.gold
                    : Colors.white;
            final borderColor =
                (step.done || step.active) ? Colors.transparent : AppColors.border;

            return Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: circleSize,
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: circleColor,
                                border: Border.all(
                                  color: borderColor,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  step.done ? '✓' : '',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontSize: compact ? 9 : 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              height: 1.5,
                              margin: EdgeInsets.only(
                                left: compact ? 4 : 6,
                                right: compact ? 4 : 6,
                              ),
                              color: step.done ? AppColors.success : AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: labelFontSize,
                      height: 1.15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (step.date != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        step.date!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: dateFontSize,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
