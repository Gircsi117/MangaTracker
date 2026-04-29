import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'models/category.model.dart';

class AppDatabase {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [CategoryTableSchema],
      directory: dir.path,
    );
  }
}