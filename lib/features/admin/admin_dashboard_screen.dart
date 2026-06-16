// lib/features/admin/admin_dashboard_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/custom_app_bar.dart';
import '../../shared/widgets/loading_widget.dart';
import '../../shared/widgets/error_state_widget.dart';
import '../../core/models/order_model.dart';
import '../product/providers/product_provider.dart';
import 'admin_panel_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_inventory_screen.dart';
import 'admin_complaints_screen.dart';
import '../checkout/providers/order_providers.dart';
import '../notifications/providers/notifications_provider.dart';
import '../../core/services/mock_data_service.dart';

/// كائن الإحصائيات (أضفت إليه عدد الطلبات المعلقة وإجمالي المنتجات)
class AdminAnalytics {
  final double totalRevenue;
  final double totalDiscounts;
  final double deliverySuccessRate;
  final int lowStockCount;
  final int pendingOrdersCount;
  final int pendingComplaintsCount;
  final int totalProductsCount;
  final String topCategory;
  final double averageDailySales;

  AdminAnalytics({
    required this.totalRevenue,
    required this.totalDiscounts,
    required this.deliverySuccessRate,
    required this.lowStockCount,
    required this.pendingOrdersCount,
    required this.pendingComplaintsCount,
    required this.totalProductsCount,
    required this.topCategory,
    required this.averageDailySales,
  });
}

/// الـ Provider المسؤول عن حساب كل شيء خلف الكواليس لضمان سرعة الـ UI
final dashboardAnalyticsProvider = Provider<AsyncValue<AdminAnalytics>>((ref) {
  final ordersAsync = ref.watch(allOrdersProvider);
  final productsAsync = ref.watch(productsStreamProvider);
  final complaintsAsync = ref.watch(allComplaintsProvider);

  // 2. Refactored dashboardAnalyticsProvider using safe .when() combination
  return ordersAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, s) => AsyncError(e, s),
    data: (orders) => productsAsync.when(
      loading: () => const AsyncLoading(),
      error: (e, s) => AsyncError(e, s),
      data: (products) => complaintsAsync.when(
        loading: () => const AsyncLoading(),
        error: (e, s) => AsyncError(e, s),
        data: (complaints) {
          double revenue = 0;
          double discounts = 0;
          int deliveredCount = 0;
          int pendingCount = 0;
          Map<String, int> categorySales = {};

          for (final order in orders) {
            discounts += order.discount;
            if (order.status == OrderStatus.pending) pendingCount++;
            if (order.status == OrderStatus.delivered) {
              revenue += order.total;
              deliveredCount++;
              for (final item in order.items) {
                categorySales[item.category] =
                    (categorySales[item.category] ?? 0) + item.quantity;
              }
            }
          }

          String topCat = 'N/A';
          if (categorySales.isNotEmpty) {
            topCat = categorySales.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          }

          return AsyncData(AdminAnalytics(
            totalRevenue: revenue,
            totalDiscounts: discounts,
            deliverySuccessRate:
                orders.isEmpty ? 0.0 : (deliveredCount / orders.length) * 100,
            lowStockCount: products.where((p) => p.totalStock < 10).length,
            pendingOrdersCount: pendingCount,
            pendingComplaintsCount: complaints.where((c) => c['status'] == 'pending').length,
            totalProductsCount: products.length,
            topCategory: topCat,
            averageDailySales: revenue / 7,
          ));
        },
      ),
    ),
  );
});

final weeklySalesChartProvider = Provider<AsyncValue<List<FlSpot>>>((ref) {
  final ordersAsync = ref.watch(allOrdersProvider);
  return ordersAsync.whenData((orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<DateTime, double> dailyTotals = {};
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      dailyTotals[date] = 0.0;
    }
    for (final order in orders) {
      if (order.status != OrderStatus.delivered) continue;
      final d = order.createdAt;
      final orderDate = DateTime(d.year, d.month, d.day);
      if (dailyTotals.containsKey(orderDate)) {
        dailyTotals[orderDate] = dailyTotals[orderDate]! + order.total;
      }
    }
    final sortedDates = dailyTotals.keys.toList()..sort();
    return List.generate(7, (i) => FlSpot(i.toDouble(), dailyTotals[sortedDates[i]]!));
  });
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analyticsAsync = ref.watch(dashboardAnalyticsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfBg : AppColors.surfBgLight,
      appBar: CustomAppBar(
        title: 'لوحة تحكم المدير',
        actions: [
          IconButton(
            icon: const Icon(Icons.data_saver_on_outlined, color: AppColors.gold400),
            tooltip: 'تعبئة بيانات تجريبية',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تعبئة بيانات تجريبية'),
                  content: const Text('سيتم إضافة منتجات وإعدادات تجريبية لقاعدة البيانات. هل تريد الاستمرار؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم، ابدأ')),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await MockDataService().seedAllData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تمت إضافة البيانات التجريبية بنجاح ✓'), backgroundColor: AppColors.success),
                    );
                    ref.invalidate(productsStreamProvider);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل إضافة البيانات: $e'), backgroundColor: AppColors.danger),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, s) => ErrorStateWidget(message: 'فشل تحميل البيانات: $e'),
        data: (stats) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نظرة عامة',
                style: AppTextStyles.displayLg.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _StatCard(
                    title: 'إجمالي المبيعات',
                    value: _formatCurrency(stats.totalRevenue),
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                  _StatCard(
                    title: 'طلبات معلقة',
                    value: stats.pendingOrdersCount.toString(),
                    icon: Icons.pending_actions_rounded,
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                  _StatCard(
                    title: 'مخزون منخفض',
                    value: stats.lowStockCount.toString(),
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.danger,
                    isDark: isDark,
                  ),
                  _StatCard(
                    title: 'إجمالي المنتجات',
                    value: stats.totalProductsCount.toString(),
                    icon: Icons.grid_view_rounded,
                    color: AppColors.info,
                    isDark: isDark,
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _SalesChart(isDark: isDark),

              const SizedBox(height: 32),
              Text(
                'إجراءات سريعة',
                style: AppTextStyles.displayLg.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _ActionCard(
                    title: 'الطلبات',
                    subtitle: 'متابعة وتحديث',
                    icon: Icons.receipt_long_rounded,
                    iconBg: AppColors.gold400,
                    badgeCount: stats.pendingOrdersCount,
                    badgeColor: Colors.orange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminOrdersScreen())),
                    isDark: isDark,
                  ),
                  _ActionCard(
                    title: 'الشكاوى',
                    subtitle: 'شكاوى وملاحظات',
                    icon: Icons.report_problem_outlined,
                    iconBg: Colors.redAccent,
                    badgeCount: stats.pendingComplaintsCount,
                    badgeColor: AppColors.danger,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminComplaintsScreen())),
                    isDark: isDark,
                  ),
                  _ActionCard(
                    title: 'المخزون',
                    subtitle: 'تعديل سريع للكميات',
                    icon: Icons.inventory_2_outlined,
                    iconBg: Colors.blue,
                    badgeCount: stats.lowStockCount,
                    badgeColor: AppColors.danger,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminInventoryScreen())),
                    isDark: isDark,
                  ),
                  _ActionCard(
                    title: 'المنتجات',
                    subtitle: 'إضافة وتعديل وحذف',
                    icon: Icons.storefront_outlined,
                    iconBg: AppColors.info,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                    isDark: isDark,
                  ),
                  _ActionCard(
                    title: 'إعدادات المتجر',
                    subtitle: 'التوصيل والخصومات',
                    icon: Icons.settings_outlined,
                    iconBg: Colors.purple,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSettingsScreen())),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCurrency(double amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M EGP';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K EGP';
  return '${amount.toStringAsFixed(0)} EGP';
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight),
        boxShadow: [BoxShadow(color: color.withValues(alpha:0.04), blurRadius: 15, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha:0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: AppTextStyles.displayXl.copyWith(
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.bodySm.copyWith(
                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final VoidCallback onTap;
  final int badgeCount;
  final Color badgeColor;
  final bool isDark;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.onTap,
    this.badgeCount = 0,
    this.badgeColor = Colors.orange,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: iconBg),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark ? AppColors.textTertiary : AppColors.textTertiaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.surfBg : AppColors.surfBgLight, width: 3),
                    boxShadow: [BoxShadow(color: badgeColor.withValues(alpha:0.4), blurRadius: 8, offset: const Offset(0, 2))]
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '+99' : badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SalesChart extends ConsumerWidget {
  final bool isDark;
  const _SalesChart({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(weeklySalesChartProvider);
    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfRaised : AppColors.surfRaisedLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderSubtle : AppColors.borderSubtleLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 15, bottom: 20),
            child: Text(
              'منحنى المبيعات (آخر 7 أيام)',
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('خطأ: $e', style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight))),
              data: (spots) {
                if (spots.isEmpty) return Center(child: Text('لا توجد بيانات', style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight)));
                double maxY = 0;
                for (var spot in spots) {
                  if (spot.y > maxY) maxY = spot.y;
                }
                maxY = maxY < 100 ? 100 : maxY * 1.2;

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true, drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('E', 'ar').format(date),
                                style: AppTextStyles.bodyXs.copyWith(
                                  color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots, isCurved: true, color: AppColors.gold400, barWidth: 4, isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(show: true, color: AppColors.gold400.withValues(alpha:0.1)),
                      ),
                    ],
                    minY: 0, maxY: maxY,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
