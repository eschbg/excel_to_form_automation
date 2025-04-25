import 'package:intl/intl.dart';

extension CustomFormatDateTime on DateTime {
  String formatToYmd() => DateFormat('yyyy-MM-dd').format(this);
  String formatToYmdPath() => DateFormat('yyyy/MM/dd').format(this);
}
