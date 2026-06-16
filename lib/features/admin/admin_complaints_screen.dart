import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../notifications/providers/notifications_provider.dart';
import '../checkout/providers/order_providers.dart';
import '../orders/order_detail_screen.dart';

class AdminComplaintsScreen extends ConsumerWidget {
  const AdminComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(allComplaintsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'الشكاوى والملاحظات'),
      body: complaintsAsync.when(
        loading: () => const LoadingWidget(),
        error: (err, _) => ErrorStateWidget(message: 'فشل تحميل الشكاوى: $err'),
        data: (complaints) {
          if (complaints.isEmpty) {
            return const Center(child: Text('لا توجد شكاوى حالياً'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: complaints.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = complaints[i];
              return _ComplaintTile(complaint: c, isDark: isDark);
            },
          );
        },
      ),
    );
  }
}

class _ComplaintTile extends ConsumerWidget {
  final Map<String, dynamic> complaint;
  final bool isDark;

  const _ComplaintTile({required this.complaint, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = complaint['createdAt'] != null 
        ? DateFormat('yyyy/MM/dd HH:mm').format((complaint['createdAt'] as dynamic).toDate())
        : '';
    final isPending = complaint['status'] == 'pending';
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final tertiaryColor = isDark ? AppColors.textTertiary : AppColors.textTertiaryLight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? AppColors.gold400.withValues(alpha:0.3) : (isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TypeBadge(type: complaint['type'] ?? ''),
              Text(date, style: AppTextStyles.bodyXs.copyWith(color: tertiaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'من: ${complaint['userName'] ?? 'غير معروف'}',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
          ),
          if (complaint['orderId'] != null)
            GestureDetector(
              onTap: () => _viewOrder(context, ref, complaint['orderId']),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'بخصوص طلب رقم: ${complaint['orderId']}',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.gold400, decoration: TextDecoration.underline),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white.withValues(alpha:0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              complaint['message'] ?? '',
              style: AppTextStyles.bodySm.copyWith(height: 1.5, color: secondaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isPending)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showResolveDialog(context, ref),
                  icon: const Icon(Icons.reply, size: 18),
                  label: const Text('رد وحل الشكوى'),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                        const SizedBox(width: 4),
                        Text('تمت المعالجة', style: AppTextStyles.bodySm.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (complaint['adminResponse'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'ردك: ${complaint['adminResponse']}',
                          style: AppTextStyles.bodyXs.copyWith(color: secondaryColor, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(BuildContext context, WidgetRef ref) {
    final responseCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حل الشكوى والرد على العميل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يمكنك كتابة رسالة اعتذار أو توضيح للعميل، ستصله كإشعار فوراً.'),
            const SizedBox(height: 16),
            TextField(
              controller: responseCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'مثلاً: نعتذر جداً عما حدث، تم تعويضك بخصم خاص...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final response = responseCtrl.text.trim();
              if (response.isEmpty) return;
              
              await ref.read(supportRepositoryProvider).resolveComplaint(
                complaint['id'],
                adminResponse: response,
                userId: complaint['userId'],
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الرد وحل الشكوى')));
              }
            },
            child: const Text('إرسال الرد وحل الشكوى'),
          ),
        ],
      ),
    );
  }

  void _viewOrder(BuildContext context, WidgetRef ref, String orderId) async {
    showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final order = await ref.read(orderByIdProvider(orderId).future);
      if (context.mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    String label = '';
    Color color = Colors.grey;
    switch (type) {
      case 'order': label = 'الطلب'; color = Colors.blue; break;
      case 'delivery': label = 'التوصيل'; color = Colors.orange; break;
      case 'product': label = 'المنتجات'; color = Colors.purple; break;
      case 'app': label = 'التطبيق'; color = Colors.teal; break;
      case 'account': label = 'الحساب'; color = Colors.indigo; break;
      case 'suggestion': label = 'اقتراح'; color = AppColors.success; break;
      default: label = 'أخرى'; color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha:0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppTextStyles.bodyXs.copyWith(color: color, fontWeight: FontWeight.bold)),
    );
  }
}
