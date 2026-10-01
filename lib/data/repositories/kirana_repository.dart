import '../../core/constants/app_constants.dart';
import '../local/hive_database.dart';
import '../models/app_settings.dart';
import '../models/customer.dart';
import '../models/khata_entry.dart';
import '../models/product.dart';
import '../models/sale.dart';

class CheckoutResult {
  const CheckoutResult({
    required this.sale,
    required this.customer,
  });

  final Sale sale;
  final Customer? customer;
}

class KiranaRepository {
  KiranaRepository(this.db);

  final HiveDatabase db;

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  List<Product> getProducts() => db.products.values
      .map((e) => Product.fromMap(Map<dynamic, dynamic>.from(e as Map)))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<Customer> getCustomers() => db.customers.values
      .map((e) => Customer.fromMap(Map<dynamic, dynamic>.from(e as Map)))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  List<Sale> getSales() => db.sales.values
      .map((e) => Sale.fromMap(Map<dynamic, dynamic>.from(e as Map)))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<KhataEntry> getKhata() => db.khata.values
      .map((e) => KhataEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  AppSettings getSettings() {
    final raw = db.settings.get(AppConstants.settingsKey);
    if (raw is Map) return AppSettings.fromMap(raw);
    return const AppSettings(
      storeName: AppConstants.defaultStoreName,
      defaultLowStockThreshold: AppConstants.defaultLowStockThreshold,
    );
  }

  Future<void> saveSettings(AppSettings settings) =>
      db.settings.put(AppConstants.settingsKey, settings.toMap());

  Future<void> saveProduct(Product product) =>
      db.products.put(product.id, product.toMap());

  Future<void> deleteProduct(String id) => db.products.delete(id);

  Future<void> saveCustomer(Customer customer) =>
      db.customers.put(customer.id, customer.toMap());

  Customer? customerById(String? id) {
    if (id == null) return null;
    final raw = db.customers.get(id);
    if (raw is! Map) return null;
    return Customer.fromMap(raw);
  }

  Product? productById(String id) {
    final raw = db.products.get(id);
    if (raw is! Map) return null;
    return Product.fromMap(raw);
  }

  List<KhataEntry> entriesForCustomer(String customerId) =>
      getKhata().where((e) => e.customerId == customerId).toList();

  double customerBalance(String customerId) => entriesForCustomer(customerId)
      .fold<double>(0, (sum, entry) => sum + entry.balanceEffect);

  Map<String, double> allCustomerBalances() {
    final result = <String, double>{};
    for (final entry in getKhata()) {
      result.update(
        entry.customerId,
        (value) => value + entry.balanceEffect,
        ifAbsent: () => entry.balanceEffect,
      );
    }
    return result;
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
    String note = 'Khata payment',
  }) async {
    if (amount <= 0) throw ArgumentError('Payment must be greater than zero.');
    final balance = customerBalance(customerId);
    if (amount > balance + 0.001) {
      throw ArgumentError('Payment cannot exceed the outstanding balance.');
    }
    final entry = KhataEntry(
      id: _id(),
      customerId: customerId,
      createdAt: DateTime.now(),
      type: KhataEntryType.payment,
      amount: amount,
      note: note,
    );
    await db.khata.put(entry.id, entry.toMap());
  }

  Future<CheckoutResult> checkout({
    required List<SaleLine> lines,
    required PaymentMethod paymentMethod,
    Customer? customer,
  }) async {
    if (lines.isEmpty) throw ArgumentError('Cart is empty.');

    for (final line in lines) {
      final product = productById(line.productId);
      if (product == null) throw StateError('Product no longer exists.');
      if (line.quantity <= 0 || line.quantity > product.currentStock) {
        throw StateError('Insufficient stock for ${product.name}.');
      }
    }

    if (paymentMethod == PaymentMethod.udhar && customer == null) {
      throw ArgumentError('A customer is required for Udhar.');
    }

    final total = lines.fold<double>(0, (sum, e) => sum + e.lineTotal);
    final saleId = _id();
    final double creditAdded =
      paymentMethod == PaymentMethod.udhar ? total : 0.0;

    final sale = Sale(
      id: saleId,
      createdAt: DateTime.now(),
      lines: List.unmodifiable(lines),
      total: total,
      paymentMethod: paymentMethod,
      customerId: customer?.id,
      creditAdded: creditAdded,
      remainingCredit: customer == null
          ? 0
          : customerBalance(customer.id) + creditAdded,
    );

    // Persist the sale and all stock changes. The boxes are local/offline.
    await db.sales.put(sale.id, sale.toMap());

    for (final line in lines) {
      final product = productById(line.productId)!;
      final updated = Product(
        id: product.id,
        name: product.name,
        category: product.category,
        unit: product.unit,
        buyingPrice: product.buyingPrice,
        sellingPrice: product.sellingPrice,
        currentStock: product.currentStock - line.quantity,
        lowStockThreshold: product.lowStockThreshold,
      );
      await saveProduct(updated);
    }

    if (paymentMethod == PaymentMethod.udhar && customer != null) {
      final entry = KhataEntry(
        id: _id(),
        customerId: customer.id,
        createdAt: sale.createdAt,
        type: KhataEntryType.credit,
        amount: total,
        note: 'Sale ${sale.id.substring(0, 8).toUpperCase()}',
        saleId: sale.id,
      );
      await db.khata.put(entry.id, entry.toMap());
    }

    return CheckoutResult(sale: sale, customer: customer);
  }
}
