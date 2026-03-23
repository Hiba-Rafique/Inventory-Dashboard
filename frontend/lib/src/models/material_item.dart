class MaterialItem {
  final String id;
  final String companyId;
  final String name;
  final String brand;
  final double price;
  final String unit;
  final String? categoryId;
  final String? createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaterialItem({
    required this.id,
    required this.companyId,
    required this.name,
    required this.brand,
    required this.price,
    required this.unit,
    required this.categoryId,
    required this.createdBy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: (json['id'] as String?) ?? '',
      companyId: (json['companyId'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      brand: (json['brand'] as String?) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      unit: (json['unit'] as String?) ?? 'pcs',
      categoryId: json['categoryId'] as String?,
      createdBy: json['createdBy'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'name': name,
      'brand': brand,
      'price': price,
      'unit': unit,
      'categoryId': categoryId,
      'createdBy': createdBy,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  MaterialItem copyWith({
    String? id,
    String? companyId,
    String? name,
    String? brand,
    double? price,
    String? unit,
    String? categoryId,
    String? createdBy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
