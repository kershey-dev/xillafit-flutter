import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/features/checkout/data/checkout_repository.dart';
import 'package:xillafit_flutter/core/links/mobile_link_handler.dart';
import 'package:xillafit_flutter/screens/payment_submission_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';

enum MobileWebViewMode { customizer, payment }

class MobileWebViewScreen extends StatefulWidget {
  const MobileWebViewScreen({
    super.key,
    required this.title,
    required this.initialUrl,
    required this.mode,
    this.productId,
    this.popOnCustomizerSave = true,
  });

  final String title;
  final String initialUrl;
  final MobileWebViewMode mode;
  final String? productId;
  final bool popOnCustomizerSave;

  @override
  State<MobileWebViewScreen> createState() => _MobileWebViewScreenState();
}

class _MobileWebViewScreenState extends State<MobileWebViewScreen> {
  WebViewController? _controller;
  int _loadingProgress = 0;
  bool _pageLoading = true;
  String? _pageError;

  bool get _supportsEmbeddedWebView {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    if (_supportsEmbeddedWebView) {
      _controller = WebViewController()
        ..setUserAgent(_mobileUserAgent)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'XillafitBridge',
          onMessageReceived: _handleBridgeMessage,
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (progress) {
              if (!mounted) return;
              setState(() => _loadingProgress = progress);
            },
            onPageStarted: (_) {
              if (!mounted) return;
              setState(() {
                _pageLoading = true;
                _pageError = null;
              });
            },
            onPageFinished: (_) async {
              await _injectMobileLayoutOptimizations();
              await _injectSessionBridge();
              if (!mounted) return;
              setState(() => _pageLoading = false);
            },
            onWebResourceError: (error) {
              if (!mounted) return;
              setState(() {
                _pageLoading = false;
                _pageError = error.description;
              });
            },
            onNavigationRequest: _handleNavigationRequest,
          ),
        );
      unawaited(_loadInitialRequest());
    } else {
      _pageLoading = false;
    }
  }

  Future<void> _loadInitialRequest() async {
    final controller = _controller;
    if (controller == null) return;

    final session = Supabase.instance.client.auth.currentSession;
    final baseUri = Uri.parse(widget.initialUrl);
    final query = <String, String>{
      ...baseUri.queryParameters,
      'mobile': '1',
      'embedded': '1',
      'app_mode': 'embedded',
      'platform': _platformLabel,
      'auth_bridge': AppLinks.authCallbackUrl(),
    };
    if (widget.mode == MobileWebViewMode.customizer &&
        (session?.accessToken ?? '').isNotEmpty) {
      query['token'] = session!.accessToken;
      query['return_url'] = AppLinks.customizerCallbackUrl(
        saved: true,
        productId: widget.productId,
      );
    }
    if ((widget.productId ?? '').trim().isNotEmpty) {
      query['productId'] = widget.productId!.trim();
    }

    final requestUri = baseUri.replace(queryParameters: query);
    final headers = <String, String>{
      if ((session?.accessToken ?? '').isNotEmpty)
        'Authorization': 'Bearer ${session!.accessToken}',
      if ((session?.accessToken ?? '').isNotEmpty)
        'X-Xillafit-Access-Token': session!.accessToken,
      'X-Xillafit-Mobile-App': 'flutter',
      'X-Xillafit-Platform': _platformLabel,
    };

    await controller.loadRequest(requestUri, headers: headers);
  }

  Future<void> _injectMobileLayoutOptimizations() async {
    final controller = _controller;
    if (controller == null) return;

    final script = '''
      (function() {
        try {
          const ensureViewport = () => {
            let meta = document.querySelector('meta[name="viewport"]');
            if (!meta) {
              meta = document.createElement('meta');
              meta.name = 'viewport';
              document.head.appendChild(meta);
            }
            meta.content = 'width=device-width, initial-scale=1, maximum-scale=1, viewport-fit=cover';
          };

          const ensureStyle = () => {
            let style = document.getElementById('xillafit-mobile-layout');
            if (!style) {
              style = document.createElement('style');
              style.id = 'xillafit-mobile-layout';
              document.head.appendChild(style);
            }

            style.textContent = `
              html, body {
                width: 100% !important;
                max-width: 100% !important;
                overflow-x: hidden !important;
                -webkit-text-size-adjust: 100% !important;
                touch-action: manipulation;
              }

              body {
                font-size: 14px !important;
              }

              @media (max-width: 920px) {
                [class*="sidebar"],
                [class*="side-bar"],
                [class*="left-nav"],
                [class*="leftNav"],
                [class*="desktop-nav"],
                [class*="desktopNav"],
                [class*="desktop-menu"],
                [class*="desktopMenu"],
                [class*="workspace-nav"],
                [class*="workspaceNav"],
                nav[aria-label*="Sidebar"],
                aside {
                  display: none !important;
                  width: 0 !important;
                  min-width: 0 !important;
                  max-width: 0 !important;
                  flex: 0 0 0 !important;
                }

                [class*="layout"],
                [class*="Layout"],
                [class*="workspace"],
                [class*="Workspace"],
                main,
                #root,
                #app {
                  width: 100% !important;
                  max-width: 100% !important;
                }

                [class*="grid"],
                [class*="Grid"],
                [class*="editor"],
                [class*="Editor"],
                [class*="builder"],
                [class*="Builder"] {
                  grid-template-columns: minmax(0, 1fr) !important;
                }

                [class*="panel"],
                [class*="Panel"],
                [class*="properties"],
                [class*="Properties"],
                [class*="layers"],
                [class*="Layers"] {
                  max-width: 100% !important;
                }

                [class*="toolbar"],
                [class*="Toolbar"],
                header {
                  position: sticky !important;
                  top: 0 !important;
                  z-index: 30 !important;
                  background: rgba(255, 255, 255, 0.96) !important;
                  backdrop-filter: blur(14px);
                }

                button, a, input, select, textarea {
                  min-height: 40px !important;
                }

                [style*="width: 320px"],
                [style*="width:320px"],
                [style*="width: 360px"],
                [style*="width:360px"],
                [style*="width: 400px"],
                [style*="width:400px"] {
                  width: 100% !important;
                  max-width: 100% !important;
                }

                [class*="canvas"],
                [class*="Canvas"],
                model-viewer,
                canvas {
                  max-width: 100vw !important;
                }

                * {
                  scrollbar-width: thin;
                }
              }
            `;
          };

          const markMobile = () => {
            document.documentElement.setAttribute('data-xillafit-mobile', 'true');
            document.body.setAttribute('data-xillafit-mobile', 'true');
            document.body.classList.add('xillafit-mobile-webview');
          };

          ensureViewport();
          ensureStyle();
          markMobile();
        } catch (error) {
          console.log('xillafit mobile layout injection failed', error);
        }
      })();
    ''';

    try {
      await controller.runJavaScript(script);
    } catch (error) {
      debugPrint('[WEBVIEW] mobile layout injection failed error=$error');
    }
  }

  Future<void> _injectSessionBridge() async {
    final controller = _controller;
    if (controller == null) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final payload = jsonEncode({
      'accessToken': session.accessToken,
      'refreshToken': session.refreshToken,
      'expiresAt': session.expiresAt,
      'tokenType': session.tokenType,
      'user': session.user.toJson(),
      'authBridgeUrl': AppLinks.authCallbackUrl(),
      'customizerReturnUrl': AppLinks.customizerCallbackUrl(
        saved: true,
        productId: widget.productId,
      ),
    });

    try {
      await controller.runJavaScript('''
        (function() {
          try {
            const payload = $payload;
            window.localStorage.setItem('xillafit.mobile.session', JSON.stringify(payload));
            window.localStorage.setItem('xillafit.mobile.access_token', payload.accessToken || '');
            window.localStorage.setItem('xillafit.mobile.refresh_token', payload.refreshToken || '');
            window.dispatchEvent(new CustomEvent('xillafit-mobile-session', { detail: payload }));
            window.__xillafitMobileSession = payload;
          } catch (error) {
            console.log('xillafit mobile session injection failed', error);
          }
        })();
      ''');
    } catch (error) {
      debugPrint('[WEBVIEW] session injection failed error=$error');
    }
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.navigate;

    if (_isCustomizerCallback(uri)) {
      _completeCustomizerFromUri(uri);
      return NavigationDecision.prevent;
    }

    final handler = MobileLinkHandler.instance;
    if (handler != null && handler.canHandleUri(uri)) {
      unawaited(_handleMobileUri(uri));
      return NavigationDecision.prevent;
    }

    if (widget.mode == MobileWebViewMode.customizer &&
        !_isAllowedCustomizerNavigation(uri)) {
      _showBlockedRouteMessage();
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  bool _isAllowedCustomizerNavigation(Uri uri) {
    if (uri.scheme == 'about' || uri.scheme == 'data' || uri.scheme == 'javascript') {
      return true;
    }

    if (uri.scheme == AppLinks.mobileScheme) {
      return uri.host == AppLinks.customizerHost ||
          uri.host == AppLinks.authHost ||
          uri.host == AppLinks.paymentHost;
    }

    final initialUri = Uri.parse(widget.initialUrl);
    final siteUri = Uri.parse(AppLinks.siteUrl);
    final allowedHosts = <String>{initialUri.host, siteUri.host};

    if (!allowedHosts.contains(uri.host)) {
      return false;
    }

    final path = uri.path.toLowerCase();
    final initialPath = initialUri.path.toLowerCase();
    return path == initialPath ||
        path.startsWith('$initialPath/') ||
        path == AppLinks.authBridgePath ||
        path == AppLinks.paymentBridgePath;
  }

  void _showBlockedRouteMessage() {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('This mobile flow only allows the embedded customizer.'),
      ),
    );
  }

  Future<void> _handleMobileUri(Uri uri) async {
    setState(() => _pageLoading = true);
    try {
      await MobileLinkHandler.instance?.handleUri(uri);
      if (!mounted) return;
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) {
        setState(() => _pageLoading = false);
      }
    }
  }

  bool _isCustomizerCallback(Uri uri) {
    if (uri.scheme == AppLinks.mobileScheme && uri.host == AppLinks.customizerHost) {
      return true;
    }

    final siteUri = Uri.parse(AppLinks.siteUrl);
    return uri.host == siteUri.host &&
        (uri.queryParameters['design'] != null ||
            (uri.path.contains('customizer') &&
                uri.queryParameters['saved'] != null));
  }

  void _completeCustomizerFromUri(Uri uri) {
    _handleCustomizerResult({
      ...uri.queryParameters,
      'saved': uri.queryParameters['saved'] ?? 'true',
    });
  }

  Future<void> _handleCustomizerResult(Map<String, dynamic> payload) async {
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (widget.popOnCustomizerSave && navigator.canPop()) {
      navigator.pop<Map<String, dynamic>>(payload);
      return;
    }

    final design = CustomDesignDraft.fromCustomizerResult(payload);
    if (design.designId.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Design synced back to the app.')),
      );
      return;
    }

    await navigator.pushNamed(
      PaymentSubmissionScreen.routeName,
      arguments: PaymentSubmissionArgs.customDesign(design: design),
    );
  }

  void _handleBridgeMessage(JavaScriptMessage message) {
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is! Map<String, dynamic>) return;
      final type = decoded['type']?.toString();
      if (type == 'designSaved' || type == 'design_saved') {
        unawaited(
          _handleCustomizerResult(
            Map<String, dynamic>.from(decoded['payload'] as Map? ?? const {}),
          ),
        );
      } else if (type == 'auth') {
        final payload = Map<String, dynamic>.from(decoded['payload'] as Map? ?? const {});
        final uri = Uri.parse(
          AppLinks.authCallbackUrl(
            queryParameters: payload.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            ),
          ),
        );
        unawaited(_handleMobileUri(uri));
      } else if (type == 'paymentReturn') {
        final payload = Map<String, dynamic>.from(decoded['payload'] as Map? ?? const {});
        final success = payload['success']?.toString() != 'false';
        final uri = Uri.parse(
          AppLinks.paymentCallbackUrl(
            success: success,
            flow: payload['flow']?.toString(),
            orderId: payload['orderId']?.toString(),
            referenceId: payload['referenceId']?.toString(),
          ),
        );
        unawaited(_handleMobileUri(uri));
      } else if (type == 'close' && mounted) {
        Navigator.of(context).maybePop();
      }
    } catch (error) {
      debugPrint('[WEBVIEW] bridge parse failed error=$error');
    }
  }

  String get _platformLabel {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    return 'unknown';
  }

  String get _mobileUserAgent {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1 XillafitApp/1.0';
    }
    return 'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36 XillafitApp/1.0';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.title,
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
      ),
      body: Column(
        children: [
          if (_pageLoading || _loadingProgress < 100)
            LinearProgressIndicator(
              minHeight: 2,
              value: _loadingProgress == 0 || _loadingProgress == 100
                  ? null
                  : _loadingProgress / 100,
              color: AppColors.gold,
            ),
          Expanded(
            child: Stack(
              children: [
                if (_supportsEmbeddedWebView)
                  WebViewWidget(controller: _controller!)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Embedded web checkout is available on Android and iOS.',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (_pageError != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load this page.',
                            style: AppTextStyles.heading,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _pageError!,
                            style: AppTextStyles.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () {
                              setState(() {
                                _pageError = null;
                                _pageLoading = true;
                              });
                              unawaited(_loadInitialRequest());
                            },
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
