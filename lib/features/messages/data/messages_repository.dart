import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/features/cart/data/cart_repository.dart';

class SupportProfile {
  const SupportProfile({
    required this.id,
    required this.role,
    this.fullName,
  });

  final String id;
  final String role;
  final String? fullName;

  factory SupportProfile.fromMap(Map<String, dynamic> map) {
    return SupportProfile(
      id: map['id']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      fullName: map['full_name']?.toString(),
    );
  }
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderProfileId,
    required this.receiverProfileId,
    required this.messageContent,
    required this.status,
    this.sentAt,
  });

  final String id;
  final String senderProfileId;
  final String receiverProfileId;
  final String messageContent;
  final String status;
  final DateTime? sentAt;

  factory SupportMessage.fromMap(Map<String, dynamic> map) {
    return SupportMessage(
      id: map['id']?.toString() ?? '',
      senderProfileId: map['sender_profile_id']?.toString() ?? '',
      receiverProfileId: map['receiver_profile_id']?.toString() ?? '',
      messageContent: map['message_content']?.toString() ?? '',
      status: map['status']?.toString() ?? 'sent',
      sentAt: DateTime.tryParse(map['sent_at']?.toString() ?? ''),
    );
  }
}

class MessagesRepository {
  MessagesRepository({
    required SupabaseClient client,
    required BackendApiClient api,
  })  : _client = client,
        _api = api;

  final SupabaseClient _client;
  final BackendApiClient _api;

  static const _staffRoles = ['admin', 'sales_staff', 'design_staff'];

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<SupportProfile>> fetchActiveSupportProfiles() async {
    final data = await _client
        .from('profiles')
        .select('id, role, full_name')
        .inFilter('role', _staffRoles)
        .eq('account_status', 'active');

    final profiles = (data as List)
        .map((row) => SupportProfile.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();

    profiles.sort((a, b) => _rank(a.role).compareTo(_rank(b.role)));
    return profiles;
  }

  Future<List<SupportMessage>> fetchMessages() async {
    final userId = currentUserId;
    if (userId == null) return const [];

    final data = await _client
        .from('messages')
        .select('*')
        .or('sender_profile_id.eq.$userId,receiver_profile_id.eq.$userId')
        .order('sent_at', ascending: true)
        .limit(200);

    return (data as List)
        .map((row) => SupportMessage.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> sendMessage({
    required String receiverProfileId,
    required String message,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _client.from('messages').insert({
      'sender_profile_id': userId,
      'receiver_profile_id': receiverProfileId,
      'subject': null,
      'message_content': message.trim(),
      'message_type': 'customer_inquiry',
      'status': 'sent',
    });
  }

  Future<void> markConversationRead({String? senderId}) async {
    await _api.patch('/messages/read', body: {
      if ((senderId ?? '').trim().isNotEmpty) 'senderId': senderId,
    });
  }

  int _rank(String role) {
    switch (role) {
      case 'admin':
        return 0;
      case 'sales_staff':
        return 1;
      case 'design_staff':
        return 2;
      default:
        return 9;
    }
  }
}

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(
    client: Supabase.instance.client,
    api: ref.watch(backendApiClientProvider),
  );
});
