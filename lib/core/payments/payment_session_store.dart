import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingPaymentSession {
  const PendingPaymentSession({
    required this.sessionId,
    required this.flow,
    this.orderId,
    this.referenceId,
  });

  final String sessionId;
  final String flow;
  final String? orderId;
  final String? referenceId;

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'flow': flow,
      if ((orderId ?? '').trim().isNotEmpty) 'order_id': orderId,
      if ((referenceId ?? '').trim().isNotEmpty) 'reference_id': referenceId,
    };
  }

  factory PendingPaymentSession.fromMap(Map<String, dynamic> map) {
    return PendingPaymentSession(
      sessionId: map['session_id']?.toString() ?? '',
      flow: map['flow']?.toString() ?? '',
      orderId: map['order_id']?.toString(),
      referenceId: map['reference_id']?.toString(),
    );
  }
}

class PaymentSessionStore {
  static const _storageKey = 'xillafit.pending_payment_session';

  static Future<void> save(PendingPaymentSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(session.toMap()));
  }

  static Future<PendingPaymentSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final session =
          PendingPaymentSession.fromMap(Map<String, dynamic>.from(decoded));
      if (session.sessionId.isEmpty) return null;
      return session;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
