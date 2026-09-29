import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
final _date = DateFormat('dd MMM yyyy');

String money(num value) => _currency.format(value);
String formatDateTime(DateTime value) => _dateTime.format(value);
String formatDate(DateTime value) => _date.format(value);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String normalizeIndianPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) return '91$digits';
  if (digits.startsWith('91') && digits.length == 12) return digits;
  return digits;
}
