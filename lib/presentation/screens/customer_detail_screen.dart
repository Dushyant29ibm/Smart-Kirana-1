import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/customer.dart';
import '../../data/models/khata_entry.dart';
import '../controllers/app_controller.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({required this.customer, super.key});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final entries = app.repository.entriesForCustomer(customer.id);
    final balance = app.balanceFor(customer.id);

    return Scaffold(
      appBar: AppBar(title: Text(customer.name)),
      floatingActionButton: balance > 0.001
          ? FloatingActionButton.extended(
              onPressed: () => _recordPayment(context, app, balance),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Record payment'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Outstanding balance'),
              subtitle: Text(customer.phone),
              trailing: Text(
                money(balance),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Transaction history',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...entries.map((e) => Card(
                child: ListTile(
                  leading: Icon(
                    e.type == KhataEntryType.credit
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  title: Text(e.note),
                  subtitle: Text(formatDateTime(e.createdAt)),
                  trailing: Text(
                    '${e.type == KhataEntryType.credit ? '+' : '-'}${money(e.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: e.type == KhataEntryType.credit
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _recordPayment(
    BuildContext context,
    AppController app,
    double balance,
  ) async {
    final amount = TextEditingController(text: balance.toStringAsFixed(2));
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Record payment'),
        content: TextField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
            helperText: 'Due: ${money(balance)}',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(amount.text);
              if (value == null || value <= 0) return;
              try {
                await app.recordPayment(customerId: customer.id, amount: value);
                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Save payment'),
          ),
        ],
      ),
    );
    amount.dispose();
  }
}
