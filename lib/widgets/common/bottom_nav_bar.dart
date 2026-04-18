import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_text_styles.dart';
import 'package:xillafit_flutter/features/notifications/data/notifications_repository.dart';

class BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);
    const items = <_BottomNavItem>[
      _BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
      _BottomNavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
      _BottomNavItem(icon: Icons.view_in_ar_rounded, label: '3D', highlighted: true),
      _BottomNavItem(icon: Icons.notifications_none_rounded, label: 'Alerts'),
      _BottomNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: const Color(0xFFF6F7FB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x110F172A),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final active = currentIndex == index;
                final badgeCount = index == 3 ? unreadNotifications : 0;

                if (item.highlighted) {
                  return const Expanded(
                    child: SizedBox(height: 52),
                  );
                }

                return Expanded(
                  child: _StandardNavItem(
                    active: active,
                    icon: item.icon,
                    label: item.label,
                    badgeCount: badgeCount,
                    onTap: () => onTap(index),
                  ),
                );
              }),
            ),
          ),
          Positioned(
            top: -14,
            child: _CenterNavItem(
              active: currentIndex == 2,
              icon: items[2].icon,
              label: items[2].label,
              onTap: () => onTap(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardNavItem extends StatelessWidget {
  const _StandardNavItem({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  final bool active;
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.text : const Color(0xFF6B7280);
    final background = active ? const Color(0xFFFFF6DE) : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(
          vertical: active ? 10 : 8,
          horizontal: active ? 6 : 4,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x16F59E0B),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: active ? 30 : 24, color: foreground),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -5,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: active ? 11 : 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                color: foreground,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavItem extends StatelessWidget {
  const _CenterNavItem({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: active ? 66 : 62,
            height: active ? 66 : 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFF4D9),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: active
                      ? const Color(0x20F59E0B)
                      : const Color(0x12F59E0B),
                  blurRadius: active ? 18 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: active ? 30 : 28,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;
}
