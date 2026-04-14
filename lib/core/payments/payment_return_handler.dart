import 'dart:async';

import 'package:app_links/app_links.dart' as applinks;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/core/payments/payment_session_store.dart';
import 'package:xillafit_flutter/screens/order_history_screen.dart';
import 'package:xillafit_flutter/screens/order_tracking_screen.dart';

class PaymentReturnHandler {
  PaymentReturnHandler({
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _navigatorKey = navigatorKey,
        _appLinks = applinks.AppLinks(),
        _api = BackendApiClient(supabase: Supabase.instance.client);

  final GlobalKey<NavigatorState> _navigatorKey;
  final applinks.AppLinks _appLinks;
  final BackendApiClient _api;

  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;
  bool _handling = false;
  String? _backgroundSyncSessionId;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    final initialUri = await _appLinks.getInitialLink();
    debugPrint('[PAYMENT_RETURN] initialize initialUri=$initialUri');
    if (initialUri != null) {
      unawaited(_handleUri(initialUri));
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[PAYMENT_RETURN] stream uri=$uri');
        unawaited(_handleUri(uri));
      },
      onError: (error) {
        debugPrint('[PAYMENT_RETURN] stream error=$error');
      },
    );
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _PaymentLifecycleObserver(onResume: _handleAppResume);

  bool _isPaymentCallback(Uri uri) {
    return uri.scheme == AppLinks.authRedirectScheme &&
        uri.host == AppLinks.authRedirectHost &&
        uri.path.startsWith('/payment');
  }

  Future<void> _handleAppResume() async {
    final pendingSession = await PaymentSessionStore.read();
    if (pendingSession == null || pendingSession.sessionId.isEmpty || _handling) {
      return;
    }

    debugPrint(
      '[PAYMENT_RETURN] app resumed with pending session='
      '${pendingSession.sessionId} flow=${pendingSession.flow}',
    );

    final fallbackUri = Uri(
      scheme: AppLinks.authRedirectScheme,
      host: AppLinks.authRedirectHost,
      path: '/payment',
      queryParameters: <String, String>{
        'success': 'true',
        if ((pendingSession.flow).trim().isNotEmpty) 'flow': pendingSession.flow,
        if ((pendingSession.orderId ?? '').trim().isNotEmpty)
          'orderId': pendingSession.orderId!,
        if ((pendingSession.referenceId ?? '').trim().isNotEmpty)
          'referenceId': pendingSession.referenceId!,
      },
    );

    await _handleUri(fallbackUri);
  }

  Future<void> _handleUri(Uri uri) async {
    if (!_isPaymentCallback(uri) || _handling) return;
    _handling = true;

    try {
      final success = uri.queryParameters['success'] == 'true';
      final pendingSession = await PaymentSessionStore.read();
      String? resolvedOrderId = pendingSession?.orderId;
      debugPrint(
        '[PAYMENT_RETURN] handle uri=$uri success=$success '
        'pendingSession=${pendingSession?.sessionId} flow=${pendingSession?.flow} '
        'orderId=${pendingSession?.orderId} ref=${pendingSession?.referenceId}',
      );

      if (!success) {
        await PaymentSessionStore.clear();
        _showSnackBar('Payment was not completed.');
        _navigateAfterReturn(
          orderId: uri.queryParameters['orderId'] ?? pendingSession?.orderId,
        );
        return;
      }

      if (pendingSession == null || pendingSession.sessionId.isEmpty) {
        _showSnackBar('Payment return received, but no pending session was found.');
        return;
      }

      final captureResult = await _attemptCapture(
        pendingSession.sessionId,
        resolvedOrderId,
      );
      resolvedOrderId = captureResult.orderId;

      if (captureResult.confirmed) {
        await PaymentSessionStore.clear();
        await _clearCartAfterPayment();
        _showSnackBar('Payment confirmed. Your order is now updating.');
      } else {
        _showSnackBar('Payment received. Syncing your order in the background.');
        unawaited(
          _continueCaptureInBackground(
            pendingSession.sessionId,
            resolvedOrderId,
          ),
        );
      }

      _navigateAfterReturn(orderId: resolvedOrderId);
    } finally {
      _handling = false;
    }
  }

  Future<_CaptureResult> _attemptCapture(
    String sessionId,
    String? currentOrderId,
  ) async {
    try {
      debugPrint('[PAYMENT_RETURN] capture attempt session=$sessionId');
      final response = await _api.post(
        '/payments/capture',
        body: {'sessionId': sessionId},
      );
      var resolvedOrderId = currentOrderId;
      if (response is Map<String, dynamic>) {
        final order = response['order'];
        if (order is Map) {
          resolvedOrderId = order['id']?.toString() ?? resolvedOrderId;
        }
      }
      debugPrint('[PAYMENT_RETURN] capture success');
      return _CaptureResult(
        confirmed: true,
        orderId: resolvedOrderId,
      );
    } on BackendApiException catch (error) {
      debugPrint(
        '[PAYMENT_RETURN] capture backend error '
        'status=${error.statusCode} message=${error.message}',
      );
      return _CaptureResult(
        confirmed: false,
        orderId: currentOrderId,
        retryable: error.statusCode == 400,
      );
    } catch (error) {
      debugPrint('[PAYMENT_RETURN] capture unknown error error=$error');
      return _CaptureResult(
        confirmed: false,
        orderId: currentOrderId,
      );
    }
  }

  Future<void> _continueCaptureInBackground(
    String sessionId,
    String? currentOrderId,
  ) async {
    if (_backgroundSyncSessionId == sessionId) return;
    _backgroundSyncSessionId = sessionId;

    try {
      var resolvedOrderId = currentOrderId;
      for (var attempt = 1; attempt <= 4; attempt++) {
        await Future<void>.delayed(Duration(milliseconds: 900 * attempt));
        final result = await _attemptCapture(sessionId, resolvedOrderId);
        resolvedOrderId = result.orderId;
        if (result.confirmed) {
          await PaymentSessionStore.clear();
          await _clearCartAfterPayment();
          _showSnackBar('Payment confirmed. Your order is now updated.');
          return;
        }
        if (!result.retryable) {
          break;
        }
      }
      _showSnackBar('Payment is still syncing. Please refresh your orders shortly.');
    } finally {
      if (_backgroundSyncSessionId == sessionId) {
        _backgroundSyncSessionId = null;
      }
    }
  }

  Future<void> _clearCartAfterPayment() async {
    try {
      await _api.delete('/cart');
      debugPrint('[PAYMENT_RETURN] cart cleared after confirmed payment');
    } catch (error) {
      debugPrint('[PAYMENT_RETURN] cart clear failed error=$error');
    }
  }

  void _navigateAfterReturn({String? orderId}) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    debugPrint('[PAYMENT_RETURN] navigateAfterReturn orderId=$orderId');

    if ((orderId ?? '').trim().isNotEmpty) {
      navigator.pushNamedAndRemoveUntil(
        OrderTrackingScreen.routeName,
        (_) => false,
        arguments: OrderTrackingArgs(orderId: orderId!),
      );
      return;
    }

    navigator.pushNamedAndRemoveUntil(
      OrderHistoryScreen.routeName,
      (_) => false,
    );
  }

  void _showSnackBar(String message) {
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CaptureResult {
  const _CaptureResult({
    required this.confirmed,
    required this.orderId,
    this.retryable = false,
  });

  final bool confirmed;
  final String? orderId;
  final bool retryable;
}

class _PaymentLifecycleObserver with WidgetsBindingObserver {
  _PaymentLifecycleObserver({required this.onResume});

  final Future<void> Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onResume());
    }
  }
}
