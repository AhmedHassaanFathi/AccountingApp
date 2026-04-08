import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String address;
  final double price;
  final String status;

  OrderItem({
    required this.address,
    required this.price,
    this.status = 'delivered',
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      address: map['address'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      status: map['status'] ?? 'delivered',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'price': price,
      'status': status,
    };
  }
}

class MerchantCollectionModel {
  final String id;
  final String merchantId;
  final String delegateId;
  final String delegateName;
  final DateTime date;
  final List<OrderItem> orders;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final String note;

  MerchantCollectionModel({
    required this.id,
    required this.merchantId,
    required this.delegateId,
    required this.delegateName,
    required this.date,
    required this.orders,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.note,
  });

  factory MerchantCollectionModel.fromMap(Map<String, dynamic> map, String id) {
    final ordersList = (map['orders'] as List<dynamic>?) ?? [];
    return MerchantCollectionModel(
      id: id,
      merchantId: map['merchantId'] ?? '',
      delegateId: map['delegateId'] ?? '',
      delegateName: map['delegateName'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      orders: ordersList.map((o) => OrderItem.fromMap(o as Map<String, dynamic>)).toList(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'merchantId': merchantId,
      'delegateId': delegateId,
      'delegateName': delegateName,
      'date': Timestamp.fromDate(date),
      'orders': orders.map((o) => o.toMap()).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'note': note,
    };
  }
}
