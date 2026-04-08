import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String delegateId;
  final DateTime date;
  final double totalAmount;
  final double officeShare;
  final double delegateShare;
  final double paidAmount;
  final double remainingAmount;
  final bool receivedProfit;

  TransactionModel({
    required this.id,
    required this.delegateId,
    required this.date,
    required this.totalAmount,
    required this.officeShare,
    required this.delegateShare,
    required this.paidAmount,
    required this.remainingAmount,
    required this.receivedProfit,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      delegateId: map['delegateId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      officeShare: (map['officeShare'] ?? 0).toDouble(),
      delegateShare: (map['delegateShare'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      receivedProfit: map['receivedProfit'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'delegateId': delegateId,
      'date': Timestamp.fromDate(date),
      'totalAmount': totalAmount,
      'officeShare': officeShare,
      'delegateShare': delegateShare,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'receivedProfit': receivedProfit,
    };
  }

  TransactionModel copyWith({
    String? id,
    String? delegateId,
    DateTime? date,
    double? totalAmount,
    double? officeShare,
    double? delegateShare,
    double? paidAmount,
    double? remainingAmount,
    bool? receivedProfit,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      delegateId: delegateId ?? this.delegateId,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      officeShare: officeShare ?? this.officeShare,
      delegateShare: delegateShare ?? this.delegateShare,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      receivedProfit: receivedProfit ?? this.receivedProfit,
    );
  }
}
