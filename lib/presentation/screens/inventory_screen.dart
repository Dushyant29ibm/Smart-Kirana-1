import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../data/models/product.dart';
import '../controllers/app_controller.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final items = app.products.where((p) {
      final q = query.toLowerCase().trim();
      return q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editProduct(context),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search product or category',
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No inventory items yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = items[i];
                      return Card(
                        child: ListTile(
                          onTap: () => _editProduct(context, existing: p),
                          title: Row(
                            children: [
                              Expanded(child: Text(p.name)),
                              if (p.isLowStock)
                                const Chip(
                                  avatar: Icon(Icons.warning_amber, size: 16),
                                  label: Text('LOW'),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${p.category} • Stock: ${_qty(p.currentStock)} ${p.unit}\n'
                            'Buy ${money(p.buyingPrice)} • Sell ${money(p.sellingPrice)}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _qty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _editProduct(BuildContext context, {Product? existing}) async {
    final app = AppScope.of(context);
    final name = TextEditingController(text: existing?.name);
    final category = TextEditingController(text: existing?.category);
    final unit = TextEditingController(text: existing?.unit ?? 'pcs');
    final buy = TextEditingController(text: existing?.buyingPrice.toString());
    final sell = TextEditingController(text: existing?.sellingPrice.toString());
    final stock = TextEditingController(text: existing?.currentStock.toString());
    final threshold = TextEditingController(
      text: (existing?.lowStockThreshold ?? app.settings.defaultLowStockThreshold)
          .toString(),
    );

    final formKey = GlobalKey<FormState>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 8,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 16,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(existing == null ? 'Add product' : 'Edit product',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _field(name, 'Product name'),
                _field(category, 'Category'),
                _field(unit, 'Unit (pcs/kg/packet)'),
                _field(buy, 'Buying price', number: true),
                _field(sell, 'Selling price', number: true),
                _field(stock, 'Current stock', number: true),
                _field(threshold, 'Low-stock threshold', number: true),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final product = Product(
                      id: existing?.id ??
                          DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name.text.trim(),
                      category: category.text.trim().isEmpty ? 'General' : category.text.trim(),
                      unit: unit.text.trim().isEmpty ? 'pcs' : unit.text.trim(),
                      buyingPrice: double.parse(buy.text),
                      sellingPrice: double.parse(sell.text),
                      currentStock: double.parse(stock.text),
                      lowStockThreshold: double.parse(threshold.text),
                    );
                    await app.saveProduct(product);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save product'),
                ),
                if (existing != null)
                  TextButton.icon(
                    onPressed: () async {
                      await app.deleteProduct(existing.id);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete product'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    for (final c in [name, category, unit, buy, sell, stock, threshold]) {
      c.dispose();
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
