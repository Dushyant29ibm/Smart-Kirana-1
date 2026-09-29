import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/sale.dart';
import '../controllers/app_controller.dart';

enum ReportRange { daily, monthly, yearly }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportRange range = ReportRange.daily;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final filtered = app.sales.where((sale) {
      return switch (range) {
        ReportRange.daily => sameDay(sale.createdAt, now),
        ReportRange.monthly =>
          sale.createdAt.year == now.year && sale.createdAt.month == now.month,
        ReportRange.yearly => sale.createdAt.year == now.year,
      };
    }).toList();

    final revenue = filtered.fold<double>(0, (sum, sale) => sum + sale.total);
    final cash = filtered
        .where((s) => s.paymentMethod == PaymentMethod.cash)
        .fold<double>(0, (sum, s) => sum + s.total);
    final upi = filtered
        .where((s) => s.paymentMethod == PaymentMethod.upi)
        .fold<double>(0, (sum, s) => sum + s.total);
    final udhar = filtered
        .where((s) => s.paymentMethod == PaymentMethod.udhar)
        .fold<double>(0, (sum, s) => sum + s.total);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<ReportRange>(
            segments: const [
              ButtonSegment(value: ReportRange.daily, label: Text('Daily')),
              ButtonSegment(value: ReportRange.monthly, label: Text('Monthly')),
              ButtonSegment(value: ReportRange.yearly, label: Text('Yearly')),
            ],
            selected: {range},
            onSelectionChanged: (value) => setState(() => range = value.first),
          ),
          const SizedBox(height: 20),
          _Metric(title: 'Sales / Revenue', value: money(revenue)),
          _Metric(title: 'Transactions', value: '${filtered.length}'),
          _Metric(title: 'Cash', value: money(cash)),
          _Metric(title: 'UPI', value: money(upi)),
          _Metric(title: 'New Udhar', value: money(udhar)),
          _Metric(
            title: 'Total Outstanding Collections',
            value: money(app.pendingCollections),
          ),
          const SizedBox(height: 20),
          Text('Recent sales',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...filtered.take(30).map((sale) => Card(
                child: ListTile(
                  title: Text(money(sale.total)),
                  subtitle: Text(
                    '${formatDateTime(sale.createdAt)} • ${sale.paymentMethod.label}',
                  ),
                  trailing: Text('${sale.lines.length} item(s)'),
                ),
              )),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
