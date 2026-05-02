import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _faqs = const [
    ('كيف أتتبع طلبي؟',
    'يمكنك متابعة حالة طلبك من قسم "طلباتي" في صفحة حسابك.'),
    ('ما هي سياسة الإرجاع؟',
    'يمكن إرجاع المنتجات خلال 7 أيام من الاستلام بشرط أن تكون بحالتها الأصلية.'),
    ('كم يستغرق التوصيل؟',
    'يستغرق التوصيل من 1 إلى 3 أيام عمل داخل المملكة العربية السعودية.'),
    ('هل يمكنني تغيير طلبي بعد تأكيده؟',
    'يمكن تعديل الطلب خلال ساعة من التأكيد. بعد ذلك لا يمكن إجراء تعديلات.'),
    ('ما طرق الدفع المتاحة؟',
    'نقبل البطاقات الائتمانية (Visa, Mastercard) ومدى وApple Pay وSTC Pay.'),
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfBg,
      appBar: const CustomAppBar(title: 'المساعدة والدعم'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('الأسئلة الشائعة',
              style: AppTextStyles.displayMd
                  .copyWith(color: AppColors.gold400)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: List.generate(_faqs.length, (i) {
                final (q, a) = _faqs[i];
                final open = _expanded.contains(i);
                return Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() {
                        if (open) {
                          _expanded.remove(i);
                        } else {
                          _expanded.add(i);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(q,
                                    style: AppTextStyles.bodyMd)),
                            Icon(
                              open
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (open)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Text(a,
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    if (i != _faqs.length - 1)
                      Divider(color: AppColors.borderSubtle, height: 1),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text('تواصل معنا',
              style: AppTextStyles.displayMd
                  .copyWith(color: AppColors.gold400)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _contactRow(Icons.email_outlined, 'البريد الإلكتروني',
                    'support@lift-store.com'),
                Divider(color: AppColors.borderSubtle, height: 20),
                _contactRow(Icons.phone_outlined, 'الهاتف', '920000000'),
                Divider(color: AppColors.borderSubtle, height: 20),
                _contactRow(Icons.access_time_outlined, 'أوقات العمل',
                    'الأحد - الخميس: 9ص - 9م'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold400, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.bodySm
                      .copyWith(color: AppColors.textTertiary)),
              Text(value, style: AppTextStyles.bodyMd),
            ],
          ),
        ),
      ],
    );
  }
}