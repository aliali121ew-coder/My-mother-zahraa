import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass.dart';

/// كارت المبلغ الكلي العريض (1×1) في أعلى الرئيسية.
///
/// حماية من الـoverflow: المبلغ داخل [FittedBox] بمقياس تصغير، فلو بلغ
/// المجموع مليارات على شاشة ضيقة (٣٢٠ بكسل) يتقلّص الخط بدل أن يفيض.
class TotalAmountCard extends StatelessWidget {
  const TotalAmountCard({
    super.key,
    required this.total,
    this.onTap,
    this.loading = false,
  });

  final num total;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GoldBorder(
      radius: AppTheme.radiusLarge,
      child: GlassCard(
        blur: true, // كارت ثابت واحد — التمويه هنا آمن على الأداء
        radius: AppTheme.radiusLarge,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        gradient: isDark
            ? AppColors.totalCardGradient
            : const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [AppColors.green, AppColors.greenMid],
              ),
        borderColor: Colors.transparent,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.savings_outlined,
                    color: AppColors.goldBright,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'المبلغ الكلي',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldBright,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_left_rounded,
                    color: AppColors.goldBright.withValues(alpha: 0.7),
                    size: 26,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (loading)
              const _ShimmerBar(width: 190, height: 38)
            else
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  Fmt.money(total),
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDark,
                    height: 1.1,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'مجموع الاشتراكات والتبرعات النقدية',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12.5,
                color: AppColors.textOnDark.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// كارت عدد (المتبرعين أو المشتركين) — يوضع في صف 2×1 تحت كارت المبلغ.
class CountCard extends StatelessWidget {
  const CountCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    this.badge,
    this.onTap,
    this.loading = false,
  });

  final String label;
  final int count;
  final IconData icon;

  /// شارة صغيرة مثل «٣ متأخرون»
  final String? badge;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      blur: true, // كارتان ثابتان فقط في الشاشة
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      gradient: isDark ? AppColors.countCardGradient : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 22),
          const SizedBox(height: 14),
          if (loading)
            const _ShimmerBar(width: 54, height: 26)
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                Fmt.count(count),
                maxLines: 1,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (badge != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.overdue.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.overdue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// شريط تحميل بسيط بلا حزمة خارجية — أخف من shimmer داخل القوائم
class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
