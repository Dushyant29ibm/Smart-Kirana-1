import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../core/constants/app_constants.dart';

class HiveDatabase {
  const HiveDatabase({
    required this.products,
    required this.customers,
    required this.sales,
    required this.khata,
    required this.settings,
  });

  final Box products;
  final Box customers;
  final Box sales;
  final Box khata;
  final Box settings;

  static Future<HiveDatabase> open() async {
    await Hive.initFlutter();
    return HiveDatabase(
      products: await Hive.openBox(AppConstants.productsBox),
      customers: await Hive.openBox(AppConstants.customersBox),
      sales: await Hive.openBox(AppConstants.salesBox),
      khata: await Hive.openBox(AppConstants.khataBox),
      settings: await Hive.openBox(AppConstants.settingsBox),
    );
  }
}
