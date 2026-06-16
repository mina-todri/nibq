// lib/shared/widgets/notification_toast.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/models/notification_model.dart';
import '../../core/routing/app_router.dart';

class NotificationToast {
  static void show(BuildContext context, NotificationModel notification) {
    debugPrint('NotificationToast: START show method');
    
    // Use the navigatorKey directly as it is the most reliable source for the root overlay
    final overlay = AppRouter.navigatorKey.currentState?.overlay;

    if (overlay == null) {
      debugPrint('NotificationToast ERROR: Navigator overlay is NULL. Cannot show toast.');
      return;
    }

    // Ensure we are not calling this during a build frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        late OverlayEntry entry;
        entry = OverlayEntry(
          builder: (ctx) => _NotificationToastWidget(
            notification: notification,
            onDismiss: () {
              if (entry.mounted) entry.remove();
            },
          ),
        );

        overlay.insert(entry);
        debugPrint('NotificationToast SUCCESS: OverlayEntry inserted for ${notification.title}');

        // Auto-dismiss after 6 seconds
        Future.delayed(const Duration(seconds: 6), () {
          if (entry.mounted) {
            // Need to animate out before removing if we want it smooth, 
            // but for simplicity in auto-dismiss we can just remove or 
            // let the widget handle it. For now, just remove safely.
            entry.remove();
            debugPrint('NotificationToast: Auto-dismissed');
          }
        });
      } catch (e) {
        debugPrint('NotificationToast CRASH: $e');
      }
    });
  }
}

class _NotificationToastWidget extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;

  const _NotificationToastWidget({
    required this.notification,
    required this.onDismiss,
  });

  @override
  State<_NotificationToastWidget> createState() => _NotificationToastWidgetState();
}

class _NotificationToastWidgetState extends State<_NotificationToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Stack لازم يلف Positioned عشان يشتغل جوا OverlayEntry
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _slide,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < -10) _dismiss();
                },
                onTap: () {
                  // Navigate to notifications page
                  AppRouter.navigatorKey.currentState?.pushNamed(AppRouter.notifications);
                  // Then dismiss the toast
                  _dismiss();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfOverlay : AppColors.surfBaseLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? AppColors.borderStrong : AppColors.borderDefaultLight,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.gold400.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: AppColors.gold400,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.notification.title,
                              style: AppTextStyles.labelMd.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.notification.body,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}