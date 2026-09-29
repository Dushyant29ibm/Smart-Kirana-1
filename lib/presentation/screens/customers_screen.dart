import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/customer.dart';
import '../controllers/app_controller.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final customers = app.customers.where((c) => app.balanceFor(c.id) > 0.001).toList()
      ..sort((a, b) => app.balanceFor(b.id).compareTo(app.balanceFor(a.id)));

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Khata')),
      body: customers.isEmpty
          ? const Center(child: Text('No pending customer balances.'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: customers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final c = customers[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase())),
                    title: Text(c.name),
                    subtitle: Text(c.phone),
                    trailing: Text(
                      money(app.balanceFor(c.id)),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
