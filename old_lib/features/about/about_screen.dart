// lib/features/about/about_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'عن التطبيق'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.gold400.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderAccent),
              ),
              child: const Center(
                child: Text(
                  'NIBQ',
                  style: TextStyle(
                    color: AppColors.gold300,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'الإصدار 1.0.0',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _tile(
            context,
            Icons.info_outline,
            'عن التطبيق',
            'NIBQ هو متجر إلكتروني متخصص في المنتجات الراقية والساعات والعطور الفاخرة.',
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            Icons.policy_outlined,
            'سياسة الخصوصية',
            'نلتزم بحماية بيانات المستخدمين وعدم مشاركتها مع أي طرف ثالث دون إذن.',
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            Icons.description_outlined,
            'الشروط والأحكام',
            'باستخدام التطبيق فإنك توافق على شروطنا وأحكامنا المعمول بها.',
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            Icons.support_agent_outlined,
            'تواصل معنا',
            'support@nibq-store.com',
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String body) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.gold400, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
