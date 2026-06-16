import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../core/models/notification_model.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/notifications_provider.dart';

import '../../shared/widgets/loading_widget.dart';
import '../orders/order_detail_screen.dart';
import '../checkout/providers/order_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'الإشعارات',
        showBack: true,
        actions: unreadCount > 0
            ? [
                TextButton(
                  onPressed: () {
                    if (user != null) {
                      ref
                          .read(notificationRepositoryProvider)
                          .markAllAsRead(user.uid);
                    }
                  },
                  child: Text(
                    'قراءة الكل',
                    style: AppTextStyles.bodySm
                        .copyWith(color: colorScheme.primary),
                  ),
                ),
              ]
            : null,
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const _EmptyNotifications();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final n = notifications[i];
              return _NotificationTile(notification: n);
            },
          );
        },
        loading: () => const LoadingWidget(),
        error: (err, stack) => Center(
          child: Text(
            'حدث خطأ: $err',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 72, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('لا توجد إشعارات',
              style: AppTextStyles.displayMd
                  .copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final n = notification;
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_outline, color: colorScheme.error),
      ),
      onDismissed: (_) {
        if (user != null) {
          ref.read(notificationRepositoryProvider).deleteNotification(user.uid, n.id);
        }
      },
      child: GestureDetector(
        onTap: () async {
          if (user != null && !n.isRead) {
            ref.read(notificationRepositoryProvider).markAsRead(user.uid, n.id);
          }

          if (n.type == NotificationType.orderStatus && n.relatedId != null) {
            _handleOrderNavigation(context, ref, n.relatedId!);
          } else {
            _showNotificationDialog(context, n);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.isRead ? colorScheme.surface : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.isRead ? colorScheme.outlineVariant : colorScheme.primary.withValues(alpha: 0.3),
              width: n.isRead ? 1 : 1.5,
            ),
            boxShadow: n.isRead 
              ? null 
              : [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getIcon(n.type), 
                      color: colorScheme.primary, 
                      size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(n.title,
                                  style: AppTextStyles.bodyMd.copyWith(
                                    fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  )),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(n.body,
                            style: AppTextStyles.bodySm.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(n.createdAt),
                    style: AppTextStyles.bodyXs.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (n.type == NotificationType.orderStatus && n.relatedId != null)
                    Row(
                      children: [
                        Text(
                          'عرض تفاصيل الطلب',
                          style: AppTextStyles.bodyXs.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios, 
                          size: 10, color: colorScheme.primary),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleOrderNavigation(BuildContext context, WidgetRef ref, String orderId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: LoadingWidget()),
    );

    try {
      final order = await ref.read(orderByIdProvider(orderId).future);
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحميل تفاصيل الطلب: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showNotificationDialog(BuildContext context, NotificationModel n) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_getIcon(n.type), color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                n.title,
                style: AppTextStyles.displayMd.copyWith(color: colorScheme.onSurface),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            n.body,
            style: AppTextStyles.bodyMd.copyWith(
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إغلاق', 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderStatus:
        return Icons.shopping_bag_outlined;
      case NotificationType.promotion:
        return Icons.local_offer_outlined;
      case NotificationType.newProduct:
        return Icons.new_releases_outlined;
      case NotificationType.general:
        return Icons.notifications_none;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm').format(date);
  }
}
