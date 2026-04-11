import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/features/notifications/data/notifications_repository.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';
import 'package:xillafit_flutter/widgets/common/app_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  static const routeName = '/notifications';

  const NotificationsScreen({super.key, this.showScaffold = true});

  final bool showScaffold;

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  List<AppNotificationItem> _items = const [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _load();
      _subscribe();
    });
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await ref.read(notificationsRepositoryProvider).fetchMyNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _subscribe() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final channel = Supabase.instance.client
        .channel('client-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'profile_id',
            value: userId,
          ),
          callback: (payload) {
            _load();
          },
        )
        .subscribe();

    _channel = channel;
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationsRepositoryProvider).markAllRead();
    await _load();
  }

  Future<void> _markRead(String id) async {
    await ref.read(notificationsRepositoryProvider).markAsRead(id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final body = RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notifications',
                  style: AppTextStyles.heading.copyWith(fontSize: 24),
                ),
              ),
              if (_items.any((item) => !item.isRead))
                TextButton(
                  onPressed: _markAllRead,
                  child: const Text('Mark all read'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 28),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 28),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
            )
          else if (_items.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.goldDark),
                  const SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Order updates and payment confirmations will appear here.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            )
          else
            for (final item in _items) ...[
              _NotifTile(
                item: item,
                onTap: () => _markRead(item.id),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );

    if (!widget.showScaffold) return body;
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
  const _NotifTile({
    required this.item,
    required this.onTap,
  });

  final AppNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0x1AC9902A),
              child: Icon(_iconForType(item.type), size: 16, color: AppColors.goldDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titleForType(item.type),
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(item.message, style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  Text(_timeAgo(item.createdAt), style: AppTextStyles.caption),
                ],
              ),
            ),
            if (!item.isRead)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.circle, size: 8, color: AppColors.gold),
              ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'order_update':
      return Icons.local_shipping_outlined;
    case 'payment':
      return Icons.payments_outlined;
    default:
      return Icons.notifications_none_rounded;
  }
}

String _titleForType(String type) {
  switch (type) {
    case 'order_update':
      return 'Order update';
    case 'payment':
      return 'Payment update';
    default:
      return 'Notification';
  }
}

String _timeAgo(DateTime? value) {
  if (value == null) return '-';
  final diff = DateTime.now().difference(value);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${value.month}/${value.day}/${value.year}';
}
