import 'package:cloud_firestore/cloud_firestore.dart';

class MerchantModel {
  final String id;
  final String name;
  final DateTime createdAt;

  MerchantModel({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory MerchantModel.fromMap(Map<String, dynamic> map, String id) {
    return MerchantModel(
      id: id,
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  MerchantModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
