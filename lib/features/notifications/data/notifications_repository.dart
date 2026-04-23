import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/storage/local_database.dart';

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
      id: map['id']?.toString() ?? map['notification_id']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['notification_type']?.toString() ?? 'general',
      isRead: map['is_read'] == true || map['is_read'] == 1,
      orderId: map['order_id']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }
}

class NotificationsSnapshot {
  const NotificationsSnapshot({
    required this.items,
    required this.isOfflineSnapshot,
    this.syncedAt,
  });

  final List<AppNotificationItem> items;
  final bool isOfflineSnapshot;
  final DateTime? syncedAt;
}

class NotificationsRepository {
  NotificationsRepository({
    required SupabaseClient client,
    required LocalDatabase localDatabase,
  })  : _client = client,
        _localDatabase = localDatabase;

  final SupabaseClient _client;
  final LocalDatabase _localDatabase;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<NotificationsSnapshot> fetchMyNotificationsSnapshot() async {
    final userId = currentUserId;
    if (userId == null) {
      return const NotificationsSnapshot(
        items: [],
        isOfflineSnapshot: false,
      );
    }

    try {
      final data = await _client
          .from('notifications')
          .select('id, message, notification_type, is_read, order_id, created_at')
          .eq('profile_id', userId)
          .order('created_at', ascending: false)
          .limit(100);

      final rows = (data as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
      final syncedAt = DateTime.now().toUtc();
      await _localDatabase.replaceNotificationItems(
        userId,
        rows,
        syncedAt: syncedAt.toIso8601String(),
      );
      return NotificationsSnapshot(
        items: rows.map(AppNotificationItem.fromMap).toList(growable: false),
        isOfflineSnapshot: false,
        syncedAt: syncedAt,
      );
    } catch (_) {
      final rows = await _localDatabase.loadNotificationItems(userId);
      DateTime? syncedAt;
      if (rows.isNotEmpty) {
        syncedAt = DateTime.tryParse(rows.first['synced_at']?.toString() ?? '');
      }
      return NotificationsSnapshot(
        items: rows.map(AppNotificationItem.fromMap).toList(growable: false),
        isOfflineSnapshot: true,
        syncedAt: syncedAt,
      );
    }
  }

  Stream<List<AppNotificationItem>> watchMyNotifications() async* {
    final userId = currentUserId;
    if (userId == null) {
      yield const [];
      return;
    }

    final initial = await fetchMyNotificationsSnapshot();
    yield initial.items;

    yield* _client
        .from('notifications')
        .stream(primaryKey: const ['id'])
        .eq('profile_id', userId)
        .order('created_at', ascending: false)
        .limit(100)
        .asyncMap((rows) async {
          final normalized = rows
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false);
          await _localDatabase.replaceNotificationItems(userId, normalized);
          return normalized.map(AppNotificationItem.fromMap).toList(growable: false);
        });
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _localDatabase.markNotificationRead(userId, notificationId);

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('profile_id', userId);
    } catch (_) {
      // Keep the local read state and retry from the server on the next refresh.
    }
  }

  Future<void> markAllRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    await _localDatabase.markAllNotificationsRead(userId);

    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('profile_id', userId)
          .eq('is_read', false);
    } catch (_) {
      // Keep local state and let the next online refresh reconcile the server copy.
    }
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(
    client: Supabase.instance.client,
    localDatabase: LocalDatabase.instance,
  );
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
