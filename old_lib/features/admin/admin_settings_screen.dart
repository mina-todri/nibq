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
  final _discountCodeCtrl = TextEditingController();
  final _discountPctCtrl = TextEditingController();
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
    _discountCodeCtrl.dispose();
    _discountPctCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final settings = await ref.read(globalSettingsRepoProvider).getSettings();
    _deliveryCtrl.text = settings.deliveryFee.toString();
    _discountCodeCtrl.text = settings.discountCode;
    _discountPctCtrl.text = settings.discountPercentage.toString();
    _freeDelivery = settings.freeDelivery;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final settings = GlobalSettings(
      deliveryFee: double.tryParse(_deliveryCtrl.text) ?? 0,
      discountCode: _discountCodeCtrl.text.trim(),
      discountPercentage: double.tryParse(_discountPctCtrl.text) ?? 0,
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
                  Text('رسوم التوصيل والخصومات', style: AppTextStyles.displayLg),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'رسوم التوصيل (EGP)',
                    controller: _deliveryCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('توصيل مجاني لجميع الطلبات'),
                    value: _freeDelivery,
                    onChanged: (val) => setState(() => _freeDelivery = val),
                    activeColor: AppColors.gold400,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'كود الخصم العالمي (اختياري)',
                    controller: _discountCodeCtrl,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'نسبة الخصم (%)',
                    controller: _discountPctCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 30),
                  PrimaryButton(label: 'حفظ الإعدادات', onPressed: _save),
                ],
              ),
            ),
    );
  }
}
