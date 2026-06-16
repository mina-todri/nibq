// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/routing/app_router.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // (3) Consume currentUserProvider safely
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(body: LoadingWidget());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'حسابي', showBack: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.person, color: colorScheme.secondary, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? 'المستخدم',
                        style: AppTextStyles.displayLg.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                        Text(
                          user.phoneNumber!,
                          style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha:0.7)),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                  onPressed: () => Navigator.pushNamed(context, AppRouter.editProfile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _section(context, [
            _Tile(Icons.shopping_bag_outlined, 'طلباتي', () => Navigator.pushNamed(context, AppRouter.orders)),
            _Tile(Icons.favorite_border, 'المفضلة', () => Navigator.pushNamed(context, AppRouter.favorites)),
            _Tile(Icons.location_on_outlined, 'العناوين', () => Navigator.pushNamed(context, AppRouter.addresses)),
          ]),
          const SizedBox(height: 12),

          _section(context, [
            _Tile(Icons.settings_outlined, 'الإعدادات', () => Navigator.pushNamed(context, AppRouter.settings)),
            _Tile(Icons.help_outline, 'المساعدة والدعم', () => Navigator.pushNamed(context, AppRouter.help)),
            _Tile(Icons.info_outline, 'عن التطبيق', () => Navigator.pushNamed(context, AppRouter.about)),
          ]),

          if (user.role == UserRole.admin) ...[
            const SizedBox(height: 12),
            _section(context, [
              _Tile(
                Icons.admin_panel_settings_outlined,
                'لوحة التحكم (مسؤول)',
                () => Navigator.pushNamed(context, AppRouter.admin),
              ),
            ]),
          ],
          const SizedBox(height: 12),

          _section(context, [
            _Tile(
              Icons.logout,
              'تسجيل الخروج',
              () => _confirmLogout(context, ref),
              danger: true,
            ),
          ]),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('خروج', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
      }
    }

  }

  Widget _section(BuildContext context, List<_Tile> tiles) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i != tiles.length - 1)
              Divider(color: colorScheme.outlineVariant, height: 1),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _Tile(this.icon, this.title, this.onTap, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = danger ? colorScheme.error : colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.bodyMd.copyWith(color: color))),
            Icon(Icons.arrow_forward_ios, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
