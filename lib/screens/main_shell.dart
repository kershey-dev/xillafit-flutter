import 'package:flutter/material.dart';
import 'package:xillafit_flutter/screens/cart_placeholder_screen.dart';
import 'package:xillafit_flutter/screens/home_screen.dart';
import 'package:xillafit_flutter/screens/messages_screen.dart';
import 'package:xillafit_flutter/screens/notifications_screen.dart';
import 'package:xillafit_flutter/screens/profile_placeholder_screen.dart';
import 'package:xillafit_flutter/widgets/common/bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  static const routeName = '/shell';

  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<Widget> get _tabs => [
    HomeScreen(
      onOpenCart: () => setState(() => _index = 1),
    ),
    const CartPlaceholderScreen(),
    const MessagesScreen(embeddedInShell: true),
    const NotificationsScreen(showScaffold: false),
    const ProfilePlaceholderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom,
        ),
        child: BottomNavBar(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
        ),
      ),
    );
  }
}
