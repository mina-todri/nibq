// lib/features/about/about_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'عن التطبيق'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App Logo/Branding
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'NIBQ',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'NIBQ STORE',
                  style: AppTextStyles.displayMd.copyWith(
                    color: colorScheme.onSurface,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'الإصدار 1.0.0',
                  style: AppTextStyles.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Main Description Section
          _sectionHeader(context, 'من نحن'),
          _infoCard(
            context,
            'NIBQ هو وجهتكم الأولى لكل ما يخص لوازم الفنون والرسم. نحن نؤمن بأن الإبداع يبدأ بالأدوات الصحيحة، لذا نسعى لتوفير أجود أنواع الألوان، الفرش، والأدوات الفنية التي تلهم الفنانين والمبدعين في رحلتهم الفنية.',
          ),
          
          const SizedBox(height: 24),

          _sectionHeader(context, 'معلومات قانونية'),
          _tile(
            context,
            Icons.policy_outlined,
            'سياسة الخصوصية',
            'نحن نولي أهمية قصوى لخصوصيتك. يتم تشفير كافة البيانات وحمايتها وفقاً لأعلى المعايير الأمنية.',
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            Icons.description_outlined,
            'الشروط والأحكام',
            'باستخدامك لتطبيق نِبْق، فإنك توافق على شروط الخدمة وسياسات التوصيل والاسترجاع الخاصة بنا.',
          ),
          
          const SizedBox(height: 24),

          _sectionHeader(context, 'تواصل معنا'),
          _tile(
            context,
            Icons.email_outlined,
            'الدعم الفني',
            'support@nibq-store.com',
          ),
          const SizedBox(height: 12),
          _tile(
            context,
            Icons.language_outlined,
            'الموقع الإلكتروني',
            'www.nibq-store.com',
          ),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'صنع بكل حب لدعم الفن العربي ❤️',
              style: AppTextStyles.bodyXs.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Text(
        title,
        style: AppTextStyles.bodyMd.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodyMd.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String body) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: AppTextStyles.bodySm.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
