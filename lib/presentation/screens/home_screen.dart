import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../controllers/app_controller.dart';
import '../widgets/summary_card.dart';
import 'customers_screen.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = DateTime.now();
    final todaySales = app.sales
        .where((s) => sameDay(s.createdAt, today))
        .fold<double>(0, (sum, s) => sum + s.total);

    return Scaffold(
      appBar: AppBar(
        title: Text(app.settings.storeName),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => _showSettings(context, app),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: app.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Today at a glance',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            SummaryCard(
              title: "Today's Sales",
              value: money(todaySales),
              icon: Icons.currency_rupee,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              ),
            ),
            SummaryCard(
              title: 'Pending Collections',
              value: money(app.pendingCollections),
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomersScreen()),
              ),
            ),
            SummaryCard(
              title: 'Low Stock Alerts',
              value: '${app.lowStockCount} item(s)',
              icon: Icons.warning_amber_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InventoryScreen()),
              ),
            ),
            const SizedBox(height: 20),
            Text('Quick actions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ActionGrid(
              actions: [
                ('New Sale', Icons.point_of_sale, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PosScreen()));
                }),
                ('Manage Inventory', Icons.inventory_2_outlined, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const InventoryScreen()));
                }),
                ('Customer Khata', Icons.people_outline, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CustomersScreen()));
                }),
                ('Reports', Icons.bar_chart_outlined, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ReportsScreen()));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSettings(
      BuildContext context, AppController app) async {
    final name = TextEditingController(text: app.settings.storeName);
    final threshold = TextEditingController(
      text: app.settings.defaultLowStockThreshold.toString(),
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Store settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Store name')),
            const SizedBox(height: 12),
            TextField(
              controller: threshold,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Default low-stock threshold'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await app.saveSettings(
                storeName: name.text,
                threshold: double.tryParse(threshold.text) ?? 5,
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    name.dispose();
    threshold.dispose();
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.actions});

  final List<(String, IconData, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (_, index) {
        final action = actions[index];
        return Card(
          child: InkWell(
            onTap: action.$3,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(action.$2, size: 32),
                const SizedBox(height: 8),
                Text(action.$1, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}
