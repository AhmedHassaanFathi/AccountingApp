import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';
import '../../delegates/data/delegate_repository.dart';
import '../../delegates/domain/models/delegate_model.dart';
import '../data/transaction_repository.dart';
import '../domain/models/transaction_model.dart';

final delegateTransactionsProvider = StreamProvider.family<List<TransactionModel>, String>((ref, delegateId) {
  return ref.watch(transactionRepositoryProvider).getTransactions(delegateId);
});

final currentDelegateProvider = StreamProvider.family<DelegateModel?, String>((ref, delegateId) {
  return ref.watch(delegateRepositoryProvider).getDelegates().map((list) {
    try {
      return list.firstWhere((d) => d.id == delegateId);
    } catch (_) {
      return null;
    }
  });
});

class DelegateTransactionsScreen extends ConsumerWidget {
  final String delegateId;

  const DelegateTransactionsScreen({super.key, required this.delegateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delegateAsync = ref.watch(currentDelegateProvider(delegateId));
    final transactionsAsync = ref.watch(delegateTransactionsProvider(delegateId));

    return Scaffold(
      appBar: AppBar(
        title: delegateAsync.when(
          data: (d) => Text(d?.name ?? 'Delegate Details'),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: delegateAsync.when(
        data: (delegate) {
          if (delegate == null) return const Center(child: Text('Delegate not found'));

          return transactionsAsync.when(
            data: (transactions) {
              return Column(
                children: [
                  _buildSummaryCard(context, ref, delegate, transactions),
                  Expanded(
                    child: transactions.isEmpty 
                      ? const Center(child: Text('No daily transactions yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(context, transactions[index], ref);
                          },
                        ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: delegateAsync.whenData((d) {
        if (d == null) return const SizedBox.shrink();
        final txs = transactionsAsync.value ?? <TransactionModel>[];
        return FloatingActionButton.extended(
          onPressed: () => _showAddTransactionDialog(context, ref, d, txs),
          icon: const Icon(Icons.add),
          label: const Text('Add Daily Record'),
        );
      }).value ?? const SizedBox.shrink(),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, DelegateModel delegate, List<TransactionModel> transactions) {
    double totalCollected = 0;
    double totalPaid = 0;
    double totalRemaining = 0;
    for (final tx in transactions) {
      totalCollected += tx.totalAmount;
      totalPaid += tx.paidAmount;
      totalRemaining += tx.remainingAmount;
    }
    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.loc('totalCollected'), style: const TextStyle(color: Colors.grey)),
                Text(currency.format(totalCollected), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.loc('amountPaid'), style: const TextStyle(color: Colors.grey)),
                Text(currency.format(totalPaid), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.loc('remaining'), style: const TextStyle(color: Colors.grey)),
                Text(currency.format(totalRemaining), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: totalRemaining > 0 ? Colors.red : Colors.green)),
              ],
            ),
            if (totalRemaining < 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مستحقات للمندوب:', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Text(currency.format(totalRemaining.abs()), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          backgroundColor: Colors.purple.shade50,
                          minimumSize: const Size(60, 36),
                        ),
                        onPressed: () => _showPayoutDialog(context, ref, delegate),
                        child: const Text('تسديد', style: TextStyle(color: Colors.purple)),
                      ),
                    ],
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, TransactionModel tx, WidgetRef ref) {
    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);
    final dateFormat = DateFormat.yMMMEd();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateFormat.format(tx.date), style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () => ref.read(transactionRepositoryProvider).deleteTransaction(tx.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const Divider(),
            if (tx.totalAmount == 0 && tx.paidAmount < 0) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('تسديد مستحقات للمندوب', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              _buildRow('المبلغ المسدد المخصوم:', currency.format(tx.paidAmount.abs()), isBold: true, color: Colors.purple),
            ] else ...[
              _buildRow('${context.loc('totalCollected')}:', currency.format(tx.totalAmount)),
              _buildRow('${context.loc('officeShare')}:', currency.format(tx.officeShare)),
              _buildRow('${context.loc('delegateShare')}:', currency.format(tx.delegateShare)),
              _buildRow('${context.loc('amountPaid')}:', currency.format(tx.paidAmount)),
              _buildRow('${context.loc('remaining')}:', currency.format(tx.remainingAmount), isBold: true, color: tx.remainingAmount > 0 ? Colors.red : Colors.green),
            ]
          ],
        ),
      ),
    );
  }

  void _showPayoutDialog(BuildContext context, WidgetRef ref, DelegateModel delegate) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تسديد مستحقات المندوب'),
          content: TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'المبلغ المسدد للمندوب (EGP)'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(context.loc('cancel'))),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                
                await ref.read(transactionRepositoryProvider).addTransaction(
                  delegate,
                  DateTime.now(),
                  0,
                  -amount, // Negative means outflow from office to delegate
                  false,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(context.loc('save')),
            ),
          ],
        );
      },
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

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref, DelegateModel delegate, List<TransactionModel> transactions) {
    final totalController = TextEditingController();
    final paidController = TextEditingController();

    double oldDebt = 0;
    for (final tx in transactions) {
      oldDebt += tx.remainingAmount;
    }
    final currency = NumberFormat.currency(symbol: 'EGP ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final total = double.tryParse(totalController.text) ?? 0;
            final paid = double.tryParse(paidController.text) ?? 0;
            final remainingInThisTx = total - paid;

            return AlertDialog(
              title: Text(context.loc('newRecord')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${context.loc('previousDebt')}:', style: const TextStyle(fontSize: 12)),
                          Text(currency.format(oldDebt), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: totalController,
                      decoration: InputDecoration(labelText: context.loc('totalCollected')),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: paidController,
                      decoration: InputDecoration(labelText: context.loc('amountPaid')),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${context.loc('remFromThis')}:', style: const TextStyle(fontSize: 12)),
                          Text(currency.format(remainingInThisTx), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(context.loc('cancel'))),
                ElevatedButton(
                  onPressed: () async {
                    if (totalController.text.isEmpty) return;
                    
                    await ref.read(transactionRepositoryProvider).addTransaction(
                      delegate,
                      DateTime.now(),
                      total,
                      paid,
                      false,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(context.loc('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
