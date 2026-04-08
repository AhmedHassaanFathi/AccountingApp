import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../delegates/data/delegate_repository.dart';

final allTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionRepositoryProvider).getAllTransactions();
});

final allDelegatesProvider = StreamProvider((ref) {
  return ref.watch(delegateRepositoryProvider).getDelegates();
});
