// lib/shared/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;
  final int notificationsCount;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
    this.notificationsCount = 0,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
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
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                      // Cart badge on index 1
                      if (i == 1 && cartCount > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              cartCount > 99 ? '99+' : '$cartCount',
                              style: AppTextStyles.bodyXs.copyWith(
                                  color: colorScheme.onError,
                                  fontSize: 9,
                                  height: 1,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      // Notifications badge on index 2
                      if (i == 2 && notificationsCount > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                notificationsCount > 9 ? '9+' : '$notificationsCount',
                                style: AppTextStyles.bodyXs.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontSize: 8,
                                    height: 1,
                                    fontWeight: FontWeight.bold),
                              ),
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
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
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