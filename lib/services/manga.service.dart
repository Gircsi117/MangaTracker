import "../types/manga.type.dart";
import "../types/list.type.dart";

abstract class MangaService {
  String get id;
  String get name;
  String get logoUrl => "";
  bool get needLogin => false;
  String get origin => "";
  String get referer => "";
  String get baseUrl => "";
  String get userAgent =>
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

  String get mangaUrl => "";

  Map<String, String> get headers => {
    "Origin": origin,
    "Referer": referer,
    "User-Agent": userAgent,
  };

  final String slug;
  Manga? manga;
  List<Chapter> chapters = [];

  MangaService([this.slug = ""]);
  MangaService create(String slug);

  Future<PaginatedList<Manga>> getMangaList(ListParams params);
  Future<Manga?> getMangaDetails();
  Future<List<Chapter>> getChapterList();
  Future<ChapterContent> getPageList(ChapterSlug chapterSlug);

  Future<Chapter?> getRelativeChapter(
    ChapterSlug chapterSlug,
    int offset,
  ) async {
    try {
      final chapters = await getChapterList();
      final sortedChapters = List<Chapter>.from(chapters)
        ..sort((a, b) => a.number.compareTo(b.number));
      final index =
          sortedChapters.indexWhere((x) => x.slug == chapterSlug) + offset;
      if (index < 0 || index >= sortedChapters.length) return null;
      return sortedChapters[index];
    } catch (e) {
      return null;
    }
  }
}
