import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DateModule {
  static Future<void> init() async {
    await initializeDateFormatting('hu');
  }

  static String getDateString(DateTime date) {
    try {
      return DateFormat('yyyy. MMM dd.', "hu").format(date);
    } catch (e) {
      return "";
    }
  }
}
