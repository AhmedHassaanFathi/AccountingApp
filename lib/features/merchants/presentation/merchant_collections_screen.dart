  import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


import '../../../core/localization/app_localizations.dart';
import '../data/merchant_repository.dart';
import '../data/merchant_collection_repository.dart';
import 'add_collection_screen.dart';
import '../domain/models/merchant_collection_model.dart';

final currentMerchantProvider = StreamProvider.family((ref, String id) {
  return ref.watch(merchantRepositoryProvider).getMerchants().map((list) {
    try {
      return list.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  });
});

final merchantCollectionsProvider = StreamProvider.family((ref, String merchantId) {
  return ref.watch(merchantCollectionRepositoryProvider).getCollectionsForMerchant(merchantId);
});

class MerchantCollectionsScreen extends ConsumerStatefulWidget {
  final String merchantId;

  const MerchantCollectionsScreen({super.key, required this.merchantId});

  @override
  ConsumerState<MerchantCollectionsScreen> createState() => _MerchantCollectionsScreenState();
}

class _MerchantCollectionsScreenState extends ConsumerState<MerchantCollectionsScreen> {
  DateTimeRange? _dateRange;

  void _shareWhatsApp(MerchantCollectionModel col, String merchantName) async {
    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final formatCurrency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('إيصال استلام - $merchantName', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('التاريخ: ${dateFormat.format(col.date)}'),
                pw.Text('المندوب: ${col.delegateName}'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  context: context,
                  cellAlignment: pw.Alignment.center,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headers: ['المنطقة', 'الحالة', 'السعر'],
                  data: col.orders.map((o) {
                    final statusStr = o.status == 'delivered' ? 'مُسلَّم' : (o.status == 'returned' ? 'مرتجع' : 'مؤجل');
                    return [o.address, statusStr, formatCurrency.format(o.price)];
                  }).toList(),
                ),
                pw.SizedBox(height: 20),
                pw.Text('الماليات', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('المُحصّل (تم استلامه): ${formatCurrency.format(col.paidAmount)}'),
                pw.Text('المتبقي: ${formatCurrency.format(col.remainingAmount)}'),
                if (col.note.isNotEmpty) pw.Text('ملاحظات: ${col.note}'),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'receipt_${col.date.millisecondsSinceEpoch}.pdf',
    );
  }

  void _generatePdf(List<MerchantCollectionModel> collections, String merchantName) async {
    if (collections.isEmpty) return;

    final doc = pw.Document();
    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();
    final dateFormat = DateFormat('yyyy/MM/dd');
    final formatCurrency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    double tPaid = 0;
    double tRemaining = 0;
    for (final c in collections) {
      tPaid += c.paidAmount;
      tRemaining += c.remainingAmount;
    }

    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('كشف حساب تاجر - $merchantName', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('الفترة المحددة: ${_dateRange == null ? 'كل الأوقات' : '${dateFormat.format(_dateRange!.start)} إلى ${dateFormat.format(_dateRange!.end)}'}'),
                  pw.SizedBox(height: 20),
                  pw.Table.fromTextArray(
                    context: context,
                    cellAlignment: pw.Alignment.center,
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    headers: ['إجمالي المدفوع (المُحصّل)', 'إجمالي الديون المتبقية'],
                    data: [ [ formatCurrency.format(tPaid), formatCurrency.format(tRemaining) ] ],
                  ),
                  pw.SizedBox(height: 30),
                  pw.Text('العمليات المعروضة', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    context: context,
                    cellAlignment: pw.Alignment.center,
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    headers: ['التاريخ', 'المندوب', 'عدد الطلبات', 'إجمالي', 'مُحصّل', 'متبقي'],
                    data: collections.map((c) => [
                      dateFormat.format(c.date),
                      c.delegateName,
                      c.orders.length.toString(),
                      formatCurrency.format(c.totalAmount),
                      formatCurrency.format(c.paidAmount),
                      formatCurrency.format(c.remainingAmount),
                    ]).toList(),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${merchantName}_statement',
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchantAsync = ref.watch(currentMerchantProvider(widget.merchantId));
    final collectionsAsync = ref.watch(merchantCollectionsProvider(widget.merchantId));

    return Scaffold(
      appBar: AppBar(
        title: merchantAsync.when(
          data: (merchant) => Text(merchant?.name ?? context.loc('merchantDetails')),
          loading: () => const Text('...'),
          error: (_, __) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.blueAccent),
            onPressed: () {
              final merchantName = merchantAsync.value?.name ?? 'التاجر';
              // Fallback to empty list if no data available
              _generatePdf(collectionsAsync.value ?? [], merchantName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: _dateRange,
              );
              if (range != null) {
                setState(() => _dateRange = range);
              }
            },
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _dateRange = null),
            ),
        ],
      ),
      body: collectionsAsync.when(
        data: (collections) {
          final filteredCollections = collections.where((c) {
            if (_dateRange == null) return true;
            final d = c.date;
            final start = _dateRange!.start;
            final end = _dateRange!.end;
            final dayDate = DateTime(d.year, d.month, d.day);
            final dayStart = DateTime(start.year, start.month, start.day);
            final dayEnd = DateTime(end.year, end.month, end.day);
            return dayDate.isAtSameMomentAs(dayStart) || 
                   dayDate.isAtSameMomentAs(dayEnd) || 
                   (dayDate.isAfter(dayStart) && dayDate.isBefore(dayEnd));
          }).toList();

          if (filteredCollections.isEmpty) {
            return const Center(child: Text('لا توجد عمليات تحصيل في هذه الفترة.'));
          }
          final dateFormat = DateFormat.yMMMEd();
          final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCollections.length,
            itemBuilder: (context, index) {
              final col = filteredCollections[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(dateFormat.format(col.date), style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => ref.read(merchantCollectionRepositoryProvider).deleteCollection(col.id),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildRow('المندوب:', col.delegateName),
                      _buildRow('عدد الأوردرات:', '${col.orders.length}'),
                      _buildRow('الإجمالي:', currency.format(col.totalAmount)),
                      _buildRow('المُحصّل:', currency.format(col.paidAmount)),
                      _buildRow(
                        'المتبقي على المندوب:', 
                        currency.format(col.remainingAmount), 
                        isBold: true, 
                        color: col.remainingAmount > 0 ? Colors.red : Colors.green,
                      ),
                      if (col.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          width: double.infinity,
                          child: Text('ملاحظات: ${col.note}', style: TextStyle(color: Colors.grey.shade800, fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _shareWhatsApp(col, merchantAsync.value?.name ?? 'تاجر'),
                          icon: const Icon(Icons.share, size: 16, color: Colors.green),
                          label: const Text('مشاركة الإيصال (واتساب)', style: TextStyle(color: Colors.green)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCollectionScreen(merchantId: widget.merchantId),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('تحصيل جديد'),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
