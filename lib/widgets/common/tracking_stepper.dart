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
        final useVerticalLayout = constraints.maxWidth < 480;
        return useVerticalLayout
            ? _VerticalTrackingStepper(steps: steps)
            : _HorizontalTrackingStepper(steps: steps);
      },
    );
  }
}

class _HorizontalTrackingStepper extends StatelessWidget {
  const _HorizontalTrackingStepper({required this.steps});

  final List<TrackingStepData> steps;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final circleSize = compact ? 18.0 : 22.0;
    final labelFontSize = compact ? 8.0 : 9.0;
    final dateFontSize = compact ? 7.0 : 8.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

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
                            color: _circleColor(step),
                            border: Border.all(
                              color: _borderColor(step),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              step.done ? 'v' : '',
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
  }
}

class _VerticalTrackingStepper extends StatelessWidget {
  const _VerticalTrackingStepper({required this.steps});

  final List<TrackingStepData> steps;
  static const double _railWidth = 28;
  static const double _circleSize = 20;
  static const double _connectorWidth = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _railWidth,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isLast)
                      Positioned(
                        top: _circleSize,
                        bottom: 0,
                        child: Container(
                          width: _connectorWidth,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    if (!isLast && (step.done || step.active))
                      Positioned(
                        top: _circleSize,
                        bottom: 0,
                        child: Container(
                          width: _connectorWidth,
                          decoration: BoxDecoration(
                            color: step.done ? AppColors.success : AppColors.gold,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    Container(
                      width: _circleSize,
                      height: _circleSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _circleColor(step),
                        border: Border.all(
                          color: _borderColor(step),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          step.done ? 'v' : '',
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
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: step.active ? FontWeight.w800 : FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                      if (step.date != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          step.date!,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

Color _circleColor(TrackingStepData step) {
  if (step.done) return AppColors.success;
  if (step.active) return AppColors.gold;
  return Colors.white;
}

Color _borderColor(TrackingStepData step) {
  return (step.done || step.active) ? Colors.transparent : AppColors.border;
}
