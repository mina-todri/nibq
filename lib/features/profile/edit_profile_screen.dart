// lib/features/profile/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  DateTime? _birthDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phoneNumber ?? '');
    _birthDate = user?.birthDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 10),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: colorScheme.copyWith(
            surface: colorScheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'تعديل الحساب'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.person, color: colorScheme.secondary, size: 48),
            ),
          ),
          const SizedBox(height: 32),

          AppTextField(
            label: 'الاسم الكامل',
            hint: 'محمد أحمد',
            controller: _nameCtrl,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'البريد الإلكتروني',
            hint: user?.email ?? '',
            readOnly: true,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),

          AppTextField(
            label: 'رقم الهاتف',
            hint: '01XXXXXXXXX',
            keyboardType: TextInputType.phone,
            controller: _phoneCtrl,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تاريخ الميلاد',
                style: AppTextStyles.labelMd.copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: colorScheme.onSurfaceVariant, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _birthDate != null
                            ? _formatDate(_birthDate!)
                            : 'اختر تاريخ الميلاد',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: _birthDate != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            label: 'حفظ التغييرات',
            loading: _isSaving,
            onPressed: _isSaving
                ? null
                : () async {
                    setState(() => _isSaving = true);
                    try {
                      await ref.read(authServiceProvider).updateUserProfile(
                            displayName: _nameCtrl.text.trim(),
                            phoneNumber: _phoneCtrl.text.trim(),
                            birthDate: _birthDate,
                          );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم حفظ التغييرات ✓')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('حدث خطأ: $e'),
                              backgroundColor: colorScheme.error),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
          ),
        ],
      ),
    );
  }
}
