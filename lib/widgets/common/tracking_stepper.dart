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
    return Row(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: step.done
                                ? AppColors.success
                                : step.active
                                    ? AppColors.gold
                                    : Colors.white,
                            border: Border.all(
                              color: (step.done || step.active) ? Colors.transparent : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              step.done ? '✓' : '',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      height: 1.5,
                      width: 30,
                      color: step.done ? AppColors.success : AppColors.border,
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(step.label, textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(fontSize: 9, fontWeight: FontWeight.w500)),
              if (step.date != null)
                Text(step.date!, style: AppTextStyles.caption.copyWith(fontSize: 8)),
            ],
          ),
        );
      }),
    );
  }
}
