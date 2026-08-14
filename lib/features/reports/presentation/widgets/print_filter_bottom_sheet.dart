import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

class PrintFilterResult {
  final int year;
  final int? month; // null means annual

  PrintFilterResult({required this.year, this.month});
}

class PrintFilterBottomSheet extends StatefulWidget {
  const PrintFilterBottomSheet({super.key});

  /// Displays the bottom sheet and returns the selected filter or null if cancelled.
  static Future<PrintFilterResult?> show(BuildContext context) {
    return showModalBottomSheet<PrintFilterResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrintFilterBottomSheet(),
    );
  }

  @override
  State<PrintFilterBottomSheet> createState() => _PrintFilterBottomSheetState();
}

class _PrintFilterBottomSheetState extends State<PrintFilterBottomSheet> {
  bool isMonthly = true;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  final List<int> years = List.generate(10, (index) => DateTime.now().year - index);
  final List<int> months = List.generate(12, (index) => index + 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 100, // هامش إضافي لتجنب شريط التنقل السفلي العائم
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.print_rounded, color: isDark ? AppColors.goldBright : AppColors.goldDark),
              const SizedBox(width: 12),
              Text(
                'خيارات الطباعة',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Toggle Annual / Monthly
          Row(
            children: [
              Expanded(
                child: _buildTab(
                  title: 'تقرير شهري',
                  isSelected: isMonthly,
                  onTap: () => setState(() => isMonthly = true),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTab(
                  title: 'تقرير سنوي',
                  isSelected: !isMonthly,
                  onTap: () => setState(() => isMonthly = false),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Dropdowns
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('السنة', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedYear,
                          isExpanded: true,
                          items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedYear = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isMonthly) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الشهر', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedMonth,
                            isExpanded: true,
                            items: months.map((m) => DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => selectedMonth = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(
                context,
                PrintFilterResult(
                  year: selectedYear,
                  month: isMonthly ? selectedMonth : null,
                ),
              );
            },
            icon: const Icon(Icons.print_rounded),
            label: Text('استمرار', style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? AppColors.goldBright : AppColors.goldDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? Colors.white12 : Colors.black12),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            color: isSelected ? activeColor : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
