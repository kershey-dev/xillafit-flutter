import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xillafit_flutter/features/orders/data/order_repository.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';
import 'package:xillafit_flutter/widgets/common/progress_bar_x.dart';
import 'package:xillafit_flutter/widgets/common/tracking_stepper.dart';

class OrderTrackingArgs {
  const OrderTrackingArgs({required this.orderId});

  final String orderId;
}

class OrderTrackingScreen extends ConsumerWidget {
  static const routeName = '/order-tracking';

  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final orderId = args is OrderTrackingArgs ? args.orderId : null;

    if (orderId == null) {
      return const Scaffold(
        body: Center(child: Text('No order selected.')),
      );
    }

    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Order Tracking',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load this order.\n$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
        ),
        data: (order) => _OrderTrackingBody(order: order),
      ),
    );
  }
}

class _OrderTrackingBody extends ConsumerStatefulWidget {
  const _OrderTrackingBody({required this.order});

  final OrderDetail order;

  @override
  ConsumerState<_OrderTrackingBody> createState() => _OrderTrackingBodyState();
}

class _OrderTrackingBodyState extends ConsumerState<_OrderTrackingBody> {
  bool _openingBalance = false;

  Future<void> _payRemainingBalance() async {
    setState(() => _openingBalance = true);
    try {
      final result = await ref
          .read(orderRepositoryProvider)
          .createBalanceCheckoutSession(widget.order.summary.id);
      await launchUrl(
        Uri.parse(result.checkoutUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _openingBalance = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final summary = order.summary;
    final stepIndex = _stepIndexForStatus(summary.orderStatus);
    final progressValue = (stepIndex + 1) / _trackingSteps.length;

    return RefreshIndicator(
      onRefresh: () async {
        await ref.refresh(orderDetailProvider(summary.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${summary.referenceNo}',
                            style: AppTextStyles.heading.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed ${formatOrderDateTime(summary.orderDate ?? summary.createdAt)}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4DE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _trackingStatusLabel(summary.orderStatus),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.goldDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TopInfo(
                        label: 'Total',
                        value: formatOrderMoney(summary.grandTotal),
                      ),
                    ),
                    Expanded(
                      child: _TopInfo(
                        label: 'Payment',
                        value: _trackingPaymentLabel(summary.paymentStatus),
                      ),
                    ),
                    Expanded(
                      child: _TopInfo(
                        label: 'Target',
                        value: formatOrderDate(summary.expectedCompletionDate),
                      ),
                    ),
                  ],
                ),
                if (summary.paymentStatus == 'partially_paid') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF5D28C)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining balance needed',
                          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatOrderMoney(summary.grandTotal * 0.5),
                          style: AppTextStyles.heading.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _openingBalance ? null : _payRemainingBalance,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.text,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              _openingBalance ? 'Opening checkout...' : 'Pay Remaining Balance',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Operational journey', style: AppTextStyles.heading),
                const SizedBox(height: 14),
                TrackingStepper(
                  steps: [
                    for (var i = 0; i < _trackingSteps.length; i++)
                      TrackingStepData(
                        label: _trackingSteps[i],
                        done: i < stepIndex,
                        active: i == stepIndex,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Progress', style: AppTextStyles.caption),
                    Text(
                      '${(progressValue * 100).round()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ProgressBarX(value: progressValue),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order items', style: AppTextStyles.heading),
                const SizedBox(height: 14),
                if (order.items.isEmpty)
                  Text('No items found for this order.', style: AppTextStyles.caption),
                for (final item in order.items) ...[
                  _OrderItemTile(item: item),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Audit trail', style: AppTextStyles.heading),
                const SizedBox(height: 14),
                if (order.tracking.isEmpty)
                  Text('No tracking updates yet.', style: AppTextStyles.caption),
                for (final event in order.tracking) ...[
                  _TrackingEventTile(event: event),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopInfo extends StatelessWidget {
  const _TopInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58,
          height: 58,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: (item.previewImageUrl ?? '').isNotEmpty
              ? Image.network(
                  item.previewImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.checkroom_rounded),
                )
              : const Icon(Icons.checkroom_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? 'Custom Apparel',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.categoryName ?? 'Apparel'} • Qty ${item.quantity}${(item.size ?? '').isNotEmpty ? ' • Size ${item.size}' : ''}',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        Text(
          formatOrderMoney(item.subtotal),
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _TrackingEventTile extends StatelessWidget {
  const _TrackingEventTile({required this.event});

  final OrderTrackingEvent event;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _trackingStatusLabel(event.status),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                formatOrderDateTime(event.createdAt),
                style: AppTextStyles.caption,
              ),
              if ((event.remarks ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(event.remarks!, style: AppTextStyles.body.copyWith(fontSize: 13)),
              ],
              if ((event.staffName ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  'Updated by ${event.staffName}',
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

const _trackingSteps = <String>[
  'Order Placed',
  'Confirmed',
  'Processing',
  'In Production',
  'Quality Check',
  'Shipped',
  'Delivered',
];

int _stepIndexForStatus(String status) {
  switch (status) {
    case 'approved':
      return 1;
    case 'processing':
      return 2;
    case 'in_production':
      return 3;
    case 'ready_for_pickup':
      return 4;
    case 'out_for_delivery':
      return 5;
    case 'completed':
      return 6;
    default:
      return 0;
  }
}

String _trackingStatusLabel(String status) {
  switch (status) {
    case 'approved':
      return 'Approved';
    case 'processing':
      return 'Processing';
    case 'in_production':
      return 'In Production';
    case 'ready_for_pickup':
      return 'Ready for Pickup';
    case 'out_for_delivery':
      return 'Out for Delivery';
    case 'completed':
      return 'Completed';
    case 'rejected':
      return 'Rejected';
    case 'returned':
      return 'Returned';
    default:
      return 'Pending';
  }
}

String _trackingPaymentLabel(String status) {
  switch (status) {
    case 'partially_paid':
      return 'Half paid';
    case 'paid':
      return 'Paid';
    case 'processing':
      return 'Processing';
    default:
      return 'Unpaid';
  }
}
