import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/mawkib_logo.dart';
import '../../settings/presentation/account_requests_page.dart';
import '../../settings/presentation/banned_users_page.dart';
import '../data/login_audit_service.dart';
import '../data/pdf_report_service.dart';
import 'widgets/print_filter_bottom_sheet.dart';

/// شاشة الجدول التفصيلي للتقرير (المشتركون أو المتبرعون).
///
/// تمتاز بتثبيت عمود الاسم وتمرير أفقي لبقية الأعمدة مع شريط أدوات
/// علوي للطباعة والمشاركة بتنسيق A4 احترافي باللغة العربية.
class ReportDetailPage extends ConsumerStatefulWidget {
  const ReportDetailPage({
    super.key,
    required this.isDonorsReport,
    this.reportType,
  });

  final bool isDonorsReport;
  final String? reportType;

  @override
  ConsumerState<ReportDetailPage> createState() => _ReportDetailPageState();
}

class _ReportDetailPageState extends ConsumerState<ReportDetailPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _verticalScrollController = ScrollController();
  final _horizontalScrollController = ScrollController();

  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_verticalScrollController.hasClients &&
          _verticalScrollController.offset != _scrollController.offset) {
        _verticalScrollController.jumpTo(_scrollController.offset);
      }
    });
    _verticalScrollController.addListener(() {
      if (_scrollController.hasClients &&
          _scrollController.offset != _verticalScrollController.offset) {
        _scrollController.jumpTo(_verticalScrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  String _getReportTitle() {
    final type = widget.reportType ?? (widget.isDonorsReport ? 'donors' : 'subscribers');
    switch (type) {
      case 'donors':
        return 'تقرير المتبرعين التفصيلي';
      case 'supporters':
        return 'تقرير الداعمين والمساهمين (العيني)';
      case 'paid':
        return 'تقرير المشتركين المسددين';
      case 'overdue':
        return 'تقرير المشتركين المتأخرين';
      case 'all_consolidated':
        return 'تقرير كافة المساهمين الموحد (الفئات الـ 3)';
      case 'vault':
        return 'كشف حركة الخزنة والمالية';
      case 'purchases':
        return 'وصل المشتريات والمصروفات';
      case 'visits_log':
        return 'سجل الزيارات والضيوف';
      case 'interactions_log':
        return 'سجل تفاعلات المنشورات';
      case 'account_requests':
        return 'طلبات تسجيل الحسابات';
      case 'blocked_users':
        return 'سجل المستخدمين المحظورين';
      case 'archive_log':
        return 'السجل الأرشيفي والإداري';
      case 'subscribers':
      default:
        return 'تقرير المشتركين التفصيلي';
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(allContributorsProvider);
    final title = _getReportTitle();
    final type = widget.reportType ?? (widget.isDonorsReport ? 'donors' : 'subscribers');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (type == 'visits_log') {
      return _buildVisitsLogScaffold(context, theme, isDark, title);
    }

    if (type == 'account_requests') {
      return const AccountRequestsPage();
    }

    if (type == 'blocked_users') {
      return const BannedUsersPage();
    }

    if (type == 'archive_log') {
      return _buildArchiveLogScaffold(context, theme, isDark, title);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'مشاركة PDF',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _handleSharePdf(asyncData.valueOrNull ?? [], title),
          ),
          IconButton(
            tooltip: 'طباعة A4',
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _handlePrintPdf(asyncData.valueOrNull ?? [], title),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذّر تحميل بيانات التقرير\n$err',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        data: (allContributors) {
          final query = _searchController.text.trim();

          // تصفية العناصر حسب نوع التقرير المطلوبة
          final rawFiltered = allContributors.where((c) {
            switch (type) {
              case 'donors':
                return c.type == ContributorType.donor;
              case 'supporters':
                return c.type == ContributorType.inKind;
              case 'paid':
                return c.isSubscriber && !c.isOverdue;
              case 'overdue':
                return c.isSubscriber && c.isOverdue;
              case 'all_consolidated':
                return true; // الفئات الثلاث
              case 'subscribers':
              default:
                return c.isSubscriber;
            }
          }).toList();

          final filtered = rawFiltered.where((c) {
            if (query.isEmpty) return true;
            return c.fullName.contains(query) || (c.phone?.contains(query) ?? false);
          }).toList();

          num totalSum = 0;
          for (final c in filtered) {
            totalSum += (type == 'donors' || type == 'all_consolidated')
                ? c.totalPaid
                : (c.subscriptionAmount ?? 0);
          }

          final printDate = DateTime.now();

          return Column(
            children: [
              // ترويسة التقرير الرسمية (الشعار، العنوان، التاريخ)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const MawkibLogo(
                            height: 48,
                            small: true,
                            radius: 12,
                            padding: EdgeInsets.all(4),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'موكب أمنا الزهراء',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.goldBright : AppColors.goldDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.textOnLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 12, color: theme.textTheme.bodySmall!.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      Fmt.date(printDate),
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.access_time_rounded, size: 12, color: theme.textTheme.bodySmall!.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${printDate.hour.toString().padLeft(2, '0')}:${printDate.minute.toString().padLeft(2, '0')}',
                                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // شريط البحث
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'تصفية التقرير بالاسم أو رقم الهاتف...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // الجدول التفصيلي
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد بيانات مطابقة للتقرير',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : _buildInteractiveTable(context, filtered, isDark, type),
              ),

              // تذييل الإحصائيات المباشر
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.isDonorsReport
                                ? Icons.volunteer_activism_outlined
                                : Icons.groups_2_outlined,
                            size: 20,
                            color: isDark ? AppColors.goldBright : AppColors.goldDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'العدد: ${Fmt.count(filtered.length)}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Text(
                        'المجموع: ${Fmt.money(totalSum)}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.goldBright : AppColors.goldDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGeneratingPdf
            ? null
            : () => _handlePrintPdf(
                  asyncData.valueOrNull ?? [],
                  title,
                ),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        icon: _isGeneratingPdf
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.print_rounded),
        label: const Text(
          'طباعة A4',
          style: TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildInteractiveTable(
    BuildContext context,
    List<ContributorModel> items,
    bool isDark,
    String reportType,
  ) {
    final headerBg = isDark ? AppColors.greenDeep : AppColors.green;
    final headerTextColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Row(
            children: [
              // العمود المظهَر والمثبّت: ت + اسم المتبرع/المشترك (RTL)
              SizedBox(
                width: 170,
                child: Column(
                  children: [
                    // ترويسة الاسم الثابتة
                    Container(
                      height: 44,
                      color: headerBg,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              'ت',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: headerTextColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              reportType == 'all_consolidated' 
                                  ? 'اسم المساهم' 
                                  : (widget.isDonorsReport ? 'اسم المتبرع' : 'اسم المشترك'),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: headerTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // قائمة الأسماء المثبتة
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final c = items[index];
                          final isEven = index.isEven;
                          final rowBg = isEven
                              ? (isDark
                                  ? Colors.white.withValues(alpha: 0.02)
                                  : AppColors.lightBg.withValues(alpha: 0.5))
                              : Colors.transparent;

                          return Container(
                            height: 48,
                            color: rowBg,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11,
                                      color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      c.fullName.isEmpty ? 'مساهم' : c.fullName,
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFamily,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 1, thickness: 1),

              // الأجزاء القابلة للتمرير الأفقي للأعمدة الأخرى
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScrollController,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: reportType == 'all_consolidated' ? 622 : (widget.isDonorsReport ? 350 : 540),
                    child: Column(
                      children: [
                        // ترويسات الأعمدة الأفقية
                        Container(
                          height: 44,
                          color: headerBg,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: reportType == 'all_consolidated'
                                ? [
                                    _headerCell('الفئة', 80, headerTextColor),
                                    _headerCell('المبلغ', 100, headerTextColor),
                                    _headerCell('رقم الهاتف', 100, headerTextColor),
                                    _headerCell('الحالة', 85, headerTextColor),
                                    _headerCell('التاريخ', 95, headerTextColor),
                                    _headerCell('الملاحظات/نوع الدعم', 150, headerTextColor),
                                  ]
                                : widget.isDonorsReport
                                    ? [
                                        _headerCell('المبلغ الإجمالي', 120, headerTextColor),
                                        _headerCell('رقم الهاتف', 110, headerTextColor),
                                        _headerCell('آخر دفعة', 108, headerTextColor),
                                      ]
                                    : [
                                        _headerCell('مبلغ الاشتراك', 115, headerTextColor),
                                        _headerCell('نوع الاشتراك', 95, headerTextColor),
                                        _headerCell('حالة السداد', 95, headerTextColor),
                                        _headerCell('رقم الهاتف', 113, headerTextColor),
                                        _headerCell('تاريخ آخر دفعة', 110, headerTextColor),
                                      ],
                          ),
                        ),

                        // صفوف البيانات القابلة للتمرير
                        Expanded(
                          child: ListView.builder(
                            controller: _verticalScrollController,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final c = items[index];
                              final isEven = index.isEven;
                              final rowBg = isEven
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : AppColors.lightBg.withValues(alpha: 0.5))
                                  : Colors.transparent;

                              return Container(
                                height: 48,
                                color: rowBg,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Row(
                                  children: reportType == 'all_consolidated'
                                      ? [
                                          _dataCell(
                                              c.type == ContributorType.subscriber 
                                                  ? 'مشترك' : (c.type == ContributorType.donor ? 'متبرع' : 'داعم'),
                                              80, isDark),
                                          _dataCell(
                                              c.type == ContributorType.inKind 
                                                  ? (c.totalPaid > 0 ? Fmt.money(c.totalPaid) : '—') 
                                                  : Fmt.money(c.type == ContributorType.subscriber ? (c.subscriptionAmount ?? 0) : c.totalPaid),
                                              100, isDark, isBold: true),
                                          _dataCell(c.phone ?? '—', 100, isDark),
                                          c.type == ContributorType.subscriber ? _statusCell(c.paymentStatus, 85) : _dataCell('—', 85, isDark),
                                          _dataCell(c.lastPaymentAt != null ? Fmt.dateShort(c.lastPaymentAt) : '—', 95, isDark),
                                          _dataCell(c.latestDonationDesc?.isNotEmpty == true ? c.latestDonationDesc! : (c.notes?.isNotEmpty == true ? c.notes! : '—'), 150, isDark),
                                        ]
                                      : widget.isDonorsReport
                                          ? [
                                              _dataCell(Fmt.money(c.totalPaid), 120, isDark, isBold: true),
                                              _dataCell(c.phone ?? '—', 110, isDark),
                                              _dataCell(c.lastPaymentAt != null ? Fmt.dateShort(c.lastPaymentAt) : '—', 108, isDark),
                                            ]
                                          : [
                                              _dataCell(Fmt.money(c.subscriptionAmount ?? 0), 115, isDark, isBold: true),
                                              _dataCell(c.subscriptionType?.label ?? '—', 95, isDark),
                                              _statusCell(c.paymentStatus, 95),
                                              _dataCell(c.phone ?? '—', 113, isDark),
                                              _dataCell(c.lastPaymentAt != null ? Fmt.dateShort(c.lastPaymentAt) : '—', 110, isDark),
                                            ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dataCell(
    String text,
    double width,
    bool isDark, {
    bool isBold = false,
    Alignment align = Alignment.center,
  }) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: align,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align == Alignment.center
              ? TextAlign.center
              : align == Alignment.centerRight
                  ? TextAlign.right
                  : TextAlign.left,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold
                ? (isDark ? AppColors.goldBright : AppColors.goldDark)
                : (isDark ? AppColors.textOnDark : AppColors.textOnLight),
          ),
        ),
      ),
    );
  }

  Widget _statusCell(PaymentStatus status, double width) {
    final color = switch (status) {
      PaymentStatus.paid => AppColors.paid,
      PaymentStatus.grace => AppColors.pending,
      PaymentStatus.overdue => AppColors.overdue,
    };
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status.label,
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String label, double width, Color color) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _handlePrintPdf(List<ContributorModel> items, String title) async {
    if (items.isEmpty) return;
    
    final filter = await PrintFilterBottomSheet.show(context);
    if (filter == null) return;

    final filteredItems = items.where((c) {
      if (c.lastPaymentAt == null) return false;
      final isYearMatch = c.lastPaymentAt!.year == filter.year;
      if (filter.month == null) return isYearMatch;
      return isYearMatch && c.lastPaymentAt!.month == filter.month;
    }).toList();

    if (filteredItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات لهذه الفترة المحددة.')),
        );
      }
      return;
    }

    setState(() => _isGeneratingPdf = true);
    
    // جلب بيانات التبرع العيني من السجلات للشهر والسنة المحددة
    final repo = ref.read(contributorsRepositoryProvider);
    final enrichedItems = <ContributorModel>[];
    for (final c in filteredItems) {
      if (c.type != ContributorType.subscriber) {
        final desc = await repo.getDonationDescForMonth(c.id, filter.year, filter.month);
        if (desc != null && desc.isNotEmpty) {
          enrichedItems.add(c.copyWith(latestDonationDesc: desc));
        } else {
          enrichedItems.add(c);
        }
      } else {
        enrichedItems.add(c);
      }
    }

    final periodTitle = filter.month == null 
        ? '$title - سنة ${filter.year}'
        : '$title - شهر ${filter.month}/${filter.year}';

    try {
      await PdfReportService.printReport(
        title: periodTitle,
        items: enrichedItems,
        reportType: widget.reportType ?? (widget.isDonorsReport ? 'donors' : 'subscribers'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إعداد الطباعة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handleSharePdf(List<ContributorModel> items, String title) async {
    if (items.isEmpty) return;
    
    final filter = await PrintFilterBottomSheet.show(context);
    if (filter == null) return;

    final filteredItems = items.where((c) {
      if (c.lastPaymentAt == null) return false;
      final isYearMatch = c.lastPaymentAt!.year == filter.year;
      if (filter.month == null) return isYearMatch;
      return isYearMatch && c.lastPaymentAt!.month == filter.month;
    }).toList();

    if (filteredItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد بيانات لهذه الفترة المحددة.')),
        );
      }
      return;
    }
    
    // جلب بيانات التبرع العيني من السجلات للشهر والسنة المحددة
    final repo = ref.read(contributorsRepositoryProvider);
    final enrichedItems = <ContributorModel>[];
    for (final c in filteredItems) {
      if (c.type != ContributorType.subscriber) {
        final desc = await repo.getDonationDescForMonth(c.id, filter.year, filter.month);
        if (desc != null && desc.isNotEmpty) {
          enrichedItems.add(c.copyWith(latestDonationDesc: desc));
        } else {
          enrichedItems.add(c);
        }
      } else {
        enrichedItems.add(c);
      }
    }

    final periodTitle = filter.month == null 
        ? '$title - سنة ${filter.year}'
        : '$title - شهر ${filter.month}/${filter.year}';

    try {
      await PdfReportService.shareReport(
        title: periodTitle,
        items: enrichedItems,
        reportType: widget.reportType ?? (widget.isDonorsReport ? 'donors' : 'subscribers'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء مشاركة الملف: $e')),
        );
      }
    }
  }

  Widget _buildVisitsLogScaffold(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String title,
  ) {
    final auditLogs = ref.watch(loginAuditProvider);
    final search = _searchController.text.trim();

    final filteredLogs = auditLogs.where((item) {
      if (search.isEmpty) return true;
      return item.accountName.contains(search) ||
          item.emailOrPhone.contains(search) ||
          item.roleName.contains(search);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'تحديث السجل',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(loginAuditProvider.notifier).loadLogs(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ترويسة سجل الزيارات
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.door_front_door_rounded, color: Colors.purpleAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سجل حركات الدخول والزيارات',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.greenAbyss,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'إجمالي الحركات المسجلة: ${auditLogs.length} حركة دخول',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // حقل البحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'بحث باسم الحساب، الهاتف، أو الدور...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // قائمة الحسابات والزيارات
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد حركات زيارة أو دخول مسجلة حالياً',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredLogs[index];
                      final dateStr =
                          '${item.timestamp.year}/${item.timestamp.month.toString().padLeft(2, '0')}/${item.timestamp.day.toString().padLeft(2, '0')}';
                      final hour = item.timestamp.hour > 12 ? item.timestamp.hour - 12 : (item.timestamp.hour == 0 ? 12 : item.timestamp.hour);
                      final amPm = item.timestamp.hour >= 12 ? 'م' : 'ص';
                      final timeStr =
                          '${hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} $amPm';

                      return GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // أيقونة الحساب
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.goldGradient,
                              ),
                              child: Center(
                                child: Text(
                                  item.accountName.isNotEmpty ? item.accountName[0] : 'U',
                                  style: const TextStyle(
                                    fontFamily: AppTheme.displayFamily,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.greenAbyss,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // تفاصيل الحساب
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.accountName,
                                          style: TextStyle(
                                            fontFamily: AppTheme.displayFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : AppColors.greenAbyss,
                                          ),
                                        ),
                                      ),
                                      // شارة الدور
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.8),
                                        ),
                                        child: Text(
                                          item.roleName,
                                          style: const TextStyle(
                                            fontFamily: AppTheme.fontFamily,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.goldBright,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.emailOrPhone,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 11.5,
                                      color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time_filled_rounded, size: 13, color: AppColors.gold.withValues(alpha: 0.8)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$dateStr — $timeStr',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white70 : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveLogScaffold(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String title,
  ) {
    final archiveSections = [
      _ArchiveSectionItem(
        title: 'قائمة المشتركين',
        subtitle: 'أرشيف وسجلات المشتركين والاشتراكات الشهرية',
        icon: Icons.badge_outlined,
        color: AppColors.goldDark,
        route: '/reports/subscribers',
        badge: 'المشتركون',
      ),
      _ArchiveSectionItem(
        title: 'قائمة المتبرعين',
        subtitle: 'أرشيف المتبرعين والمساهمين والدعم العيني',
        icon: Icons.volunteer_activism_rounded,
        color: AppColors.paid,
        route: '/reports/donors',
        badge: 'المتبرعون',
      ),
      _ArchiveSectionItem(
        title: 'ألبوم الوسائط والتغطيات',
        subtitle: 'أرشيف منشورات وقصص وتغطيات الموكب والمناسبات',
        icon: Icons.photo_library_rounded,
        color: Colors.pinkAccent,
        route: '/posts',
        badge: 'الألبوم والمنشورات',
      ),
      _ArchiveSectionItem(
        title: 'سجل الحسابات والطلبات',
        subtitle: 'أرشيف طلبات الحسابات والأعضاء والمستخدمين',
        icon: Icons.manage_accounts_rounded,
        color: Colors.teal,
        route: '/reports/account_requests',
        badge: 'الحسابات',
      ),
      _ArchiveSectionItem(
        title: 'سجل الخزنة والمالية',
        subtitle: 'أرشيف حركة الخزنة، المشتريات، والوصولات المالية',
        icon: Icons.account_balance_wallet_rounded,
        color: Colors.amber.shade700,
        route: '/reports/vault',
        badge: 'الخزنة',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          // ترويسة سجل الأرشيف
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Colors.cyanAccent, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سجل الأرشيف المركزي',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.greenAbyss,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'تصفح واستعراض كافة أرشيفات وأقسام الموكب المحفوظة',
                          style: TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 12,
                            color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // شبكة وبطاقات الأرشيف الـ 5
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: archiveSections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = archiveSections[index];
                return GlassCard(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    onTap: () {
                      if (item.route.startsWith('/reports/')) {
                        final type = item.route.replaceFirst('/reports/', '');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailPage(
                              isDonorsReport: type == 'donors',
                              reportType: type,
                            ),
                          ),
                        );
                      } else {
                        context.go(item.route);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: item.color.withValues(alpha: 0.35)),
                            ),
                            child: Icon(item.icon, color: item.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontFamily: AppTheme.displayFamily,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : AppColors.greenAbyss,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: item.color.withValues(alpha: 0.3), width: 0.8),
                                      ),
                                      child: Text(
                                        item.badge,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFamily,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: item.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 12,
                                    color: isDark ? AppColors.textOnDarkMuted : AppColors.textOnLightMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ],
                      ),
                    ),
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

class _ArchiveSectionItem {
  const _ArchiveSectionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final String badge;
}
