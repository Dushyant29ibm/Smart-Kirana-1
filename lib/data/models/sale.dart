enum PaymentMethod {
  cash,
  upi,
  udhar;

  String get label => switch (this) {
        PaymentMethod.cash => 'Cash',
        PaymentMethod.upi => 'UPI',
        PaymentMethod.udhar => 'Udhar',
      };

  static PaymentMethod fromString(String value) => PaymentMethod.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PaymentMethod.cash,
      );
}

class SaleLine {
  const SaleLine({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.sellingPrice,
  });

  final String productId;
  final String productName;
  final String unit;
  final double quantity;
  final double sellingPrice;

  double get lineTotal => quantity * sellingPrice;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'unit': unit,
        'quantity': quantity,
        'sellingPrice': sellingPrice,
      };

  factory SaleLine.fromMap(Map<dynamic, dynamic> map) => SaleLine(
        productId: map['productId'] as String,
        productName: map['productName'] as String? ?? '',
        unit: map['unit'] as String? ?? 'pcs',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0,
      );
}

class Sale {
  const Sale({
    required this.id,
    required this.createdAt,
    required this.lines,
    required this.total,
    required this.paymentMethod,
    required this.customerId,
    required this.creditAdded,
    required this.remainingCredit,
  });

  final String id;
  final DateTime createdAt;
  final List<SaleLine> lines;
  final double total;
  final PaymentMethod paymentMethod;
  final String? customerId;
  final double creditAdded;
  final double remainingCredit;

  Map<String, dynamic> toMap() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'lines': lines.map((e) => e.toMap()).toList(),
        'total': total,
        'paymentMethod': paymentMethod.name,
        'customerId': customerId,
        'creditAdded': creditAdded,
        'remainingCredit': remainingCredit,
      };

  factory Sale.fromMap(Map<dynamic, dynamic> map) => Sale(
        id: map['id'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lines: ((map['lines'] as List?) ?? const [])
            .map((e) => SaleLine.fromMap(Map<dynamic, dynamic>.from(e as Map)))
            .toList(),
        total: (map['total'] as num?)?.toDouble() ?? 0,
        paymentMethod: PaymentMethod.fromString(
          map['paymentMethod'] as String? ?? 'cash',
        ),
        customerId: map['customerId'] as String?,
        creditAdded: (map['creditAdded'] as num?)?.toDouble() ?? 0,
        remainingCredit: (map['remainingCredit'] as num?)?.toDouble() ?? 0,
      );
}
