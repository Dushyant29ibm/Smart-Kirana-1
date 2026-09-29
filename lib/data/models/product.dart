class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.buyingPrice,
    required this.sellingPrice,
    required this.currentStock,
    required this.lowStockThreshold,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final double buyingPrice;
  final double sellingPrice;
  final double currentStock;
  final double lowStockThreshold;

  bool get isLowStock => currentStock <= lowStockThreshold;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'unit': unit,
        'buyingPrice': buyingPrice,
        'sellingPrice': sellingPrice,
        'currentStock': currentStock,
        'lowStockThreshold': lowStockThreshold,
      };

  factory Product.fromMap(Map<dynamic, dynamic> map) => Product(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        category: map['category'] as String? ?? 'General',
        unit: map['unit'] as String? ?? 'pcs',
        buyingPrice: (map['buyingPrice'] as num?)?.toDouble() ?? 0,
        sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0,
        currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0,
        lowStockThreshold:
            (map['lowStockThreshold'] as num?)?.toDouble() ?? 5,
      );
}
