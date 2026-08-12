import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass.dart';
import '../models/contributor_model.dart';
import '../models/enums.dart';

/// كارت مساهم (متبرع أو مشترك) داخل قائمة عمودية.
class ContributorTile extends ConsumerWidget {
  const ContributorTile({
    super.key,
    required this.contributor,
    this.rank,
    this.onTap,
    this.showStatus = false,
    this.hideName = false,
    this.showTypeBadge = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  final ContributorModel contributor;

  /// المرتبة في قائمة الأعلى تبرّعاً — الأوائل الثلاثة يحصلون على وسام
  final int? rank;
  final VoidCallback? onTap;

  /// يعرض شارة مسدد/متأخر — للمشتركين
  final bool showStatus;

  /// يخفي الاسم لدور العضو الذي لا يُصرَّح له برؤية الأسماء
  final bool hideName;

  /// يعرض وسام نوع المساهم (مشترك / متبرع / داعم) — يُعرَض فقط في الرئيسية وعرض كافة البيانات
  final bool showTypeBadge;

  /// وضع التحديد المتعدد للحذف
  final bool isSelectionMode;

  /// هل السجل محدد حالياً
  final bool isSelected;

  /// دالة التغيير عند ضغط مربع الاختيار
  final ValueChanged<bool?>? onSelectChanged;

  bool get _hasMedal => rank != null && rank! <= 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = contributor;
    final amount = rank != null
        ? c.totalPaid
        : (c.isSubscriber ? (c.subscriptionAmount ?? c.totalPaid) : c.totalPaid);

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
      onTap: isSelectionMode
          ? () => onSelectChanged?.call(!isSelected)
          : (onTap ??
              () {
                context.push('/subscriber_detail/${c.id}');
              }),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderColor: isSelected ? AppColors.gold : borderColor,
      gradient: cardGradient,
      child: Row(
        children: [
          if (isSelectionMode) ...[
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: isSelected,
                activeColor: AppColors.gold,
                checkColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                side: BorderSide(
                  color: isDark ? AppColors.goldBright : AppColors.goldDark,
                  width: 1.8,
                ),
                onChanged: onSelectChanged,
              ),
            ),
            const SizedBox(width: 10),
          ],
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          hideName ? 'مساهم مُخفى الاسم' : c.fullName,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            fontSize: 14.5,
                            fontWeight: _hasMedal ? FontWeight.w700 : FontWeight.w600,
                            color: isRank1
                                ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                                : (isDark ? AppColors.textOnDark : AppColors.textOnLight),
                          ),
                        ),
                      ),
                    ),
                    if (_hasMedal) ...[
                      const SizedBox(width: 6),
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
                  ],
                ),
              ],
            ),
          ),
          if (_hasMedal || showTypeBadge || (showStatus && c.isSubscriber)) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_hasMedal) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: switch (rank!) {
                        1 => AppColors.rank1Gradient,
                        2 => AppColors.rank2Gradient,
                        _ => AppColors.rank3Gradient,
                      },
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (switch (rank!) {
                            1 => AppColors.gold,
                            2 => AppColors.silverMedal,
                            _ => AppColors.bronzeMedal,
                          }).withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.military_tech_rounded,
                          size: 13,
                          color: AppColors.greenAbyss,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '#$rank',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.greenAbyss,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_hasMedal && (showTypeBadge || (showStatus && c.isSubscriber)))
                  const SizedBox(height: 4),
                if (showTypeBadge) ...[
                  // وسام نوع المساهم (مشترك / متبرع / داعم)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.isSubscriber
                          ? AppColors.greenDeep.withValues(alpha: isDark ? 0.28 : 0.12)
                          : (c.type == ContributorType.donor
                              ? AppColors.gold.withValues(alpha: isDark ? 0.25 : 0.14)
                              : Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: c.isSubscriber
                            ? AppColors.greenDeep.withValues(alpha: 0.5)
                            : (c.type == ContributorType.donor
                                ? AppColors.gold.withValues(alpha: 0.6)
                                : Colors.blue.withValues(alpha: 0.5)),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      c.type.label,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: c.isSubscriber
                            ? (isDark ? const Color(0xFF6FE0A5) : AppColors.greenDeep)
                            : (c.type == ContributorType.donor
                                ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                                : (isDark ? Colors.lightBlueAccent : Colors.blue.shade800)),
                      ),
                    ),
                  ),
                ],
                if (showTypeBadge && (showStatus && c.isSubscriber))
                  const SizedBox(height: 4),
                if (showStatus && c.isSubscriber) ...[
                  _StatusChip(status: c.paymentStatus),
                ],
              ],
            ),
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
      if (url.startsWith('http')) {
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
        inner = Image.file(
          File(url),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _letterBox(context, letter),
        );
      }
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
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
              boxShadow: rank! <= 3
                  ? [
                      BoxShadow(
                        color: (rank == 1
                                ? AppColors.gold
                                : rank == 2
                                    ? AppColors.silverMedal
                                    : AppColors.bronzeMedal)
                            .withValues(alpha: 0.45),
                        blurRadius: 5,
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rank! <= 3) ...[
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 11,
                    color: AppColors.greenAbyss,
                  ),
                  const SizedBox(width: 1.5),
                ],
                Text(
                  Fmt.count(rank),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: rank! <= 3 ? AppColors.greenAbyss : AppColors.textOnDark,
                  ),
                ),
              ],
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
    final color = switch (status) {
      PaymentStatus.paid => AppColors.paid,
      PaymentStatus.grace => AppColors.pending,
      PaymentStatus.overdue => AppColors.overdue,
    };
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
