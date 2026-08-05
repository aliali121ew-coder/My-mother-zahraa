import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/glass.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/mawkib_logo.dart';
import '../data/pdf_report_service.dart';

/// شاشة الجدول التفصيلي للتقرير (المشتركون أو المتبرعون).
///
/// تمتاز بتثبيت عمود الاسم وتمرير أفقي لبقية الأعمدة مع شريط أدوات
/// علوي للطباعة والمشاركة بتنسيق A4 احترافي باللغة العربية.
class ReportDetailPage extends ConsumerStatefulWidget {
  const ReportDetailPage({super.key, required this.isDonorsReport});

  final bool isDonorsReport;

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

  @override
  Widget build(BuildContext context) {
    final asyncData = widget.isDonorsReport
        ? ref.watch(donorsProvider)
        : ref.watch(subscribersProvider);

    final title = widget.isDonorsReport ? 'تقرير المتبرعين التفصيلي' : 'تقرير المشتركين التفصيلي';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          final filtered = allContributors.where((c) {
            if (query.isEmpty) return true;
            return c.fullName.contains(query) || (c.phone?.contains(query) ?? false);
          }).toList();

          num totalSum = 0;
          for (final c in filtered) {
            totalSum += widget.isDonorsReport
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
                        children: [
                          const MawkibLogo(
                            height: 38,
                            small: true,
                            radius: 10,
                            padding: EdgeInsets.all(4),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'موكب أمنا الزهراء',
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFamily,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.goldBright : AppColors.goldDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  title,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Fmt.date(printDate),
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${printDate.hour.toString().padLeft(2, '0')}:${printDate.minute.toString().padLeft(2, '0')}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
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
                    : _buildInteractiveTable(context, filtered, isDark),
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
                              widget.isDonorsReport ? 'اسم المتبرع' : 'اسم المشترك',
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
                                  child: Text(
                                    c.fullName.isEmpty ? 'مساهم' : c.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFamily,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
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
                    width: widget.isDonorsReport ? 350 : 540,
                    child: Column(
                      children: [
                        // ترويسات الأعمدة الأفقية
                        Container(
                          height: 44,
                          color: headerBg,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: widget.isDonorsReport
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
                                  children: widget.isDonorsReport
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
    final paid = status == PaymentStatus.paid;
    final color = paid ? AppColors.paid : AppColors.overdue;
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
    setState(() => _isGeneratingPdf = true);
    try {
      await PdfReportService.printReport(
        title: title,
        items: items,
        isDonorsReport: widget.isDonorsReport,
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
    try {
      await PdfReportService.shareReport(
        title: title,
        items: items,
        isDonorsReport: widget.isDonorsReport,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء مشاركة الملف: $e')),
        );
      }
    }
  }
}
