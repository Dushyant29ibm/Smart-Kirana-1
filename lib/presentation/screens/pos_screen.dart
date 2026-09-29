import 'package:flutter/material.dart';

import '../../core/services/whatsapp_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';
import '../../data/repositories/kirana_repository.dart';
import '../controllers/app_controller.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final cart = <String, double>{};
  String query = '';

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final products = app.products.where((p) {
      final q = query.toLowerCase().trim();
      return q.isEmpty || p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);
    }).toList();

    final cartLines = cart.entries.map((e) {
      final product = app.products.firstWhere((p) => p.id == e.key);
      return SaleLine(
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        quantity: e.value,
        sellingPrice: product.sellingPrice,
      );
    }).toList();

    final total = cartLines.fold<double>(0, (sum, e) => sum + e.lineTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search products',
              ),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const Center(child: Text('No products found.'))
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (_, i) => _ProductCard(
                      product: products[i],
                      quantity: cart[products[i].id] ?? 0,
                      onAdd: () => _add(products[i]),
                      onRemove: () => _remove(products[i]),
                    ),
                  ),
          ),
          if (cartLines.isNotEmpty)
            Material(
              elevation: 12,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 90,
                        child: ListView(
                          children: cartLines.map((line) => ListTile(
                            dense: true,
                            title: Text(line.productName),
                            subtitle: Text('${_qty(line.quantity)} ${line.unit}'),
                            trailing: Text(money(line.lineTotal)),
                          )).toList(),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: Theme.of(context).textTheme.titleLarge),
                          Text(money(total), style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => _checkout(cartLines),
                        icon: const Icon(Icons.payment),
                        label: const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _qty(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  void _add(Product product) {
    final current = cart[product.id] ?? 0;
    if (current >= product.currentStock) return;
    setState(() => cart[product.id] = current + 1);
  }

  void _remove(Product product) {
    final current = cart[product.id] ?? 0;
    if (current <= 1) {
      setState(() => cart.remove(product.id));
    } else {
      setState(() => cart[product.id] = current - 1);
    }
  }

  Future<void> _checkout(List<SaleLine> lines) async {
    final payment = await showModalBottomSheet<PaymentMethod>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: PaymentMethod.values.map((method) {
            return ListTile(
              leading: Icon(switch (method) {
                PaymentMethod.cash => Icons.payments_outlined,
                PaymentMethod.upi => Icons.qr_code_2,
                PaymentMethod.udhar => Icons.account_balance_wallet_outlined,
              }),
              title: Text(method.label),
              onTap: () => Navigator.pop(ctx, method),
            );
          }).toList(),
        ),
      ),
    );

    if (!mounted || payment == null) return;

    Customer? customer;
    if (payment == PaymentMethod.udhar) {
      customer = await _pickCustomer();
      if (!mounted || customer == null) return;
    }

    final app = AppScope.of(context);
    try {
      final result = await app.checkout(
        lines: lines,
        paymentMethod: payment,
        customer: customer,
      );

      setState(cart.clear);

      if (!mounted) return;
      final shouldWhatsApp = result.customer != null &&
          await _askWhatsApp(result);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sale completed: ${money(result.sale.total)}')),
      );

      if (shouldWhatsApp) {
        await WhatsAppService.openWhatsApp(
          phone: result.customer!.phone,
          message: WhatsAppService.buildInvoice(
            storeName: app.settings.storeName,
            sale: result.sale,
            customer: result.customer,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<bool> _askWhatsApp(CheckoutResult result) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Send WhatsApp bill?'),
            content: Text('Send the invoice to ${result.customer!.name}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open WhatsApp')),
            ],
          ),
        ) ??
        false;
  }

  Future<Customer?> _pickCustomer() async {
    final app = AppScope.of(context);
    final search = TextEditingController();
    Customer? selected;

    selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final q = search.text.toLowerCase().trim();
          final matches = app.customers.where((c) =>
              q.isEmpty || c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * .7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: search,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search customer',
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.person_add_alt_1),
                          title: const Text('Add new customer'),
                          onTap: () async {
                            final customer = await _addCustomer(ctx);
                            if (customer != null && ctx.mounted) {
                              Navigator.pop(ctx, customer);
                            }
                          },
                        ),
                        ...matches.map((c) => ListTile(
                          title: Text(c.name),
                          subtitle: Text(c.phone),
                          trailing: Text(money(app.balanceFor(c.id))),
                          onTap: () => Navigator.pop(ctx, c),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    search.dispose();
    return selected;
  }

  Future<Customer?> _addCustomer(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final key = GlobalKey<FormState>();

    return showDialog<Customer>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New customer'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (!key.currentState!.validate()) return;
              final app = AppScope.of(context);
              final customer = await app.saveCustomer(name: name.text, phone: phone.text);
              if (ctx.mounted) Navigator.pop(ctx, customer);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final double quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(money(product.sellingPrice)),
            Text('Stock: ${product.currentStock} ${product.unit}',
                style: Theme.of(context).textTheme.bodySmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: quantity > 0 ? onRemove : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(quantity.toInt().toString()),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: product.currentStock > quantity ? onAdd : null,
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
