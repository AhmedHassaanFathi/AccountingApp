import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/transaction_model.dart';
import '../../delegates/domain/models/delegate_model.dart';
import '../../../core/constants/app_constants.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(FirebaseFirestore.instance);
});

class TransactionRepository {
  final FirebaseFirestore _firestore;

  TransactionRepository(this._firestore);

  CollectionReference get _transactions => _firestore.collection('transactions');

  Stream<List<TransactionModel>> getTransactions(String delegateId) {
    return _transactions
        .where('delegateId', isEqualTo: delegateId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Stream<List<TransactionModel>> getAllTransactions() {
    return _transactions
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addTransaction(
    DelegateModel delegate,
    DateTime date,
    double totalAmount,
    double paidAmount,
    bool receivedProfit,
  ) async {
    double officeShare = 0;
    double delegateShare = 0;

    if (delegate.type == AppConstants.delegateTypePercentage) {
      // Office takes a percentage
      officeShare = totalAmount * (delegate.percentage / 100);
      delegateShare = totalAmount - officeShare;
    } else if (delegate.type == AppConstants.delegateTypeHalf) {
      // Office takes a percentage of the TOTAL
      officeShare = totalAmount * (delegate.percentage / 100);
      
      // Expected system base is 50%. The delegate's share is the rest of that 50%.
      double systemBase = totalAmount * 0.5;
      delegateShare = systemBase - officeShare;
    }

    double remainingAmount = officeShare - paidAmount;

    final transactionMap = {
      'delegateId': delegate.id,
      'date': Timestamp.fromDate(date),
      'totalAmount': totalAmount,
      'officeShare': officeShare,
      'delegateShare': delegateShare,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'receivedProfit': receivedProfit,
    };

    await _transactions.add(transactionMap);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactions.doc(transaction.id).update(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _transactions.doc(id).delete();
  }
}
