import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/features/orders/data/order_repository.dart';
import 'package:xillafit_flutter/screens/order_tracking_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';

class OrderHistoryScreen extends ConsumerWidget {
  static const routeName = '/order-history';

  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'My Orders',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your orders.\n$error',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
          ),
        ),
        data: (orders) {
          final totalSpent = orders.fold<double>(0, (sum, item) => sum + item.grandTotal);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(orderHistoryProvider.future),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'Total orders',
                        value: '${orders.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Total spent',
                        value: formatOrderMoney(totalSpent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (orders.isEmpty)
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 34),
                          const SizedBox(height: 10),
                          Text(
                            'No orders yet',
                            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your approved and paid orders will show here.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final order in orders) ...[
                  _OrderHistoryTile(order: order),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading.copyWith(fontSize: 24),
          ),
        ],
      ),
    );
  }
}

class _OrderHistoryTile extends StatelessWidget {
  const _OrderHistoryTile({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return AppCard(
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
                      '#${order.referenceNo}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placed ${formatOrderDate(order.orderDate ?? order.createdAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              _StatusPill(label: _labelForStatus(order.orderStatus)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoBlock(
                  label: 'Payment',
                  value: _labelForPayment(order.paymentStatus),
                ),
              ),
              Expanded(
                child: _InfoBlock(
                  label: 'Delivery',
                  value: _labelForDelivery(order.deliveryOption),
                ),
              ),
              Expanded(
                child: _InfoBlock(
                  label: 'Total',
                  value: formatOrderMoney(order.grandTotal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(
                context,
                OrderTrackingScreen.routeName,
                arguments: OrderTrackingArgs(orderId: order.id),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.text,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Track Order'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.goldDark,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _labelForStatus(String value) {
  switch (value) {
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

String _labelForPayment(String value) {
  switch (value) {
    case 'fully_paid':
    case 'paid':
      return 'Paid';
    case 'partially_paid':
      return 'Half paid';
    case 'processing':
      return 'Processing';
    case 'failed':
      return 'Failed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Unpaid';
  }
}

String _labelForDelivery(String? value) {
  if (value == 'pickup') return 'Pick up';
  if (value == 'delivery') return 'Delivery';
  return 'Standard';
}
