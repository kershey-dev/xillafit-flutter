import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:xillafit_flutter/core/network/backend_api_client.dart';
import 'package:xillafit_flutter/screens/notifications_screen.dart';
import 'package:xillafit_flutter/screens/order_tracking_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase configuration is provided per environment.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  String? _lastKnownToken;

  Future<void> initialize({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final initialToken = await messaging.getToken();
      _lastKnownToken = initialToken;
      debugPrint('[PUSH] FCM token=$initialToken');
      await _registerTokenIfPossible(initialToken);

      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((token) async {
        _lastKnownToken = token;
        debugPrint('[PUSH] FCM token refreshed=$token');
        await _registerTokenIfPossible(token);
      });

      _authSubscription?.cancel();
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
        data,
      ) async {
        if (data.session != null) {
          await _registerTokenIfPossible(_lastKnownToken);
        }
      });

      FirebaseMessaging.onMessage.listen((message) {
        final context = navigatorKey.currentContext;
        if (context == null) return;
        final title = message.notification?.title ?? 'Xilla notification';
        final body = message.notification?.body ?? 'You have a new update.';
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('$title: $body')),
        );
      });

      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleTap(navigatorKey, message),
      );

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleTap(navigatorKey, initialMessage);
      }
    } catch (error) {
      debugPrint('[PUSH] Firebase messaging unavailable error=$error');
    }
  }

  Future<void> _registerTokenIfPossible(String? token) async {
    final normalized = (token ?? '').trim();
    if (normalized.isEmpty) return;
    if (Supabase.instance.client.auth.currentSession == null) return;

    try {
      final api = BackendApiClient(supabase: Supabase.instance.client);
      await api.post(
        '/notifications/mobile-token',
        body: {
          'token': normalized,
          'platform': _platformLabel,
          'appName': 'xillafit_flutter',
        },
      );
    } catch (error) {
      debugPrint('[PUSH] token registration failed error=$error');
    }
  }

  String get _platformLabel {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  void _handleTap(
    GlobalKey<NavigatorState> navigatorKey,
    RemoteMessage message,
  ) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final orderId = message.data['orderId']?.toString();
    if ((orderId ?? '').trim().isNotEmpty) {
      navigator.pushNamed(
        OrderTrackingScreen.routeName,
        arguments: OrderTrackingArgs(orderId: orderId!),
      );
      return;
    }

    navigator.pushNamed(NotificationsScreen.routeName);
  }
}
