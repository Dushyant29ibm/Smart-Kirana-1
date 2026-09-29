import 'package:url_launcher/url_launcher.dart';

import '../utils/formatters.dart';
import '../../data/models/customer.dart';
import '../../data/models/sale.dart';

class WhatsAppService {
  static String buildInvoice({
    required String storeName,
    required Sale sale,
    Customer? customer,
  }) {
    final lines = <String>[
      '🧾 *$storeName*',
      'Invoice: ${sale.id.substring(0, 8).toUpperCase()}',
      formatDateTime(sale.createdAt),
      if (customer != null) 'Customer: ${customer.name}',
      '',
      ...sale.lines.map(
        (line) =>
            '${line.productName} x ${_qty(line.quantity)} @ ${money(line.sellingPrice)} = ${money(line.lineTotal)}',
      ),
      '',
      '*Total: ${money(sale.total)}*',
      'Payment: ${sale.paymentMethod.label}',
      if (sale.creditAdded > 0)
        'Added to Udhar: ${money(sale.creditAdded)}',
      if (sale.remainingCredit > 0)
        'Remaining Udhar: ${money(sale.remainingCredit)}',
      '',
      'Thank you! 🙏',
    ];
    return lines.join('\n');
  }

  static String _qty(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  static Future<bool> openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final normalized = normalizeIndianPhone(phone);
    if (normalized.isEmpty) return false;

    final uri = Uri.https('wa.me', '/$normalized', {'text': message});
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
