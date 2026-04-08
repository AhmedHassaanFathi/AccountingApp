import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../delegates/data/delegate_repository.dart';
import '../../delegates/domain/models/delegate_model.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/models/transaction_model.dart';
import '../../merchants/data/merchant_collection_repository.dart';
import '../../merchants/domain/models/merchant_collection_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DelegateModel? _selectedDelegate;
  DateTimeRange? _dateRange;

  Future<pw.Document?> _buildPdfDoc(List<TransactionModel> txs, double tMerchants) async {
    if (_selectedDelegate == null || txs.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد بيانات للطباعة (No data to export)')));
       return null;
    }

    final doc = pw.Document();
    final formatCurrency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    final formatDate = DateFormat('yyyy/MM/dd');

    final fontRegular = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    double tCollected = 0;
    double tOffice = 0;
    double tDelegate = 0;
    double tPaid = 0;
    double tRemaining = 0;

    for (final t in txs) {
      tCollected += t.totalAmount;
      tOffice += t.officeShare;
      tDelegate += t.delegateShare;
      tPaid += t.paidAmount;
      tRemaining += t.remainingAmount;
    }

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
                pw.Text('حسابات 360 - تقرير المندوب', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('اسم المندوب: ${_selectedDelegate!.name}'),
                pw.Text('الفترة المحددة: ${_dateRange == null ? 'كل الأوقات' : '${formatDate.format(_dateRange!.start)} إلى ${formatDate.format(_dateRange!.end)}'}'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  context: context,
                  cellAlignment: pw.Alignment.center,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  headers: ['إجمالي المبيعات', 'أرباح المكتب', 'عمولة المندوب', 'ما تم توريده', 'مستحقات التجار', 'الرصيد المتبقي'],
                  data: [
                    [
                      formatCurrency.format(tCollected),
                      formatCurrency.format(tOffice),
                      formatCurrency.format(tDelegate),
                      formatCurrency.format(tPaid),
                      formatCurrency.format(tMerchants),
                      formatCurrency.format(tRemaining),
                    ]
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('سجل المعاملات اليومية', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  context: context,
                  cellAlignment: pw.Alignment.center,
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  headers: ['التاريخ', 'تحصيل', 'مكتب', 'مندوب', 'تنزيلات (سداد)', 'متبقي'],
                  data: txs.where((t) => t.totalAmount > 0 || t.paidAmount != 0).map((t) => [
                    formatDate.format(t.date),
                    formatCurrency.format(t.totalAmount),
                    formatCurrency.format(t.officeShare),
                    formatCurrency.format(t.delegateShare),
                    formatCurrency.format(t.paidAmount),
                    formatCurrency.format(t.remainingAmount),
                  ]).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
    
    return doc;
  }

  void _generatePdf(List<TransactionModel> txs, double tMerchants) async {
    final doc = await _buildPdfDoc(txs, tMerchants);
    if (doc == null) return;
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: '${_selectedDelegate!.name}_report',
    );
  }

  void _sharePdf(List<TransactionModel> txs, double tMerchants) async {
    final doc = await _buildPdfDoc(txs, tMerchants);
    if (doc == null) return;
    
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${_selectedDelegate!.name}_report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final delegatesAsync = ref.watch(delegateRepositoryProvider).getDelegates();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('reports')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: StreamBuilder<List<DelegateModel>>(
                  stream: delegatesAsync,
                  builder: (context, snapshot) {
                    final delegates = snapshot.data ?? [];
                    return Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: delegates.any((d) => d.id == _selectedDelegate?.id) ? _selectedDelegate?.id : null,
                          decoration: const InputDecoration(labelText: 'اختر مندوب'),
                          items: delegates.map((d) {
                            return DropdownMenuItem(value: d.id, child: Text(d.name));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              final d = delegates.firstWhere((del) => del.id == val);
                              setState(() => _selectedDelegate = d);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.date_range),
                                label: Text(_dateRange == null 
                                  ? context.loc('selectDateRange') 
                                  : '${DateFormat.yMd().format(_dateRange!.start)} - ${DateFormat.yMd().format(_dateRange!.end)}'),
                                onPressed: () async {
                                  final range = await showDateRangePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (range != null) {
                                    setState(() => _dateRange = range);
                                  }
                                },
                              ),
                            ),
                            if (_dateRange != null)
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _dateRange = null),
                              )
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _selectedDelegate == null 
                ? const Center(child: Text('Select a delegate to view report'))
                : StreamBuilder<List<TransactionModel>>(
                    stream: ref.watch(transactionRepositoryProvider).getTransactions(_selectedDelegate!.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      
                      var txs = snapshot.data ?? [];
                      
                      if (_dateRange != null) {
                        txs = txs.where((t) {
                          // Allow same day transactions logic
                          final date = DateTime(t.date.year, t.date.month, t.date.day);
                          final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
                          final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
                          
                          return (date.isAtSameMomentAs(start) || date.isAfter(start)) && 
                                 (date.isAtSameMomentAs(end) || date.isBefore(end));
                        }).toList();
                      }

                      if (txs.isEmpty) {
                         return const Center(child: Text('No records found for this period.'));
                      }

                      double tCollected = 0;
                      double tDelegate = 0;
                      double tPaid = 0;
                      double tRemaining = 0;

                      for (final t in txs) {
                        tCollected += t.totalAmount;
                        tDelegate += t.delegateShare;
                        tPaid += t.paidAmount;
                        tRemaining += t.remainingAmount;
                      }
                      
                       return StreamBuilder<List<MerchantCollectionModel>>(
                        stream: ref.watch(merchantCollectionRepositoryProvider).getCollectionsForDelegate(_selectedDelegate!.id),
                        builder: (context, merchantSnapshot) {
                          var mCols = merchantSnapshot.data ?? [];
                          double tMerchants = 0;
                          for (final m in mCols) {
                             tMerchants += m.remainingAmount;
                          }
                          
                          final formatCurrency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

                      return Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${context.loc('totalMade')}:', style: const TextStyle(color: Colors.grey)),
                                      Text(formatCurrency.format(tCollected), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${context.loc('delegateShare')}:', style: const TextStyle(color: Colors.grey)),
                                      Text(formatCurrency.format(tDelegate), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${context.loc('amountPaid')}:', style: const TextStyle(color: Colors.grey)),
                                      Text(formatCurrency.format(tPaid), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                   const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('مستحقات التجار (بحوزة المندوب):', style: TextStyle(color: Colors.grey)),
                                      Text(formatCurrency.format(tMerchants), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${context.loc('remaining')}:', style: const TextStyle(color: Colors.grey)),
                                      Text(formatCurrency.format(tRemaining), style: TextStyle(fontWeight: FontWeight.bold, color: tRemaining > 0 ? Colors.red : Colors.green)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: txs.length,
                              itemBuilder: (context, index) {
                                final tx = txs[index];
                                return ListTile(
                                  title: Text(DateFormat.yMMMEd().format(tx.date)),
                                  subtitle: Text('Collected: ${tx.totalAmount} | Remaining: ${tx.remainingAmount}'),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _generatePdf(txs, tMerchants),
                                    icon: const Icon(Icons.print),
                                    label: const Text('طباعة'),
                                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _sharePdf(txs, tMerchants),
                                    icon: const Icon(Icons.share),
                                    label: const Text('مشاركة على واتساب'),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 50),
                                      backgroundColor: Colors.green.shade600,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                      });
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
