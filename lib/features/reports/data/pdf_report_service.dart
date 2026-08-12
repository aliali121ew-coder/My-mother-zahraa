import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/contributor_model.dart';
import '../../../shared/models/enums.dart';

/// خدمة توليد وتنسيق ملفات PDF بحجم A4 قياسي وطباعتها.
class PdfReportService {
  const PdfReportService._();

  /// توليد وطباعة تقرير A4 تفصيلي للمشتركين أو المتبرعين.
  static Future<void> printReport({
    required String title,
    required List<ContributorModel> items,
    required bool isDonorsReport,
  }) async {
    final pdfBytes = await generateReportPdf(
      title: title,
      items: items,
      isDonorsReport: isDonorsReport,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '$title - ${DateFormat('yyyy-MM-dd', 'en').format(DateTime.now())}',
    );
  }

  /// مشاركة تقرير PDF كملف لتطبيقات التواصل الاجتماعي (واتساب، تليكرام، ماسنجر...).
  static Future<void> shareReport({
    required String title,
    required List<ContributorModel> items,
    required bool isDonorsReport,
  }) async {
    final pdfBytes = await generateReportPdf(
      title: title,
      items: items,
      isDonorsReport: isDonorsReport,
    );

    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedTitle = title.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '_');
      final file = File('${tempDir.path}/$sanitizedTitle.pdf');
      await file.writeAsBytes(pdfBytes);

      // ignore: deprecated_member_use
      final result = await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        text: 'تقرير $title - موكب أمنا الزهراء',
        subject: 'تقرير $title',
      );

      if (result.status == ShareResultStatus.dismissed) {
        // Fallback in case share_plus is bypassed
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'تقرير_$title.pdf',
        );
      }
    } catch (_) {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'تقرير_$title.pdf',
      );
    }
  }

  /// إنشاء ثوابت الملف وتنسيق الصفحات A4 بالكامل.
  static Future<Uint8List> generateReportPdf({
    required String title,
    required List<ContributorModel> items,
    required bool isDonorsReport,
  }) async {
    final pdf = pw.Document();

    // تحميل الخطوط القياسية المتوافقة مع محرك PDF أوفلاين
    final fontRegularData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf');
    final fontBoldData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf');
    final fontRegular = pw.Font.ttf(fontRegularData);
    final fontBold = pw.Font.ttf(fontBoldData);

    // تحميل الشعار إذا توفر
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo/logo_small.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    // حساب المجموع الكلي
    num totalSum = 0;
    for (final item in items) {
      totalSum += item.isSubscriber ? (item.subscriptionAmount ?? 0) : item.totalPaid;
    }

    final printDate = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd', 'en').format(printDate);
    final timeStr = DateFormat('HH:mm:ss', 'en').format(printDate);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.copyWith(
          marginTop: 22,
          marginBottom: 22,
          marginLeft: 22,
          marginRight: 22,
        ),
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (pw.Context context) => _buildHeader(
          title: title,
          dateStr: dateStr,
          timeStr: timeStr,
          logoImage: logoImage,
        ),
        footer: (pw.Context context) => _buildFooter(context),
        build: (pw.Context context) => [
          pw.SizedBox(height: 10),
          _buildSummaryBox(
            totalCount: items.length,
            totalSum: totalSum,
            isDonorsReport: isDonorsReport,
          ),
          pw.SizedBox(height: 14),
          _buildTable(
            items: items,
            isDonorsReport: isDonorsReport,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required String title,
    required String dateStr,
    required String timeStr,
    pw.MemoryImage? logoImage,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromHex('#C6A77B'), width: 1.8),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // 1. اسم الموكب والعنوان على اليمين
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'موكب أمنا الزهراء',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#14512F'),
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#8A6A33'),
                  ),
                ),
              ],
            ),
          ),

          // 2. الشعار في الوسط مكبّر بدون خلفية أو حدود
          if (logoImage != null)
            pw.Container(
              width: 64,
              height: 64,
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.symmetric(horizontal: 10),
              child: pw.Image(
                logoImage,
                fit: pw.BoxFit.contain,
              ),
            )
          else
            pw.SizedBox(width: 64),

          // 3. تاريخ ووقت الطباعة على اليسار
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'تاريخ الطباعة: $dateStr',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'وقت الطباعة: $timeStr',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryBox({
    required int totalCount,
    required num totalSum,
    required bool isDonorsReport,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F3F6F3'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('D3DBD5'), width: 0.8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'عدد ${isDonorsReport ? 'المتبرعين' : 'المشتركين'}: ${Fmt.count(totalCount)}',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('101C16'),
            ),
          ),
          pw.Text(
            'المبلغ الإجمالي: ${Fmt.money(totalSum)}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('8A6A33'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable({
    required List<ContributorModel> items,
    required bool isDonorsReport,
  }) {
    final headers = isDonorsReport
        ? ['تاريخ آخر تبرع', 'رقم الهاتف', 'المبلغ الإجمالي', 'اسم المتبرع', 'ت']
        : ['تاريخ آخر دفعة', 'رقم الهاتف', 'حالة السداد', 'نوع الاشتراك', 'مبلغ الاشتراك', 'اسم المشترك', 'ت'];

    final columnWidths = isDonorsReport
        ? <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(1.2),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.4),
            3: const pw.FlexColumnWidth(2.4),
            4: const pw.FixedColumnWidth(28),
          }
        : <int, pw.TableColumnWidth>{
            0: const pw.FlexColumnWidth(1.1),
            1: const pw.FlexColumnWidth(1.1),
            2: const pw.FlexColumnWidth(0.85),
            3: const pw.FlexColumnWidth(0.85),
            4: const pw.FlexColumnWidth(1.2),
            5: const pw.FlexColumnWidth(2.0),
            6: const pw.FixedColumnWidth(28),
          };

    final rows = <pw.TableRow>[];

    // ترويسة الجدول
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColor.fromHex('#14512F')),
        children: [
          for (final h in headers)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 7),
              alignment: pw.Alignment.center,
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
        ],
      ),
    );

    // صفوف البيانات
    for (var i = 0; i < items.length; i++) {
      final c = items[i];
      final isEven = i.isEven;
      final rowBg = isEven ? PdfColor.fromHex('#F9FBF9') : PdfColors.white;

      if (isDonorsReport) {
        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(c.lastPaymentAt != null ? DateFormat('yyyy-MM-dd', 'en').format(c.lastPaymentAt!) : '—', align: pw.Alignment.center),
              _cell(c.phone ?? '—', align: pw.Alignment.center),
              _cell(Fmt.money(c.totalPaid), align: pw.Alignment.center, isBold: true),
              _cell(c.fullName.isEmpty ? 'مساهم' : c.fullName, align: pw.Alignment.centerRight),
              _cell(Fmt.count(i + 1), align: pw.Alignment.center),
            ],
          ),
        );
      } else {
        final statusColor = switch (c.paymentStatus) {
          PaymentStatus.paid => PdfColor.fromHex('#2E9E6B'),
          PaymentStatus.grace => PdfColor.fromHex('#D79A3C'),
          PaymentStatus.overdue => PdfColor.fromHex('#E54D42'),
        };
        final statusBg = switch (c.paymentStatus) {
          PaymentStatus.paid => PdfColor.fromHex('#EAF6F0'),
          PaymentStatus.grace => PdfColor.fromHex('#FDF8ED'),
          PaymentStatus.overdue => PdfColor.fromHex('#FDF0EE'),
        };

        rows.add(
          pw.TableRow(
            decoration: pw.BoxDecoration(color: rowBg),
            children: [
              _cell(c.lastPaymentAt != null ? DateFormat('yyyy-MM-dd', 'en').format(c.lastPaymentAt!) : '—', align: pw.Alignment.center),
              _cell(c.phone ?? '—', align: pw.Alignment.center),
              // شارة حالة السداد (مسدد بالأخضر / متأخر بالأحمر)
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: pw.BoxDecoration(
                    color: statusBg,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: statusColor, width: 0.6),
                  ),
                  child: pw.Text(
                    c.paymentStatus.label,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              _cell(c.subscriptionType?.label ?? '—', align: pw.Alignment.center),
              _cell(Fmt.money(c.subscriptionAmount ?? 0), align: pw.Alignment.center, isBold: true),
              _cell(c.fullName.isEmpty ? 'مساهم' : c.fullName, align: pw.Alignment.centerRight),
              _cell(Fmt.count(i + 1), align: pw.Alignment.center),
            ],
          ),
        );
      }
    }

    return pw.Table(
      columnWidths: columnWidths,
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E2E8E3'), width: 0.6),
      children: rows,
    );
  }

  static pw.Widget _cell(
    String text, {
    required pw.Alignment align,
    bool isBold = false,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align == pw.Alignment.center
            ? pw.TextAlign.center
            : align == pw.Alignment.centerRight
                ? pw.TextAlign.right
                : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isBold ? PdfColor.fromHex('#8A6A33') : PdfColor.fromHex('#101C16'),
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromHex('#E2E8E3'), width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'نظام موكب أمنا الزهراء - تقارير مالية معتمدة',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
          pw.Text(
            'صفحة ${context.pageNumber} من ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }
}
