import 'package:isar/isar.dart';

part 'category.model.g.dart';

@collection
class CategoryTable {
  Id id = Isar.autoIncrement;
  late String name;
}