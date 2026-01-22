import 'package:intl/intl.dart';

DateTime dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

String ymd(DateTime dateTime) {
  return DateFormat('yyyy-MM-dd').format(dateOnly(dateTime));
}
