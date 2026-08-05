import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// حوار تقويم تفاعلي عالي الفخامة يسهّل اختيار السنة والشهر واليوم بلمسة واحدة.
class AppDatePickerDialog extends StatefulWidget {
  const AppDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.primaryColor,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Color? primaryColor;

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    Color? primaryColor,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppDatePickerDialog(
        initialDate: initialDate,
        firstDate: firstDate ?? DateTime(2020),
        lastDate: lastDate ?? DateTime(2035),
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<AppDatePickerDialog> createState() => _AppDatePickerDialogState();
}

class _AppDatePickerDialogState extends State<AppDatePickerDialog> {
  late DateTime _selectedDate;
  late int _viewYear;
  late int _viewMonth;

  // 0: أيام الشهر (التقويم), 1: اختيار الشهر, 2: اختيار السنة
  int _viewMode = 0;

  static const List<String> _arabicMonths = [
    'يناير (1)',
    'فبراير (2)',
    'مارس (3)',
    'أبريل (4)',
    'مايو (5)',
    'يونيو (6)',
    'يوليو (7)',
    'أغسطس (8)',
    'سبتمبر (9)',
    'أكتوبر (10)',
    'نوفمبر (11)',
    'ديسمبر (12)',
  ];

  static const List<String> _weekDays = [
    'أحد',
    'إثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _viewYear = widget.initialDate.year;
    _viewMonth = widget.initialDate.month;
  }

  Color get _accent => widget.primaryColor ?? AppColors.greenDeep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F2D1C) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textOnLight;
    final mutedTextColor =
        isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted;

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = (screenWidth * 0.48).clamp(320.0, 400.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      elevation: 0,
      child: Container(
        width: dialogWidth,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _accent.withValues(alpha: isDark ? 0.6 : 0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: isDark ? 0.3 : 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.15),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(23),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. الترويسة العلوية الفاخرة لعرض التاريخ المختار وتسهيل التنقل
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _accent,
                      _accent.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التاريخ المحدد',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('EEEE، d MMMM yyyy', 'ar')
                                .format(_selectedDate),
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // شريط أزرار التنقل السريع بين (السنة / الشهر / الأيام)
                    Row(
                      children: [
                        _buildHeaderModeTab(
                          label: 'السنة: $_viewYear',
                          selected: _viewMode == 2,
                          onTap: () => setState(
                              () => _viewMode = _viewMode == 2 ? 0 : 2),
                        ),
                        const SizedBox(width: 8),
                        _buildHeaderModeTab(
                          label: 'الشهر: ${_arabicMonths[_viewMonth - 1]}',
                          selected: _viewMode == 1,
                          onTap: () => setState(
                              () => _viewMode = _viewMode == 1 ? 0 : 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. جسم التقويم بحسب النمط المختار (أيام / أشهر / سنوات)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildBodyContent(isDark, textColor, mutedTextColor),
              ),

              // 3. شريط التأكيد والإلغاء السفلي
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: mutedTextColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_selectedDate),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.check_rounded, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'تأكيد التاريخ',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderModeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: selected ? _accent : Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              selected
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: selected ? _accent : Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(
      bool isDark, Color textColor, Color mutedTextColor) {
    if (_viewMode == 2) {
      return _buildYearPickerGrid(isDark, textColor);
    } else if (_viewMode == 1) {
      return _buildMonthPickerGrid(isDark, textColor);
    }

    return Column(
      key: const ValueKey('days_calendar'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
                onPressed: () {
                  setState(() {
                    if (_viewMonth == 1) {
                      _viewMonth = 12;
                      _viewYear--;
                    } else {
                      _viewMonth--;
                    }
                  });
                },
              ),
              GestureDetector(
                onTap: () => setState(() => _viewMode = 1),
                child: Row(
                  children: [
                    Text(
                      '${_arabicMonths[_viewMonth - 1]} $_viewYear',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down_rounded, color: _accent),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onPressed: () {
                  setState(() {
                    if (_viewMonth == 12) {
                      _viewMonth = 1;
                      _viewYear++;
                    } else {
                      _viewMonth++;
                    }
                  });
                },
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekDays
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _accent,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _buildDaysGrid(isDark, textColor),
        ),
      ],
    );
  }

  Widget _buildDaysGrid(bool isDark, Color textColor) {
    final firstDayOfMonth = DateTime(_viewYear, _viewMonth, 1);
    final daysInMonth = DateTime(_viewYear, _viewMonth + 1, 0).day;

    final firstWeekdayOffset = firstDayOfMonth.weekday % 7;
    final totalGridCells = firstWeekdayOffset + daysInMonth;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.1,
      ),
      itemCount: totalGridCells,
      itemBuilder: (context, index) {
        if (index < firstWeekdayOffset) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - firstWeekdayOffset + 1;
        final cellDate = DateTime(_viewYear, _viewMonth, dayNumber);
        final isSelected = cellDate.year == _selectedDate.year &&
            cellDate.month == _selectedDate.month &&
            cellDate.day == _selectedDate.day;

        final isToday = cellDate.year == DateTime.now().year &&
            cellDate.month == DateTime.now().month &&
            cellDate.day == DateTime.now().day;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = cellDate;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? _accent
                  : (isToday
                      ? _accent.withValues(alpha: 0.15)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isSelected
                  ? Border.all(color: _accent, width: 1)
                  : null,
            ),
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.5,
                  fontWeight:
                      isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : (isToday ? _accent : textColor),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthPickerGrid(bool isDark, Color textColor) {
    return Container(
      key: const ValueKey('months_grid'),
      padding: const EdgeInsets.all(14),
      height: 230,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthIndex = index + 1;
          final isSelected = _viewMonth == monthIndex;

          return InkWell(
            onTap: () {
              setState(() {
                _viewMonth = monthIndex;
                _viewMode = 0;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? _accent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _accent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Center(
                child: Text(
                  _arabicMonths[index],
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.5,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : textColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearPickerGrid(bool isDark, Color textColor) {
    final startYear = widget.firstDate.year;
    final totalYears = widget.lastDate.year - startYear + 1;

    return Container(
      key: const ValueKey('years_grid'),
      padding: const EdgeInsets.all(14),
      height: 230,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 2.0,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: totalYears,
        itemBuilder: (context, index) {
          final year = startYear + index;
          final isSelected = _viewYear == year;

          return InkWell(
            onTap: () {
              setState(() {
                _viewYear = year;
                _viewMode = 0;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? _accent
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.grey.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? _accent
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Center(
                child: Text(
                  '$year',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : textColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
