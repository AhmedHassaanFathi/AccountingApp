import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';
import 'providers/dashboard_providers.dart';
import 'dashboard_breakdown_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTimeRange? _dateRange;

  void _openBreakdown(BuildContext context, String title, Map<String, double> data) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DashboardBreakdownScreen(title: title, data: data),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(allTransactionsProvider);
    final delegatesAsync = ref.watch(allDelegatesProvider);
    final merchantCollsAsync = ref.watch(allMerchantCollectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('dashboard')),
        actions: [
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
      body: (transactionsAsync.isLoading || delegatesAsync.isLoading || merchantCollsAsync.isLoading)
          ? const Center(child: CircularProgressIndicator())
          : (transactionsAsync.hasError || delegatesAsync.hasError || merchantCollsAsync.hasError)
              ? const Center(child: Text('حدث خطأ في تحميل البيانات'))
              : _buildContent(context, transactionsAsync.value ?? [], delegatesAsync.value ?? [], merchantCollsAsync.value ?? []),
    );
  }

  Widget _buildContent(BuildContext context, List transactions, List delegates, List merchantCollections) {
    // Map delegate IDs to names
    final delegateNames = { for (var d in delegates) d.id: d.name };

    // Filter by date
    final filteredTxs = transactions.where((tx) {
      if (_dateRange == null) return true;
      final d = tx.date;
      final start = _dateRange!.start;
      final end = _dateRange!.end;
      final dayDate = DateTime(d.year, d.month, d.day);
      final dayStart = DateTime(start.year, start.month, start.day);
      final dayEnd = DateTime(end.year, end.month, end.day);
      return dayDate.isAtSameMomentAs(dayStart) || 
             dayDate.isAtSameMomentAs(dayEnd) || 
             (dayDate.isAfter(dayStart) && dayDate.isBefore(dayEnd));
    }).toList();

    double totalCollected = 0;
    double totalOfficeShare = 0;
    double totalPaid = 0;
    double totalDebt = 0; // Owed to office
    double totalOwedToDelegates = 0; // Owed to delegates

    double totalMerchantCollected = 0;
    double totalMerchantDebt = 0;

    final filteredMerchantColls = merchantCollections.where((c) {
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

    for (final c in filteredMerchantColls) {
      totalMerchantCollected += c.paidAmount;
      if (c.remainingAmount > 0) {
        totalMerchantDebt += c.remainingAmount;
      }
    }

    // Breakdowns
    Map<String, double> officeProfitsMap = {};
    Map<String, double> vaultMap = {};
    Map<String, double> debtMap = {};
    Map<String, double> owedMap = {};
    Map<String, double> totalCollectedMap = {};

    for (final tx in filteredTxs) {
      final name = delegateNames[tx.delegateId] ?? 'مجهول';
      
      totalCollected += tx.totalAmount;
      totalOfficeShare += tx.officeShare;
      totalPaid += tx.paidAmount;

      totalCollectedMap[name] = (totalCollectedMap[name] ?? 0) + tx.totalAmount;
      officeProfitsMap[name] = (officeProfitsMap[name] ?? 0) + tx.officeShare;
      vaultMap[name] = (vaultMap[name] ?? 0) + tx.paidAmount;

      if (tx.remainingAmount > 0) {
        totalDebt += tx.remainingAmount;
        debtMap[name] = (debtMap[name] ?? 0) + tx.remainingAmount;
      } else if (tx.remainingAmount < 0) {
        totalOwedToDelegates += tx.remainingAmount.abs();
        owedMap[name] = (owedMap[name] ?? 0) + tx.remainingAmount.abs();
      }
    }

    // Clean up empty records from breakdowns
    totalCollectedMap.removeWhere((k, v) => v <= 0);
    officeProfitsMap.removeWhere((k, v) => v <= 0);
    vaultMap.removeWhere((k, v) => v <= 0);
    debtMap.removeWhere((k, v) => v <= 0);
    owedMap.removeWhere((k, v) => v <= 0);

    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt, size: 16, color: isDark ? Colors.blue.shade200 : Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'الفترة: ${DateFormat.yMd().format(_dateRange!.start)} - ${DateFormat.yMd().format(_dateRange!.end)}',
                      style: TextStyle(color: isDark ? Colors.blue.shade200 : Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

          // Hero Card: Total Collected
          _buildHeroCard(
            title: 'إجمالي المبيعات (شغل المناديب)',
            amount: currency.format(totalCollected),
            icon: Icons.payments,
            color: Colors.blue,
            context: context,
            onTap: () => _openBreakdown(context, 'تفاصيل مبيعات المناديب', totalCollectedMap),
          ),
          const SizedBox(height: 16),
          
          // Two Columns Layout
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'أرباح المكتب',
                  subtitle: 'نسبة الإدارة الصافية',
                  amount: currency.format(totalOfficeShare),
                  icon: Icons.pie_chart,
                  color: Colors.deepPurple,
                  context: context,
                  onTap: () => _openBreakdown(context, 'تفاصيل أرباح المكتب من المناديب', officeProfitsMap),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'الخزينة (الدرج)',
                  subtitle: 'إجمالي التوريدات النقدية',
                  amount: currency.format(totalPaid),
                  icon: Icons.account_balance,
                  color: Colors.green,
                  context: context,
                  onTap: () => _openBreakdown(context, 'تفاصيل الخزينة وتوريدات المناديب', vaultMap),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
                Expanded(
                child: _buildMetricCard(
                  title: 'ديون متاخرة',
                  subtitle: 'نواقص للدرج على المناديب',
                  amount: currency.format(totalDebt),
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
                  context: context,
                  onTap: () => _openBreakdown(context, 'تفاصيل ديون المناديب (عليهم للمكتب)', debtMap),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'مستحقات المناديب',
                  subtitle: 'أرباح متأخرة لهم عندنا',
                  amount: currency.format(totalOwedToDelegates),
                  icon: Icons.handshake,
                  color: Colors.orange,
                  context: context,
                  onTap: () => _openBreakdown(context, 'تفاصيل مستحقات المناديب (ليهم عند المكتب)', owedMap),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Merchant Hero Card: Total Merchant Collected
          _buildHeroCard(
            title: 'إجمالي المحصل في المتاجر',
            amount: currency.format(totalMerchantCollected),
            icon: Icons.store,
            color: Colors.teal,
            context: context,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
                Expanded(
                child: _buildMetricCard(
                  title: 'ديون متاجر',
                  subtitle: 'لم تُحصّل من المناديب',
                  amount: currency.format(totalMerchantDebt),
                  icon: Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  context: context,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({required String title, required String amount, required IconData icon, required Color color, required BuildContext context, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.8), color], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal)),
                  Icon(icon, color: Colors.white, size: 32),
                ],
              ),
              const SizedBox(height: 16),
              Text(amount, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String subtitle, required String amount, required IconData icon, required Color color, required BuildContext context, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? Colors.grey.shade900 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: isDark ? color.withOpacity(0.9) : color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 12),
              Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? color.withOpacity(0.9) : color)),
            ],
          ),
        ),
      ),
    );
  }
}
