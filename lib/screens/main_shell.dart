import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/core/network/connectivity_status.dart';
import 'package:xillafit_flutter/core/config/app_links.dart';
import 'package:xillafit_flutter/features/cart/presentation/cart_provider.dart';
import 'package:xillafit_flutter/screens/cart_placeholder_screen.dart';
import 'package:xillafit_flutter/screens/home_screen.dart';
import 'package:xillafit_flutter/screens/messages_screen.dart';
import 'package:xillafit_flutter/screens/mobile_webview_screen.dart';
import 'package:xillafit_flutter/screens/notifications_screen.dart';
import 'package:xillafit_flutter/screens/profile_placeholder_screen.dart';
import 'package:xillafit_flutter/widgets/common/bottom_nav_bar.dart';

class MainShell extends ConsumerStatefulWidget {
  static const routeName = '/shell';

  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  bool _showBackOnlineBanner = false;
  bool? _lastOfflineState;
  Timer? _backOnlineTimer;

  @override
  void dispose() {
    _backOnlineTimer?.cancel();
    super.dispose();
  }

  void _openCartScreen() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CartPlaceholderScreen.routeName,
      (route) => route.settings.name == MainShell.routeName || route.isFirst,
    );
  }

  Future<void> _openCustomizer() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MobileWebViewScreen(
          title: '3D Customizer',
          initialUrl: AppLinks.customizeUrl,
          mode: MobileWebViewMode.customizer,
        ),
      ),
    );
  }

  List<Widget> get _tabs => [
    HomeScreen(
      onOpenCart: _openCartScreen,
    ),
    const MessagesScreen(embeddedInShell: true),
    const SizedBox.shrink(),
    const NotificationsScreen(showScaffold: false),
    const ProfilePlaceholderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final offlineAsync = ref.watch(isOfflineProvider);
    final isOffline = offlineAsync.asData?.value ?? false;
    _handleConnectivityTransition(isOffline);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (isOffline) const _OfflineModeBanner(),
            if (!isOffline && _showBackOnlineBanner) const _BackOnlineBanner(),
            Expanded(
              child: IndexedStack(index: _index, children: _tabs),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: BottomNavBar(
          currentIndex: _index,
          onTap: (value) {
            if (value == 2) {
              _openCustomizer();
              return;
            }
            setState(() => _index = value);
          },
        ),
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
      _backOnlineTimer?.cancel();
      Future.microtask(() => ref.read(cartProvider.notifier).refreshCart());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _showBackOnlineBanner = true);
      });
      _backOnlineTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _showBackOnlineBanner = false);
      });
    }

    if (isOffline && _showBackOnlineBanner) {
      _backOnlineTimer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _showBackOnlineBanner = false);
      });
    }

    _lastOfflineState = isOffline;
  }
}

class _OfflineModeBanner extends StatelessWidget {
  const _OfflineModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF4E8),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5D1A7)),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: Color(0xFF9A6700),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline Mode: showing saved data. Changes will sync when online.',
              style: TextStyle(
                color: Color(0xFF9A6700),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackOnlineBanner extends StatelessWidget {
  const _BackOnlineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFEFFAF2),
        border: Border(
          bottom: BorderSide(color: Color(0xFFB7E4C7)),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.cloud_done_rounded,
            size: 18,
            color: Color(0xFF1F7A3D),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Back online. Syncing latest data...',
              style: TextStyle(
                color: Color(0xFF1F7A3D),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
