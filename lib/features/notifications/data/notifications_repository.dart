import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    this.orderId,
    this.createdAt,
  });

  final String id;
  final String message;
  final String type;
  final bool isRead;
  final String? orderId;
  final DateTime? createdAt;

  factory AppNotificationItem.fromMap(Map<String, dynamic> map) {
    return AppNotificationItem(
      id: map['id']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['notification_type']?.toString() ?? 'general',
      isRead: map['is_read'] == true,
      orderId: map['order_id']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

class NotificationsRepository {
  NotificationsRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<AppNotificationItem>> fetchMyNotifications() async {
    final userId = currentUserId;
    if (userId == null) return const [];

    final data = await _client
        .from('notifications')
        .select('id, message, notification_type, is_read, order_id, created_at')
        .eq('profile_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    return (data as List)
        .map((row) => AppNotificationItem.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Stream<List<AppNotificationItem>> watchMyNotifications() {
    final userId = currentUserId;
    if (userId == null) {
      return Stream<List<AppNotificationItem>>.value(const []);
    }

    return _client
        .from('notifications')
        .stream(primaryKey: const ['id'])
        .eq('profile_id', userId)
        .order('created_at', ascending: false)
        .limit(100)
        .map(
          (rows) => rows
              .map((row) => AppNotificationItem.fromMap(Map<String, dynamic>.from(row)))
              .toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('profile_id', userId);
  }

  Future<void> markAllRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('profile_id', userId)
        .eq('is_read', false);
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(client: Supabase.instance.client);
});

final myNotificationsProvider = StreamProvider<List<AppNotificationItem>>((ref) {
  return ref.watch(notificationsRepositoryProvider).watchMyNotifications();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(myNotificationsProvider).maybeWhen(
        data: (items) => items.where((item) => !item.isRead).length,
        orElse: () => 0,
      );
});
