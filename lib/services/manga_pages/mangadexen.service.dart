import 'package:manga_tracker/services/manga_pages/mangadexhu.service.dart';
import '../manga.service.dart';

class MangaDexEnService extends MangaDexHuService {
  @override
  String get id => "mangadex-en";

  @override
  String get name => "MangaDexEN";

  @override
  String get lang => "en";

  MangaDexEnService([super.slug = ""]);

  @override
  MangaService create(String slug) {
    return MangaDexEnService(slug);
  }
}
