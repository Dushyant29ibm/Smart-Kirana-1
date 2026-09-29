enum KhataEntryType { credit, payment }

class KhataEntry {
  const KhataEntry({
    required this.id,
    required this.customerId,
    required this.createdAt,
    required this.type,
    required this.amount,
    required this.note,
    this.saleId,
  });

  final String id;
  final String customerId;
  final DateTime createdAt;
  final KhataEntryType type;
  final double amount;
  final String note;
  final String? saleId;

  double get balanceEffect =>
      type == KhataEntryType.credit ? amount : -amount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'customerId': customerId,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
        'amount': amount,
        'note': note,
        'saleId': saleId,
      };

  factory KhataEntry.fromMap(Map<dynamic, dynamic> map) => KhataEntry(
        id: map['id'] as String,
        customerId: map['customerId'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        type: KhataEntryType.values.firstWhere(
          (e) => e.name == (map['type'] as String? ?? 'credit'),
          orElse: () => KhataEntryType.credit,
        ),
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        note: map['note'] as String? ?? '',
        saleId: map['saleId'] as String?,
      );
}
