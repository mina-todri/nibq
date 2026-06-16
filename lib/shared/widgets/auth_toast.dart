// lib/shared/widgets/auth_toast.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

enum ToastType { error, success, warning }

class AuthToast {
  static void show(
      BuildContext context, {
        required String message,
        required ToastType type,
        String? title,
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AuthToastWidget(
        title: title ?? _defaultTitle(type),
        message: message,
        type: type,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss بعد 4 ثواني
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  static String _defaultTitle(ToastType type) => switch (type) {
    ToastType.error   => 'حدث خطأ',
    ToastType.success => 'تم بنجاح',
    ToastType.warning => 'تنبيه',
  };
}

class _AuthToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _AuthToastWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AuthToastWidget> createState() => _AuthToastWidgetState();
}

class _AuthToastWidgetState extends State<_AuthToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _ToastColors.of(widget.type);

    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom +
          MediaQuery.of(context).padding.bottom +
          16,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: AppColors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border, width: 0.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(colors.icon, color: colors.iconColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: AppTextStyles.displaySm
                              .copyWith(color: colors.titleColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastColors {
  final Color bg;
  final Color border;
  final Color iconColor;
  final Color titleColor;
  final IconData icon;

  const _ToastColors({
    required this.bg,
    required this.border,
    required this.iconColor,
    required this.titleColor,
    required this.icon,
  });

  factory _ToastColors.of(ToastType type) => switch (type) {
    ToastType.error => const _ToastColors(
      bg: Color(0xFF2A1212),
      border: Color(0xFF5A2020),
      iconColor: AppColors.danger,
      titleColor: Color(0xFFF08080),
      icon: Icons.cancel_rounded,
    ),
    ToastType.success => const _ToastColors(
      bg: Color(0xFF0D2A1A),
      border: Color(0xFF1A5C36),
      iconColor: AppColors.success,
      titleColor: Color(0xFF5EE0A0),
      icon: Icons.check_circle_rounded,
    ),
    ToastType.warning => const _ToastColors(
      bg: Color(0xFF2A1E0A),
      border: Color(0xFF6B4510),
      iconColor: AppColors.warning,
      titleColor: Color(0xFFF5C060),
      icon: Icons.warning_rounded,
    ),
  };
}