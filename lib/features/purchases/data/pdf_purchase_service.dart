import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/purchase_model.dart';

class PdfPurchaseService {
  static const primaryColor = PdfColor.fromInt(0xff082216); // AppColors.greenDeep
  static const goldColor = PdfColor.fromInt(0xffC6A77B); // AppColors.gold
  static const lightBg = PdfColor.fromInt(0xfff3f6f3); // AppColors.lightBg

  static Future<pw.Font> _getBoldFont() async {
    final fontData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Bold.ttf');
    return pw.Font.ttf(fontData);
  }

  static Future<pw.Font> _getRegularFont() async {
    final fontData = await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  static Future<Uint8List?> _getLogo() async {
    try {
      final byteData = await rootBundle.load('assets/logo/logo_small.png');
      return byteData.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static pw.Widget _buildHeader(pw.Font boldFont, Uint8List? logoBytes, String title, String subtitle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('موكب أمنا الزهراء', style: pw.TextStyle(font: boldFont, fontSize: 24, color: primaryColor)),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: pw.BoxDecoration(
                color: goldColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.white)),
            ),
            if (subtitle.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(subtitle, style: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.grey700)),
            ]
          ],
        ),
        if (logoBytes != null)
          pw.Container(
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              border: pw.Border.all(color: goldColor, width: 2),
            ),
            child: pw.Image(pw.MemoryImage(logoBytes), width: 70, height: 70),
          ),
      ],
    );
  }

  static Future<void> generateAndPrint(PurchaseModel purchase) async {
    final pdf = pw.Document();
    final boldFont = await _getBoldFont();
    final regularFont = await _getRegularFont();
    final logoBytes = await _getLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5.landscape,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: goldColor, width: 3),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(boldFont, logoBytes, 'سند صرف مالي', 'تاريخ الإصدار: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}'),
                pw.SizedBox(height: 24),
                
                // Card for Details
                pw.Container(
                  decoration: pw.BoxDecoration(
                    color: lightBg,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                  ),
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('رقم السند: ${purchase.id.substring(0, 8).toUpperCase()}', style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
                          pw.Text('تاريخ الشراء: ${DateFormat('yyyy/MM/dd').format(purchase.purchaseDate)}', style: pw.TextStyle(font: boldFont, fontSize: 14, color: primaryColor)),
                        ],
                      ),
                      pw.Divider(color: PdfColors.grey300),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('المبلغ المصروف:', style: pw.TextStyle(font: boldFont, fontSize: 16)),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: pw.BoxDecoration(
                              color: primaryColor,
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Text(Fmt.money(purchase.amount), style: pw.TextStyle(font: boldFont, fontSize: 18, color: PdfColors.white)),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 16),
                      pw.Text('تفاصيل الصرف:', style: pw.TextStyle(font: boldFont, fontSize: 14, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(purchase.itemName, style: pw.TextStyle(font: boldFont, fontSize: 18, color: primaryColor)),
                      
                      if (purchase.supplierName?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 8),
                        pw.Text('اسم أمين الصندوق / المشتري: ${purchase.supplierName}', style: pw.TextStyle(font: regularFont, fontSize: 12)),
                      ],
                      if (purchase.notes?.isNotEmpty == true) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('ملاحظات: ${purchase.notes}', style: pw.TextStyle(font: regularFont, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSignatureBlock(boldFont, 'المستلم / المشتري'),
                    _buildSignatureBlock(boldFont, 'أمين الصندوق'),
                    _buildSignatureBlock(boldFont, 'كفيل الموكب (للاعتماد)'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'receipt_${purchase.id.substring(0, 8)}.pdf',
    );
  }

  static Future<void> generateAndPrintAll(List<PurchaseModel> purchases) async {
    final pdf = pw.Document();
    final boldFont = await _getBoldFont();
    final regularFont = await _getRegularFont();
    final logoBytes = await _getLogo();

    final totalAmount = purchases.fold<num>(0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 24),
          child: _buildHeader(boldFont, logoBytes, 'وصل المشتريات والمصروفات', 'تاريخ الإصدار: ${DateFormat('yyyy/MM/dd').format(DateTime.now())}'),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text('صفحة ${context.pageNumber} من ${context.pagesCount}', style: pw.TextStyle(font: regularFont, fontSize: 10, color: PdfColors.grey)),
        ),
        build: (context) {
          return [
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 12, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: pw.TextStyle(font: regularFont, fontSize: 11),
              cellAlignment: pw.Alignment.center,
              headers: ['ت', 'التاريخ', 'اسم المتطلب / الشراء', 'المشتري', 'المبلغ (د.ع)'],
              data: List<List<String>>.generate(
                purchases.length,
                (index) {
                  final p = purchases[index];
                  return [
                    '${index + 1}',
                    DateFormat('yyyy/MM/dd').format(p.purchaseDate),
                    p.itemName,
                    p.supplierName ?? '-',
                    Fmt.amount(p.amount),
                  ];
                },
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: goldColor, width: 2),
                ),
                child: pw.Row(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('المجموع الكلي:', style: pw.TextStyle(font: boldFont, fontSize: 16)),
                    pw.SizedBox(width: 16),
                    pw.Text(Fmt.money(totalAmount), style: pw.TextStyle(font: boldFont, fontSize: 18, color: primaryColor)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 48),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                _buildSignatureBlock(boldFont, 'أمين الصندوق'),
                _buildSignatureBlock(boldFont, 'توقيع كفيل الموكب'),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'purchases_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  static pw.Widget _buildSignatureBlock(pw.Font font, String title) {
    return pw.Column(
      children: [
        pw.Text(title, style: pw.TextStyle(font: font, fontSize: 12, color: primaryColor)),
        pw.SizedBox(height: 8),
        pw.Container(
          width: 120,
          height: 1,
          color: PdfColors.grey500,
        ),
      ],
    );
  }
}
