import 'package:flutter/material.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';
import 'package:xillafit_flutter/widgets/common/progress_bar_x.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';
import 'package:xillafit_flutter/widgets/common/search_bar_widget.dart';
import 'package:xillafit_flutter/widgets/common/tracking_stepper.dart';

class OrderTrackingScreen extends StatelessWidget {
  static const routeName = '/order-tracking';

  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SearchBarWidget(hint: 'Search order ID'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ORDER #XF-2024-00847', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text('Classic Brand T-Shirt + Jersey Set', style: AppTextStyles.productName.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text('Placed March 2, 2024 · 27 items total', style: AppTextStyles.caption),
                  const SizedBox(height: 16),
                  const TrackingStepper(
                    steps: [
                      TrackingStepData(label: 'Order Placed', done: true),
                      TrackingStepData(label: 'Payment', done: true),
                      TrackingStepData(label: 'Design', done: true),
                      TrackingStepData(label: 'Production', active: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Production Progress', style: AppTextStyles.caption),
                      Text('65%', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, color: AppColors.goldDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const ProgressBarX(value: 0.65),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rate Your Experience', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  const Text('★★★★★', style: TextStyle(color: AppColors.gold, fontSize: 22)),
                  const SizedBox(height: 8),
                  const SearchBarWidget(hint: 'Tell us about your experience'),
                  const SizedBox(height: 8),
                  const PrimaryButton(text: 'Submit Feedback'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
