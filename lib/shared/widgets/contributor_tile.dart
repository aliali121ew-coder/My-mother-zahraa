import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass.dart';
import '../models/contributor_model.dart';
import '../models/enums.dart';

/// كارت مساهم (متبرع أو مشترك) داخل قائمة عمودية.
///
/// **قرار أداء:** يستخدم `GlassCard(blur: false)` — نفس المظهر الزجاجي
/// بتدرّج مطلي مسبقاً بلا [BackdropFilter]. لو استخدمنا التمويه هنا لانهار
/// معدّل الإطارات، لأن كل عنصر في القائمة سيعيد حساب التمويه في كل إطار.
class ContributorTile extends StatelessWidget {
  const ContributorTile({
    super.key,
    required this.contributor,
    this.rank,
    this.onTap,
    this.showStatus = false,
    this.hideName = false,
  });

  final ContributorModel contributor;

  /// المرتبة في قائمة الأعلى تبرّعاً — الأوائل الثلاثة يحصلون على وسام
  final int? rank;
  final VoidCallback? onTap;

  /// يعرض شارة مسدد/متأخر — للمشتركين
  final bool showStatus;

  /// يخفي الاسم لدور العضو الذي لا يُصرَّح له برؤية الأسماء
  final bool hideName;

  bool get _hasMedal => rank != null && rank! <= 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = contributor;
    final amount = c.isSubscriber ? c.subscriptionAmount : c.totalPaid;

    final isRank1 = rank == 1;
    final isRank2 = rank == 2;
    final isRank3 = rank == 3;

    final borderColor = isRank1
        ? AppColors.gold.withValues(alpha: 0.75)
        : isRank2
            ? AppColors.silverMedal.withValues(alpha: 0.6)
            : isRank3
                ? AppColors.bronzeMedal.withValues(alpha: 0.6)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.gold.withValues(alpha: 0.15));

    final cardGradient = isRank1 && isDark
        ? LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.gold.withValues(alpha: 0.16),
              AppColors.greenDeep.withValues(alpha: 0.8),
            ],
          )
        : null;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderColor: borderColor,
      gradient: cardGradient,
      child: Row(
        children: [
          _Avatar(contributor: c, rank: rank, hideName: hideName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hideName ? 'مساهم مُخفى الاسم' : c.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 15.5,
                          fontWeight: _hasMedal ? FontWeight.w700 : FontWeight.w600,
                          color: isRank1
                              ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                              : (isDark ? AppColors.textOnDark : AppColors.textOnLight),
                        ),
                      ),
                    ),
                    if (_hasMedal) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: switch (rank!) {
                            1 => AppColors.rank1Gradient,
                            2 => AppColors.rank2Gradient,
                            _ => AppColors.rank3Gradient,
                          },
                          boxShadow: [
                            BoxShadow(
                              color: (switch (rank!) {
                                1 => AppColors.gold,
                                2 => AppColors.silverMedal,
                                _ => AppColors.bronzeMedal,
                              })
                                  .withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Icon(
                          switch (rank!) {
                            1 => Icons.emoji_events_rounded,
                            2 => Icons.workspace_premium_rounded,
                            _ => Icons.military_tech_rounded,
                          },
                          size: 14,
                          color: AppColors.greenAbyss,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          Fmt.moneyShort(amount),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: isRank1
                                ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                                : (isDark ? AppColors.gold : AppColors.goldDark),
                          ),
                        ),
                      ),
                    ),
                    if (c.isSubscriber && c.subscriptionType != null) ...[
                      _dot(context),
                      Text(
                        c.subscriptionType!.label,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (!c.isSubscriber && c.lastPaymentAt != null) ...[
                      _dot(context),
                      Flexible(
                        child: Text(
                          Fmt.dateShort(c.lastPaymentAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (showStatus) ...[
            const SizedBox(width: 8),
            _StatusChip(status: c.paymentStatus),
          ],
          if (c.pendingSync) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.cloud_upload_outlined,
              size: 16,
              color: AppColors.pending.withValues(alpha: 0.9),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dot(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context)
                .textTheme
                .bodySmall
                ?.color
                ?.withValues(alpha: 0.5),
          ),
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.contributor, this.rank, this.hideName = false});

  final ContributorModel contributor;
  final int? rank;
  final bool hideName;

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    final url = contributor.photoUrl;
    final letter = hideName || contributor.fullName.isEmpty
        ? '؟'
        : contributor.fullName.characters.first;

    Widget inner;
    if (url != null && url.isNotEmpty && !hideName) {
      inner = CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        memCacheWidth: 132,
        placeholder: (_, _) => _letterBox(context, letter),
        errorWidget: (_, _, _) => _letterBox(context, letter),
      );
    } else {
      inner = _letterBox(context, letter);
    }

    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: rank == 1
              ? AppColors.gold
              : rank == 2
                  ? AppColors.silverMedal
                  : rank == 3
                      ? AppColors.bronzeMedal
                      : AppColors.gold.withValues(alpha: 0.3),
          width: rank != null && rank! <= 3 ? 2.0 : 1.0,
        ),
      ),
      child: ClipOval(child: SizedBox(width: size, height: size, child: inner)),
    );

    if (rank == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? AppColors.rank1Gradient
                  : rank == 2
                      ? AppColors.rank2Gradient
                      : rank == 3
                          ? AppColors.rank3Gradient
                          : null,
              color: rank! > 3 ? AppColors.greenMid : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 1.6,
              ),
            ),
            child: Text(
              Fmt.count(rank),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: rank! <= 3 ? AppColors.greenAbyss : AppColors.textOnDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _letterBox(BuildContext context, String letter) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.gold.withValues(alpha: 0.30),
              AppColors.green.withValues(alpha: 0.45),
            ],
          ),
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.goldBright,
            ),
          ),
        ),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final paid = status == PaymentStatus.paid;
    final color = paid ? AppColors.paid : AppColors.overdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
