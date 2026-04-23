import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/network/connectivity_status.dart';
import 'package:xillafit_flutter/core/payments/payment_session_store.dart';
import 'package:xillafit_flutter/features/orders/data/order_repository.dart';
import 'package:xillafit_flutter/screens/main_shell.dart';
import 'package:xillafit_flutter/screens/mobile_webview_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';
import 'package:xillafit_flutter/widgets/common/cached_product_image.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            Navigator.of(context).pushNamedAndRemoveUntil(
              MainShell.routeName,
              (_) => false,
            );
          },
        ),
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
        data: (snapshot) => _OrderTrackingBody(snapshot: snapshot),
      ),
    );
  }
}

class _OrderTrackingBody extends ConsumerStatefulWidget {
  const _OrderTrackingBody({required this.snapshot});

  final OrderDetailSnapshot snapshot;

  @override
  ConsumerState<_OrderTrackingBody> createState() => _OrderTrackingBodyState();
}

class _OrderTrackingBodyState extends ConsumerState<_OrderTrackingBody> {
  Timer? _refreshTimer;
  bool _openingBalance = false;
  bool _waitingForBalanceReturn = false;
  RealtimeChannel? _realtimeChannel;
  bool? _lastOfflineState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _subscribeToOrderUpdates();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshOrderSilently(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _refreshTimer?.cancel();
    final channel = _realtimeChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _OrderTrackingLifecycleObserver(onResume: _refreshOrderSilently);

  void _refreshOrderSilently() {
    if (!mounted) return;
    ref.invalidate(orderDetailProvider(widget.snapshot.order.summary.id));
    ref.invalidate(orderHistoryProvider);
  }

  void _subscribeToOrderUpdates() {
    final orderId = widget.snapshot.order.summary.id;
    final channel = Supabase.instance.client.channel('client-order-$orderId');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (_) => _refreshOrderSilently(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_tracking',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (_) => _refreshOrderSilently(),
        )
        .subscribe();

    _realtimeChannel = channel;
  }

  Future<void> _payRemainingBalance() async {
    setState(() => _openingBalance = true);
    try {
      final result = await ref
          .read(orderRepositoryProvider)
          .createBalanceCheckoutSession(widget.snapshot.order.summary.id);
      if ((result.sessionId ?? '').trim().isNotEmpty) {
        await PaymentSessionStore.save(
          PendingPaymentSession(
            sessionId: result.sessionId!,
            flow: 'balance',
            orderId: widget.snapshot.order.summary.id,
            referenceId: widget.snapshot.order.summary.referenceNo,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _waitingForBalanceReturn = true);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MobileWebViewScreen(
            title: 'Remaining Balance',
            initialUrl: result.checkoutUrl,
            mode: MobileWebViewMode.payment,
          ),
        ),
      );
    } catch (error) {
      await PaymentSessionStore.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingBalance = false;
          _waitingForBalanceReturn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider).asData?.value ?? false;
    _handleConnectivityTransition(isOffline);
    final order = widget.snapshot.order;
    final summary = order.summary;
    final stepIndex = _stepIndexForStatus(summary.orderStatus);
    final progressValue = (stepIndex + 1) / _trackingSteps.length;

    return RefreshIndicator(
      onRefresh: () async {
        _refreshOrderSilently();
        await ref.read(orderDetailProvider(summary.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          if (widget.snapshot.fromCache) ...[
            _OfflineSnapshotCard(
              syncedAt: widget.snapshot.syncedAt,
              message:
                  'Showing the last synced tracking timeline. Updates will refresh when you reconnect.',
            ),
            const SizedBox(height: 12),
          ],
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
                            onPressed: _openingBalance || _waitingForBalanceReturn
                                ? null
                                : _payRemainingBalance,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: AppColors.text,
                              minimumSize: const Size.fromHeight(44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              _openingBalance
                                  ? 'Preparing checkout...'
                                  : _waitingForBalanceReturn
                                      ? 'Waiting for payment confirmation...'
                                      : 'Pay Remaining Balance',
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

  void _handleConnectivityTransition(bool isOffline) {
    final previous = _lastOfflineState;
    if (previous == null) {
      _lastOfflineState = isOffline;
      return;
    }
    if (previous && !isOffline) {
      Future.microtask(_refreshOrderSilently);
    }
    _lastOfflineState = isOffline;
  }
}

class _OfflineSnapshotCard extends StatelessWidget {
  const _OfflineSnapshotCard({
    required this.message,
    this.syncedAt,
  });

  final String message;
  final DateTime? syncedAt;

  @override
  Widget build(BuildContext context) {
    final syncedLabel = syncedAt == null ? null : formatOrderDateTime(syncedAt!.toLocal());
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF5D1A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Offline snapshot',
            style: AppTextStyles.body.copyWith(
              color: AppColors.goldDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.goldDark,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (syncedLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              'Last synced: $syncedLabel',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.goldDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderTrackingLifecycleObserver with WidgetsBindingObserver {
  _OrderTrackingLifecycleObserver({required this.onResume});

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
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
              ? CachedProductImage(
                  imageUrl: item.previewImageUrl,
                  fit: BoxFit.cover,
                  fallback: const Icon(Icons.checkroom_rounded),
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
  'Preparation',
  'Production',
  'Ready for Pickup',
  'Out for Delivery',
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
    case 'fully_paid':
    case 'paid':
      return 'Paid';
    case 'processing':
      return 'Processing';
    default:
      return 'Unpaid';
  }
}
