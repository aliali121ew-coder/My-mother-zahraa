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
    final c = contributor;
    final amount = c.isSubscriber ? c.subscriptionAmount : c.totalPaid;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderColor: _hasMedal ? AppColors.gold.withValues(alpha: 0.42) : null,
      child: Row(
        children: [
          _Avatar(contributor: c, rank: rank, hideName: hideName),
          const SizedBox(width: 13),
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
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (_hasMedal) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 17,
                        color: switch (rank!) {
                          1 => AppColors.goldBright,
                          2 => const Color(0xFFC0C0C0),
                          _ => AppColors.bronze,
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        Fmt.moneyShort(amount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gold,
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
        // صورة مصغّرة في الذاكرة: يمنع تحميل صور ضخمة داخل قائمة طويلة
        memCacheWidth: 132,
        placeholder: (_, _) => _letterBox(context, letter),
        errorWidget: (_, _, _) => _letterBox(context, letter),
      );
    } else {
      inner = _letterBox(context, letter);
    }

    final avatar = ClipOval(child: SizedBox(width: size, height: size, child: inner));

    if (rank == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: rank! <= 3 ? AppColors.gold : AppColors.greenMid,
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
                fontWeight: FontWeight.w700,
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
