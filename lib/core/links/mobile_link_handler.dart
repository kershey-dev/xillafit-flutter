import 'dart:async';

import 'package:app_links/app_links.dart' as applinks;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/core/payments/payment_session_store.dart';
import 'package:xillafit_flutter/screens/main_shell.dart';
import 'package:xillafit_flutter/screens/order_history_screen.dart';
import 'package:xillafit_flutter/screens/order_tracking_screen.dart';

class MobileLinkHandler {
  MobileLinkHandler({
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _navigatorKey = navigatorKey,
        _appLinks = applinks.AppLinks(),
        _api = BackendApiClient(supabase: Supabase.instance.client) {
    _instance = this;
  }

  static MobileLinkHandler? _instance;

  static MobileLinkHandler? get instance => _instance;

  final GlobalKey<NavigatorState> _navigatorKey;
  final applinks.AppLinks _appLinks;
  final BackendApiClient _api;

  StreamSubscription<Uri>? _linkSubscription;
  bool _initialized = false;
  bool _handlingPayment = false;
  String? _backgroundSyncSessionId;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    final initialUri = await _appLinks.getInitialLink();
    debugPrint('[MOBILE_LINKS] initialize initialUri=$initialUri');
    if (initialUri != null) {
      unawaited(handleUri(initialUri));
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('[MOBILE_LINKS] stream uri=$uri');
        unawaited(handleUri(uri));
      },
      onError: (error) {
        debugPrint('[MOBILE_LINKS] stream error=$error');
      },
    );
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _MobileLinksLifecycleObserver(onResume: _handleAppResume);

  bool canHandleUri(Uri uri) {
    return _isPaymentCallback(uri) || _isAuthCallback(uri);
  }

  Future<bool> handleUri(Uri uri) async {
    if (_isPaymentCallback(uri)) {
      await _handlePaymentUri(uri);
      return true;
    }
    if (_isAuthCallback(uri)) {
      await _handleAuthUri(uri);
      return true;
    }
    return false;
  }

  bool _isPaymentCallback(Uri uri) {
    final params = _mergedParams(uri);
    final isNewShape = uri.scheme == AppLinks.mobileScheme &&
        uri.host == AppLinks.paymentHost &&
        (uri.path == AppLinks.paymentSuccessPath ||
            uri.path == AppLinks.paymentCancelPath);
    final isLegacyShape = uri.scheme == AppLinks.mobileScheme &&
        uri.host == AppLinks.legacyAuthRedirectHost &&
        uri.path.startsWith('/payment');
    final isBridgeShape = _isSiteBridgeUri(uri, AppLinks.paymentBridgePath) &&
        params.containsKey('success');
    return isNewShape || isLegacyShape || isBridgeShape;
  }

  bool _isAuthCallback(Uri uri) {
    final params = _mergedParams(uri);
    final isNewShape = uri.scheme == AppLinks.mobileScheme &&
        uri.host == AppLinks.authHost;
    final isLegacyShape = uri.scheme == AppLinks.mobileScheme &&
        uri.host == AppLinks.legacyAuthRedirectHost &&
        !uri.path.startsWith('/payment');
    final isBridgeShape =
        _isSiteBridgeUri(uri, AppLinks.authBridgePath) &&
            (params.containsKey('refresh_token') ||
                params.containsKey('session') ||
                params.containsKey('access_token'));
    return isNewShape || isLegacyShape || isBridgeShape;
  }

  bool _isSiteBridgeUri(Uri uri, String expectedPath) {
    final siteUri = Uri.parse(AppLinks.siteUrl);
    return uri.host == siteUri.host && uri.path == expectedPath;
  }

  Map<String, String> _mergedParams(Uri uri) {
    final merged = <String, String>{...uri.queryParameters};
    final fragment = uri.fragment.trim();
    if (fragment.isNotEmpty) {
      final normalized = fragment.startsWith('?') ? fragment.substring(1) : fragment;
      try {
        merged.addAll(Uri.splitQueryString(normalized));
      } catch (_) {
        final queryIndex = normalized.indexOf('?');
        if (queryIndex >= 0 && queryIndex < normalized.length - 1) {
          merged.addAll(Uri.splitQueryString(normalized.substring(queryIndex + 1)));
        }
      }
    }
    return merged;
  }

  Future<void> _handleAppResume() async {
    final pendingSession = await PaymentSessionStore.read();
    if (pendingSession == null || pendingSession.sessionId.isEmpty || _handlingPayment) {
      return;
    }

    final fallbackUri = Uri.parse(
      AppLinks.paymentCallbackUrl(
        success: true,
        flow: pendingSession.flow,
        orderId: pendingSession.orderId,
        referenceId: pendingSession.referenceId,
      ),
    );

    await _handlePaymentUri(fallbackUri);
  }

  Future<void> _handleAuthUri(Uri uri) async {
    final params = _mergedParams(uri);
    try {
      if ((params['session'] ?? '').trim().isNotEmpty) {
        await Supabase.instance.client.auth.recoverSession(
          Uri.decodeComponent(params['session']!.trim()),
        );
      } else if ((params['refresh_token'] ?? '').trim().isNotEmpty) {
        await Supabase.instance.client.auth.setSession(
          params['refresh_token']!.trim(),
        );
      } else {
        _showSnackBar('Sign-in link opened, but no session data was included.');
        return;
      }

      _showSnackBar('Signed in successfully on mobile.');
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        MainShell.routeName,
        (_) => false,
      );
    } catch (error) {
      debugPrint('[MOBILE_LINKS] auth restore failed error=$error');
      _showSnackBar('Could not restore your session. Please sign in again.');
    }
  }

  Future<void> _handlePaymentUri(Uri uri) async {
    if (_handlingPayment) return;
    _handlingPayment = true;

    try {
      final params = _mergedParams(uri);
      final success = params['success'] != 'false' &&
          uri.path != AppLinks.paymentCancelPath;
      final pendingSession = await PaymentSessionStore.read();
      String? resolvedOrderId = params['orderId'] ?? pendingSession?.orderId;

      if (!success) {
        await PaymentSessionStore.clear();
        _showSnackBar('Payment was not completed.');
        _navigateAfterPaymentReturn(orderId: resolvedOrderId);
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

      _navigateAfterPaymentReturn(orderId: resolvedOrderId);
    } finally {
      _handlingPayment = false;
    }
  }

  Future<_CaptureResult> _attemptCapture(
    String sessionId,
    String? currentOrderId,
  ) async {
    try {
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
      return _CaptureResult(
        confirmed: true,
        orderId: resolvedOrderId,
      );
    } on BackendApiException catch (error) {
      return _CaptureResult(
        confirmed: false,
        orderId: currentOrderId,
        retryable: error.statusCode == 400,
      );
    } catch (_) {
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
    } catch (error) {
      debugPrint('[MOBILE_LINKS] cart clear failed error=$error');
    }
  }

  void _navigateAfterPaymentReturn({String? orderId}) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;

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
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
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

class _MobileLinksLifecycleObserver with WidgetsBindingObserver {
  _MobileLinksLifecycleObserver({required this.onResume});

  final Future<void> Function() onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(onResume());
    }
  }
}
