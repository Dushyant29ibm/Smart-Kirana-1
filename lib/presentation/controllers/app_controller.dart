import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/repositories/kirana_repository.dart';

class AppController extends ChangeNotifier {
  AppController._(this.repository);

  final KiranaRepository repository;

  late AppSettings settings;
  List<Product> products = const [];
  List<Customer> customers = const [];
  List<Sale> sales = const [];

  static Future<AppController> create(KiranaRepository repository) async {
    final controller = AppController._(repository);
    await controller.refresh();
    return controller;
  }

  Future<void> refresh() async {
    settings = repository.getSettings();
    products = repository.getProducts();
    customers = repository.getCustomers();
    sales = repository.getSales();
    notifyListeners();
  }

  double balanceFor(String customerId) =>
      repository.customerBalance(customerId);

  Map<String, double> get balances => repository.allCustomerBalances();

  double get pendingCollections =>
      balances.values.where((e) => e > 0.001).fold(0, (a, b) => a + b);

  int get lowStockCount => products.where((p) => p.isLowStock).length;

  Future<void> saveProduct(Product product) async {
    await repository.saveProduct(product);
    await refresh();
  }

  Future<void> deleteProduct(String id) async {
    await repository.deleteProduct(id);
    await refresh();
  }

  Future<Customer> saveCustomer({
    required String name,
    required String phone,
    String? id,
  }) async {
    final customer = Customer(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      phone: phone.trim(),
    );
    await repository.saveCustomer(customer);
    await refresh();
    return customer;
  }

  Future<void> saveSettings({
    required String storeName,
    required double threshold,
  }) async {
    await repository.saveSettings(
      AppSettings(
        storeName: storeName.trim().isEmpty
            ? AppConstants.defaultStoreName
            : storeName.trim(),
        defaultLowStockThreshold: threshold,
      ),
    );
    await refresh();
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
  }) async {
    await repository.recordPayment(customerId: customerId, amount: amount);
    await refresh();
  }

  Future<CheckoutResult> checkout({
    required List<SaleLine> lines,
    required PaymentMethod paymentMethod,
    Customer? customer,
  }) async {
    final result = await repository.checkout(
      lines: lines,
      paymentMethod: paymentMethod,
      customer: customer,
    );
    await refresh();
    return result;
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
