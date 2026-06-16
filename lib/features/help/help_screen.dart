import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../auth/providers/auth_provider.dart';
import '../notifications/providers/notifications_provider.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  final _faqs = const [
    ('كم تستغرق مدة التوصيل؟',
    'نقوم بالتوصيل داخل مدينة 6 أكتوبر خلال 60 إلى 120 دقيقة كحد أقصى من وقت تأكيد الطلب، لضمان وصول أدواتك في أسرع وقت.'),
    ('ما هي المناطق المشمولة بالتوصيل؟',
    'حالياً نوفر الخدمة لجميع أحياء مدينة 6 أكتوبر (الشيخ زايد، الأحياء من 1 لـ 12، حدائق أكتوبر، والتوسعات الشمالية).'),
    ('كيف تضمنون جودة الأدوات؟',
    'نتعاقد مع كبرى المكتبات الموثوقة في مدينة أكتوبر لنضمن لك توفر كافة الأدوات الدراسية والفنية الأصلية بأفضل جودة.'),
    ('هل يمكنني الطلب من أكثر من مكتبة؟',
    'نعم، يمكنك اختيار منتجات من مكتبات مختلفة في طلب واحد، وسيقوم فريق التوصيل بتجميعها لك وتوصيلها في أسرع وقت.'),
    ('ماذا أفعل إذا استلمت منتجاً غير مطلوب؟',
    'يرجى إبلاغ المندوب فوراً أو التواصل معنا عبر الواتساب خلال ساعة من الاستلام، وسنقوم بتبديل المنتج مجاناً وبدون أي رسوم إضافية.'),
  ];

  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark 
          ? AppColors.surfBg 
          : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'المساعدة والدعم'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'الأسئلة الشائعة',
            style: AppTextStyles.displayMd.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
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
                      borderRadius: i == 0 
                          ? const BorderRadius.vertical(top: Radius.circular(14))
                          : i == _faqs.length - 1 && !open
                              ? const BorderRadius.vertical(bottom: Radius.circular(14))
                              : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                q,
                                style: AppTextStyles.bodyMd.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              open
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (open)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: Text(
                          a,
                          style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    if (i != _faqs.length - 1)
                      Divider(color: colorScheme.outlineVariant, height: 1),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'تواصل معنا مباشرة',
            style: AppTextStyles.displayMd.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                _contactRow(Icons.email_outlined, 'البريد الإلكتروني',
                    'support@nibq-store.com', colorScheme),
                Divider(color: colorScheme.outlineVariant, height: 24),
                _contactRow(Icons.message_outlined, 'واتساب', '010XXXXXXXX', colorScheme),
                Divider(color: colorScheme.outlineVariant, height: 24),
                _contactRow(Icons.access_time_outlined, 'أوقات العمل',
                    'يومياً: 10 ص - 10 م', colorScheme),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => _showGeneralComplaintDialog(context),
              icon: const Icon(Icons.feedback_outlined),
              label: const Text('إرسال شكوى أو اقتراح', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showGeneralComplaintDialog(BuildContext context) {
    final msgCtrl = TextEditingController();
    String type = 'app';
    final user = ref.read(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'إرسال شكوى/ملاحظة',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: type,
                dropdownColor: colorScheme.surfaceContainerHighest,
                style: TextStyle(color: colorScheme.onSurface),
                items: const [
                  DropdownMenuItem(value: 'app', child: Text('مشكلة في التطبيق')),
                  DropdownMenuItem(value: 'account', child: Text('مشكلة في الحساب')),
                  DropdownMenuItem(value: 'suggestion', child: Text('اقتراح جديد')),
                  DropdownMenuItem(value: 'other', child: Text('أخرى')),
                ],
                onChanged: (v) => setState(() => type = v!),
                decoration: InputDecoration(
                  labelText: 'نوع الملاحظة',
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: msgCtrl,
                maxLines: 4,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظاتك هنا...',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (msgCtrl.text.trim().isEmpty) return;
                await ref.read(supportRepositoryProvider).sendComplaint(
                  userId: user?.uid ?? 'unknown',
                  userName: user?.displayName ?? 'Guest',
                  orderId: null,
                  type: type,
                  message: msgCtrl.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال ملاحظتك بنجاح')));
                }
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySm.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
