import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/transaction_repository.dart';

final allTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionRepositoryProvider).getAllTransactions();
});

final dashboardMetricsProvider = Provider((ref) {
  final transactionsAsync = ref.watch(allTransactionsProvider);

  return transactionsAsync.whenData((transactions) {
    double totalCollectedToday = 0;
    double totalRemainingMoney = 0;
    
    final today = DateTime.now();

    for (final tx in transactions) {
      // Check if transaction is from today
      if (tx.date.year == today.year && tx.date.month == today.month && tx.date.day == today.day) {
        totalCollectedToday += tx.totalAmount;
      }
      
      // Calculate remaining money (this might mean delegate remaining to office or unpaid amounts)
      totalRemainingMoney += tx.remainingAmount;
    }

    return {
      'collectedToday': totalCollectedToday,
      'remainingMoney': totalRemainingMoney,
    };
  });
});
