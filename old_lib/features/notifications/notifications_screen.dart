import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final IconData icon;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.isRead = false,
  });
}

class NotificationsNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationsNotifier()
      : super([
    NotificationItem(
      id: '1',
      title: 'تم تأكيد طلبك',
      body: 'طلبك رقم #AB12CD تم تأكيده وجاري التحضير',
      time: 'منذ 5 دقائق',
      icon: Icons.shopping_bag_outlined,
    ),
    NotificationItem(
      id: '2',
      title: 'عرض حصري',
      body: 'خصم 20% على جميع العطور هذا الأسبوع',
      time: 'منذ ساعة',
      icon: Icons.local_offer_outlined,
      isRead: true,
    ),
    NotificationItem(
      id: '3',
      title: 'تم شحن طلبك',
      body: 'طلبك في الطريق إليك ويُتوقع وصوله غداً',
      time: 'أمس',
      icon: Icons.local_shipping_outlined,
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: 'منتج جديد',
      body: 'تم إضافة "عطر الورد الملكي" إلى مجموعتنا',
      time: 'منذ يومين',
      icon: Icons.new_releases_outlined,
      isRead: true,
    ),
  ]);

  void markRead(String id) {
    state = state.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();
    state = [...state]; // trigger rebuild
  }

  void markAllRead() {
    for (final n in state) {
      n.isRead = true;
    }
    state = [...state];
  }

  void delete(String id) {
    state = state.where((n) => n.id != id).toList();
  }
}

final notificationsProvider =
StateNotifierProvider<NotificationsNotifier, List<NotificationItem>>(
        (_) => NotificationsNotifier());

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.surfBg,
      appBar: CustomAppBar(
        title: 'الإشعارات',
        showBack: false,
        actions: unread > 0
            ? [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: Text(
              'قراءة الكل',
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.gold400),
            ),
          ),
        ]
            : null,
      ),
      body: notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none,
                size: 72, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('لا توجد إشعارات',
                style: AppTextStyles.displayMd
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final n = notifications[i];
          return Dismissible(
            key: Key(n.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: AlignmentDirectional.centerEnd,
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.danger),
            ),
            onDismissed: (_) =>
                ref.read(notificationsProvider.notifier).delete(n.id),
            child: GestureDetector(
              onTap: () =>
                  ref.read(notificationsProvider.notifier).markRead(n.id),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: n.isRead
                      ? AppColors.surfRaised
                      : AppColors.surfOverlay,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: n.isRead
                        ? AppColors.borderSubtle
                        : AppColors.borderAccent,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                        AppColors.gold400.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(n.icon,
                          color: AppColors.gold400, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(n.title,
                                    style: AppTextStyles.bodyMd.copyWith(
                                        fontWeight: FontWeight.w700)),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(n.body,
                              style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(n.time,
                              style: AppTextStyles.bodyXs.copyWith(
                                  color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}