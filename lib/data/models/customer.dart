class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String name;
  final String phone;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
      };

  factory Customer.fromMap(Map<dynamic, dynamic> map) => Customer(
        id: map['id'] as String,
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
      );
}
