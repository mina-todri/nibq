// lib/features/admin/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../settings/providers/global_settings_provider.dart';
import '../../core/services/global_settings_repository.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/routing/app_router.dart';

final globalSettingsRepoProvider = Provider((ref) => GlobalSettingsRepository());

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _deliveryCtrl = TextEditingController();
  bool _freeDelivery = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _deliveryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await ref.read(globalSettingsRepoProvider).getSettings();
    _deliveryCtrl.text = settings.deliveryFee.toString();
    _freeDelivery = settings.freeDelivery;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final settings = GlobalSettings(
      deliveryFee: double.tryParse(_deliveryCtrl.text) ?? 0,
      freeDelivery: _freeDelivery,
    );
    
    try {
      await ref.read(globalSettingsRepoProvider).updateSettings(settings);
      ref.invalidate(globalSettingsProvider); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات ✓')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    if (!isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عذراً، غير مسموح لك بالدخول لهذه الصفحة'), backgroundColor: AppColors.danger),
        );
        AppRouter.navigateToHome(context);
      });
      return const Scaffold();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: const CustomAppBar(title: 'إعدادات المتجر'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'رسوم التوصيل',
                    style: AppTextStyles.displayLg.copyWith(color: primaryColor),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'رسوم التوصيل الافتراضية (EGP)',
                    controller: _deliveryCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderDefaultLight),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'توصيل مجاني لجميع الطلبات حالياً',
                        style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      subtitle: Text(
                        'سيتم تجاهل رسوم التوصيل عند تفعيل هذا الخيار',
                        style: AppTextStyles.bodySm.copyWith(color: secondaryColor),
                      ),
                      value: _freeDelivery,
                      onChanged: (val) => setState(() => _freeDelivery = val),
                      activeThumbColor: AppColors.gold400,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                  ),
                  const SizedBox(height: 30),
                  PrimaryButton(label: 'حفظ الإعدادات', onPressed: _isLoading ? null : _save),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.info),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'تم نقل إدارة الكوبونات إلى قسم منفذ لزيادة الأمان.',
                            style: AppTextStyles.bodySm.copyWith(color: AppColors.info),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
