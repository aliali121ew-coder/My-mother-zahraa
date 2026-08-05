import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/girih_pattern.dart';
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
        blur: true,
        radius: AppTheme.radiusLarge,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        gradient: isDark
            ? AppColors.totalCardGradient
            : const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF1B5938), Color(0xFF103A24)],
              ),
        borderColor: Colors.transparent,
        onTap: onTap,
        child: Stack(
          children: [
            // خلفية زخرفية ناعمة في الزاوية
            const Positioned(
              left: -35,
              bottom: -35,
              child: GirihPattern(size: 170, opacity: 0.10),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.rank1Gradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.greenAbyss,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المبلغ الكلي',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldBright,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.paid,
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'موقف المالي الحي',
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 11,
                                  color: AppColors.textOnDarkMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (onTap != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.goldBright,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (loading)
                  const _ShimmerBar(width: 190, height: 42)
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
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnDark,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'مجموع الاشتراكات والتبرعات النقدية',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.5,
                        color: AppColors.textOnDark.withValues(alpha: 0.72),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'مُعتمد',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.goldBright,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
      blur: true,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      gradient: isDark ? AppColors.countCardGradient : null,
      borderColor: AppColors.gold.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppColors.goldBright : AppColors.goldDark,
                  size: 20,
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.overdue.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.overdue.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.overdue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        badge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.overdue,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
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
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
            ),
          ),
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
