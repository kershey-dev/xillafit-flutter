import 'package:flutter/material.dart';
import 'package:xillafit_flutter/app_colors.dart';
import 'package:xillafit_flutter/app_text_styles.dart';

/// Five tabs: Home, Cart, Messages, Notifications, Profile.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = <(IconData, String)>[
      (Icons.home_outlined, 'Home'),
      (Icons.shopping_bag_outlined, 'Cart'),
      (Icons.chat_bubble_outline, 'Chat'),
      (Icons.notifications_none, 'Notifs'),
      (Icons.person_outline, 'Profile'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final active = currentIndex == index;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: active ? 22 : 18,
                      height: 3,
                      decoration: BoxDecoration(
                        color: active ? AppColors.gold : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: active
                            ? const [BoxShadow(color: Color(0x66F59E0B), blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      items[index].$1,
                      size: 20,
                      color: active ? AppColors.gold : const Color(0xFFBABAB6),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[index].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 8,
                        letterSpacing: 0.15,
                        color: active ? AppColors.gold : const Color(0xFFBABAB6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
