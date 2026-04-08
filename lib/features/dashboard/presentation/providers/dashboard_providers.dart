import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../transactions/data/transaction_repository.dart';
import '../../../delegates/data/delegate_repository.dart';
import '../../../merchants/data/merchant_collection_repository.dart';

final allTransactionsProvider = StreamProvider((ref) {
  return ref.watch(transactionRepositoryProvider).getAllTransactions();
});

final allDelegatesProvider = StreamProvider((ref) {
  return ref.watch(delegateRepositoryProvider).getDelegates();
});

final allMerchantCollectionsProvider = StreamProvider((ref) {
  return ref.watch(merchantCollectionRepositoryProvider).getAllCollections();
});
