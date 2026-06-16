// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../auth/providers/auth_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isArabic = settings.isArabic;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(title: isArabic ? 'الإعدادات' : 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle(context, isArabic ? 'عام' : 'General', isArabic),
          _card(
            context,
            child: Column(
              children: [
                _navTile(
                  context,
                  icon: Icons.language,
                  title: isArabic ? 'اللغة' : 'Language',
                  value: isArabic ? 'العربية' : 'English',
                  onTap: () => ref.read(settingsProvider.notifier).toggleLocale(),
                  isArabic: isArabic,
                ),
                _divider(context),
                _navTile(
                  context,
                  icon: settings.isDark ? Icons.dark_mode : Icons.light_mode,
                  title: isArabic ? 'المظهر' : 'Appearance',
                  value: isArabic ? (settings.isDark ? 'داكن' : 'فاتح') : (settings.isDark ? 'Dark' : 'Light'),
                  onTap: () => ref.read(settingsProvider.notifier).toggleTheme(),
                  isArabic: isArabic,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, isArabic ? 'الإشعارات' : 'Notifications', isArabic),
          _card(
            context,
            child: Column(
              children: [
                _switchTile(
                  context,
                  isArabic ? 'عروض وخصومات' : 'Offers & Discounts',
                  settings.notifyOffers,
                  (v) => ref.read(settingsProvider.notifier).setNotifOffers(v),
                ),
                _divider(context),
                _switchTile(
                  context,
                  isArabic ? 'تحديثات الطلبات' : 'Order Updates',
                  settings.notifyOrders,
                  (v) => ref.read(settingsProvider.notifier).setNotifOrders(v),
                ),
                _divider(context),
                _switchTile(
                  context,
                  isArabic ? 'تحديثات التطبيق' : 'App Updates',
                  settings.notifyUpdates,
                  (v) => ref.read(settingsProvider.notifier).setNotifUpdates(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, isArabic ? 'الحساب' : 'Account', isArabic),
          _card(
            context,
            child: Column(
              children: [
                _navTile(context, icon: Icons.lock_outline, title: isArabic ? 'الخصوصية والأمان' : 'Privacy & Security', value: '', isArabic: isArabic),
                _divider(context),
                _navTile(context, icon: Icons.description_outlined, title: isArabic ? 'الشروط والأحكام' : 'Terms & Conditions', value: '', isArabic: isArabic),
                _divider(context),
                _navTile(context, icon: Icons.help_outline, title: isArabic ? 'المساعدة' : 'Help', value: '', isArabic: isArabic),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _card(
            context,
            child: Column(
              children: [
                _dangerTile(context, Icons.logout, isArabic ? 'تسجيل الخروج' : 'Logout', onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: colorScheme.surface,
                      title: Text(isArabic ? 'تسجيل الخروج' : 'Logout', style: TextStyle(color: colorScheme.onSurface)),
                      content: Text(isArabic ? 'هل أنت متأكد من تسجيل الخروج؟' : 'Are you sure you want to logout?', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(isArabic ? 'إلغاء' : 'Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(isArabic ? 'خروج' : 'Logout', style: TextStyle(color: colorScheme.error))),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.pop(context); // Close settings screen
                    }
                  }
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${isArabic ? 'الإصدار' : 'Version'} 1.0.0',
              style: AppTextStyles.bodySm.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t, bool isArabic) => Padding(
        padding: EdgeInsets.only(bottom: 8, right: isArabic ? 4 : 0, left: isArabic ? 0 : 4),
        child: Text(
          t,
          style: AppTextStyles.bodySm.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _card(BuildContext context, {required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: child,
      );

  Widget _divider(BuildContext context) => Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1);

  Widget _navTile(BuildContext context, {required IconData icon, required String title, required String value, VoidCallback? onTap, required bool isArabic}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.bodyMd.copyWith(color: colorScheme.onSurface))),
            if (value.isNotEmpty)
              Text(
                value,
                style: AppTextStyles.bodySm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(BuildContext context, String title, bool value, ValueChanged<bool> onChanged) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.bodyMd.copyWith(color: colorScheme.onSurface))),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _dangerTile(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.error, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMd.copyWith(color: colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
