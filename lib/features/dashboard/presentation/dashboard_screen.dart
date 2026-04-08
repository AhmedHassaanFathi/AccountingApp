import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';
import 'providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc('appTitle')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.loc('dashboard'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            metricsAsync.when(
              data: (metrics) => _buildMetricsGrid(context, metrics),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error loading metrics: $e')),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Map<String, double> metrics) {
    final formatCurrency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Collected Today',
            amount: formatCurrency.format(metrics['collectedToday']),
            icon: Icons.today,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'Remaining Money',
            amount: formatCurrency.format(metrics['remainingMoney']),
            icon: Icons.account_balance_wallet,
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

}

class _MetricCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.title, required this.amount, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(amount, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
