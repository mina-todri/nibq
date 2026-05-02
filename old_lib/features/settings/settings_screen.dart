// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../auth/providers/auth_provider.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final isDark = settings.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'الإعدادات'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionTitle('عام'),
          _card(
            isDark: isDark,
            child: Column(
              children: [
                _navTile(
                  isDark: isDark,
                  icon: Icons.language,
                  title: 'اللغة',
                  value: settings.isArabic ? 'العربية' : 'English',
                  onTap: () => ref.read(settingsProvider.notifier).toggleLocale(),
                ),
                _divider(isDark),
                _navTile(
                  isDark: isDark,
                  icon: isDark ? Icons.dark_mode : Icons.light_mode,
                  title: 'المظهر',
                  value: isDark ? 'داكن' : 'فاتح',
                  onTap: () => ref.read(settingsProvider.notifier).toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('الإشعارات'),
          _card(
            isDark: isDark,
            child: Column(
              children: [
                _switchTile(
                  'عروض وخصومات',
                  settings.notifyOffers,
                  (v) => ref.read(settingsProvider.notifier).setNotifOffers(v),
                ),
                _divider(isDark),
                _switchTile(
                  'تحديثات الطلبات',
                  settings.notifyOrders,
                  (v) => ref.read(settingsProvider.notifier).setNotifOrders(v),
                ),
                _divider(isDark),
                _switchTile(
                  'تحديثات التطبيق',
                  settings.notifyUpdates,
                  (v) => ref.read(settingsProvider.notifier).setNotifUpdates(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('الحساب'),
          _card(
            isDark: isDark,
            child: Column(
              children: [
                _navTile(isDark: isDark, icon: Icons.lock_outline, title: 'الخصوصية والأمان', value: ''),
                _divider(isDark),
                _navTile(isDark: isDark, icon: Icons.description_outlined, title: 'الشروط والأحكام', value: ''),
                _divider(isDark),
                _navTile(isDark: isDark, icon: Icons.help_outline, title: 'المساعدة', value: ''),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _card(
            isDark: isDark,
            child: Column(
              children: [
                _dangerTile(Icons.logout, 'تسجيل الخروج', onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('تسجيل الخروج'),
                      content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('إلغاء')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('خروج')),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(authProvider.notifier).signOut();
                  }
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'الإصدار 1.0.0',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        child: Text(
          t,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.gold400,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _card({required Widget child, required bool isDark}) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight),
        ),
        child: child,
      );

  Widget _divider(bool isDark) => Divider(color: isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight, height: 1);

  Widget _navTile({required bool isDark, required IconData icon, required String title, required String value, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight, size: 20),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.bodyMd.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight))),
            if (value.isNotEmpty)
              Text(
                value,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark ? AppColors.textTertiary : AppColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.bodyMd)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.gold400,
            activeTrackColor: AppColors.gold400.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _dangerTile(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.danger, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
