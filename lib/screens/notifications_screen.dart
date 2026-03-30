import 'package:flutter/material.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';
  final bool showScaffold;

  const NotificationsScreen({super.key, this.showScaffold = true});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final body = ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
      children: [
        Text(
          'NOTIFICATIONS',
          style: AppTextStyles.title.copyWith(fontSize: 24, letterSpacing: 1.0),
        ),
        const SizedBox(height: 20),
        Text(
          'Today',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
        ),
        const SizedBox(height: 10),
        const _NotifTile(
          icon: Icons.factory_outlined,
          title: 'Order In Production',
          body: 'Your order #XF-2024-00847 is now in production.',
          time: '2 hours ago',
          unread: true,
        ),
        const _NotifTile(
          icon: Icons.payments_outlined,
          title: 'Payment Confirmed',
          body: 'We received your payment successfully.',
          time: 'Yesterday',
        ),
        const SizedBox(height: 16),
        Text(
          'Earlier',
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
        ),
        const SizedBox(height: 10),
        const _NotifTile(
          icon: Icons.draw_outlined,
          title: 'Design Revision Available',
          body: 'Our team made revisions to your jersey design.',
          time: 'Mar 3',
        ),
      ],
    );

    if (!showScaffold) return body;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        bottom: true,
        child: body,
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final bool unread;
  const _NotifTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.unread = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0x1AC9902A),
              child: Icon(icon, size: 16, color: AppColors.goldDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(body, style: AppTextStyles.caption),
                  const SizedBox(height: 2),
                  Text(time, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (unread) const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.circle, size: 8, color: AppColors.gold),
            ),
          ],
        ),
      ),
    );
  }
}
