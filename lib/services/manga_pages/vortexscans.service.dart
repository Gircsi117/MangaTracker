import 'package:manga_tracker/services/manga.service.dart';
import 'package:manga_tracker/types/list.type.dart';
import 'package:manga_tracker/types/manga.type.dart';

class VortexScansService extends MangaService {
  @override
  String get id => "vortexscans";

  @override
  String get name => "VortexScans";

  @override
  String get origin => "https://vortexscans.org";

  @override
  String get referer => "https://vortexscans.org/";

  @override
  String get logoUrl =>
      "https://storage.vortexscans.org/upload/2024/12/02/Logo-d426c8cb30892710.webp";

  @override
  bool get needLogin => true;

  @override
  String get mangaUrl => "$origin/series/$slug";

  VortexScansService([super.slug = ""]);

  @override
  MangaService create(String slug) => VortexScansService(slug);

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      return PaginatedList(items: [], totalCount: 0);
    } catch (e) {
      return PaginatedList(items: [], totalCount: 0);
    }
  }

  @override
  Future<Manga?> getMangaDetails() async {
    try {
      return manga;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Chapter>> getChapterList() async {
    try {
      return chapters;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ChapterContent> getPageList(chapterSlug) async {
    try {
      return ChapterContent.empty();
    } catch (e) {
      return ChapterContent.empty();
    }
  }
}
