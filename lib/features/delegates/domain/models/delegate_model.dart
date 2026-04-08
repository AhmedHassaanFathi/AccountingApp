class DelegateModel {
  final String id;
  final String name;
  final String type; // 'percentage' or 'half'
  final double percentage;

  DelegateModel({
    required this.id,
    required this.name,
    required this.type,
    required this.percentage,
  });

  factory DelegateModel.fromMap(Map<String, dynamic> map, String id) {
    return DelegateModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? 'percentage',
      percentage: (map['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'percentage': percentage,
    };
  }

  DelegateModel copyWith({
    String? id,
    String? name,
    String? type,
    double? percentage,
  }) {
    return DelegateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      percentage: percentage ?? this.percentage,
    );
  }
}
