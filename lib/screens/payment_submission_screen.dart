import 'package:flutter/material.dart';
import 'package:xillafit_flutter/screens/order_tracking_screen.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';
import 'package:xillafit_flutter/widgets/common/primary_button.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';

class PaymentSubmissionScreen extends StatelessWidget {
  static const routeName = '/payment-submission';

  const PaymentSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x12C9902A), blurRadius: 20, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  Text('AMOUNT DUE', style: AppTextStyles.caption.copyWith(color: AppColors.muted, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text('₱2,600', style: AppTextStyles.largeTitle.copyWith(color: AppColors.text, fontSize: 46)),
                  const SizedBox(height: 4),
                  Text('Order #XF-2024-00848', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Method', style: AppTextStyles.heading),
                  const SizedBox(height: 10),
                  _MethodTile(icon: '📱', title: 'GCash / Maya', sub: 'Send to: 0917-XXX-XXXX', active: true),
                  const SizedBox(height: 8),
                  _MethodTile(icon: '🏦', title: 'Bank Transfer', sub: 'BDO / BPI / UnionBank'),
                  const SizedBox(height: 8),
                  _MethodTile(icon: '💵', title: 'Cash on Pickup', sub: 'Marilao, Bulacan'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Upload Payment Proof', style: AppTextStyles.heading),
                  const SizedBox(height: 4),
                  Text('Screenshot or photo of your payment receipt', style: AppTextStyles.caption),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x14C9902A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x80C9902A), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text('📎', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text('Tap to upload', style: AppTextStyles.body.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('JPG, PNG, PDF · max 5 MB', style: AppTextStyles.muted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('BEFORE SUBMITTING, CHECK:', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const _CheckRow('Correct amount (₱2,600)', true),
                  const _CheckRow('Recipient number / account visible', true),
                  const _CheckRow('Screenshot is clear and not cropped', false),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    text: 'Submit Payment',
                    onPressed: () => Navigator.pushNamed(context, OrderTrackingScreen.routeName),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String icon;
  final String title;
  final String sub;
  final bool active;
  const _MethodTile({required this.icon, required this.title, required this.sub, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? AppColors.gold : AppColors.border, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: active ? AppColors.goldDark : AppColors.textSecondary,
            size: 20,
          ),
          Text(icon),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w600, fontSize: 13)),
              Text(sub, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String text;
  final bool done;
  const _CheckRow(this.text, this.done);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: done ? AppColors.success : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(done ? '✓' : '', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 13, color: done ? AppColors.text : AppColors.muted)),
        ],
      ),
    );
  }
}
