import 'package:flutter/material.dart';
import 'package:xillafit_flutter/screens/catalog_screen.dart';
import 'package:xillafit_flutter/screens/notifications_screen.dart';
import 'package:xillafit_flutter/screens/order_history_screen.dart';
import 'package:xillafit_flutter/widgets/app_styles.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.gold,
      unselectedItemColor: const Color(0xFFBABAB6),
      onTap: (index) {
        if (index == currentIndex) return;
        if (index == 0) {
          Navigator.pushNamedAndRemoveUntil(context, CatalogScreen.routeName, (_) => false);
        } else if (index == 1) {
          Navigator.pushNamed(context, CatalogScreen.routeName);
        } else if (index == 2) {
          Navigator.pushNamed(context, OrderHistoryScreen.routeName);
        } else {
          Navigator.pushNamed(context, NotificationsScreen.routeName);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Products'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Notifs'),
      ],
    );
  }
}
