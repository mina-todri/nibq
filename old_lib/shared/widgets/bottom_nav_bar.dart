// lib/shared/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  // 4 tabs: home, cart, notifications, profile
  static const _items = [
    (Icons.home_outlined, Icons.home, 'الرئيسية'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag, 'السلة'),
    (Icons.notifications_outlined, Icons.notifications, 'الإشعارات'),
    (Icons.person_outline, Icons.person, 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfBase : AppColors.surfBaseLight,
        border: Border(
          top: BorderSide(
              color: isDark
                  ? AppColors.borderSubtle
                  : AppColors.borderSubtleLight),
        ),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final active = i == currentIndex;
          final item = _items[i];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(i),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        active ? item.$2 : item.$1,
                        color: active
                            ? AppColors.gold400
                            : AppColors.textSecondary,
                        size: 24,
                      ),
                      // Cart badge on index 1
                      if (i == 1 && cartCount > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              cartCount > 99 ? '99+' : '$cartCount',
                              style: AppTextStyles.bodyXs.copyWith(
                                  color: AppColors.textInverse,
                                  fontSize: 9,
                                  height: 1,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$3,
                    style: AppTextStyles.bodyXs.copyWith(
                      color: active
                          ? AppColors.gold400
                          : AppColors.textSecondary,
                      fontWeight:
                      active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}