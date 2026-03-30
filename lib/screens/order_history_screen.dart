import 'package:flutter/material.dart';
import 'package:xillafit_flutter/screens/order_tracking_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';
import 'package:xillafit_flutter/widgets/common/badge.dart';
import 'package:xillafit_flutter/widgets/common/dark_button.dart';

class OrderHistoryScreen extends StatelessWidget {
  static const routeName = '/order-history';

  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('#XF-2024-00847', 'T-Shirt + Jersey Set · Mar 2, 2024', BadgeType.blue, 'In Production', '₱12,380', true),
      ('#XF-2024-00831', 'Volleyball Jerseys (×20) · Feb 18', BadgeType.green, 'Completed', '₱9,600', false),
      ('#XF-2024-00809', 'Corporate Polo (×30) · Jan 25', BadgeType.green, 'Completed', '₱15,600', false),
      ('#XF-2023-00776', 'Basketball Jerseys (×15) · Dec 10', BadgeType.gray, 'Completed', '₱7,200', false),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ORDER HISTORY', style: AppTextStyles.title.copyWith(fontSize: 26)),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: rows
                    .map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.$1, style: AppTextStyles.productName.copyWith(fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text(r.$2, style: AppTextStyles.caption),
                                  const SizedBox(height: 5),
                                  StatusBadge(text: r.$4, type: r.$3),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(r.$5, style: AppTextStyles.price.copyWith(fontSize: 22)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 82,
                                  child: DarkButton(
                                    text: r.$6 ? 'Track' : 'Reorder',
                                    compact: true,
                                    onPressed: () {
                                      if (r.$6) {
                                        Navigator.pushNamed(context, OrderTrackingScreen.routeName);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Text('4', style: AppTextStyles.heading.copyWith(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text('Total Orders', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    child: Column(
                      children: [
                        Text('₱44,780', style: AppTextStyles.heading.copyWith(fontSize: 24)),
                        const SizedBox(height: 4),
                        Text('Total Spent', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
