import 'package:http/http.dart' as http;
import 'package:manga_tracker/modules/date.module.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../manga.service.dart';
import '../../types/manga.type.dart';
import '../../types/list.type.dart';

class ManhwaManiaService extends MangaService {
  @override
  String get id => "manhwamania";

  @override
  String get name => "ManhwaMania";

  @override
  String get baseUrl => "http://manhwamania.hu/api";

  @override
  String get origin => "http://manhwamania.hu";

  @override
  String get referer => "http://manhwamania.hu";

  @override
  String get logoUrl =>
      "https://iconape.com/wp-content/png_logo_vector/manga-logo.png";

  @override
  String get mangaUrl => "";

  ManhwaManiaService([super.slug = ""]);

  @override
  MangaService create(String slug) {
    return ManhwaManiaService(slug);
  }

  static String _formatFolder(String folderFormat, double chapter) {
    final n = chapter.toInt();
    return folderFormat
        .replaceAll("%03d", n.toString().padLeft(3, "0"))
        .replaceAll("%02d", n.toString().padLeft(2, "0"))
        .replaceAll("%d", n.toString());
  }

  static String _generateSlug(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[\u0300-\u036f]'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  static Future<Map<String, String>> _getSlugs() async {
    try {
      final response = await http.get(Uri.parse("https://manhwamania.hu"));
      final match = RegExp(
        r'const titleToRoute\s*=\s*(\{[\s\S]*?\});',
      ).firstMatch(response.body);
      if (match != null) {
        final raw = jsonDecode(match.group(1)!) as Map<String, dynamic>;
        return raw.map((k, v) => MapEntry(k, v as String));
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      final limit = params.limit ?? 20;
      final offset = params.offset ?? 0;
      final query = params.query ?? "";
      final slugs = await _getSlugs();

      final response = await http.get(
        Uri.parse("$baseUrl/get_all_series.php"),
        headers: headers,
      );

      final series = jsonDecode(response.body)["series"] as List? ?? [];

      final mangas = series
          .map((x) {
            final title = x["title"] as String;
            final slug = slugs[title] ?? _generateSlug(title);
            return Manga(
              id: x["id"].toString(),
              slug: slug,
              title: title,
              coverUrl: "$origin/${x["cover"]}",
              description: x["description"] ?? "",
              author: "Unknown",
              type: "Unknown",
            );
          })
          .where((x) => x.slug.isNotEmpty)
          .where((x) => x.title.toLowerCase().contains(query.toLowerCase()))
          .toList();

      final paginated = mangas.skip(offset).take(limit).toList();

      return PaginatedList(items: paginated, totalCount: mangas.length);
    } catch (e) {
      return PaginatedList(items: [], totalCount: 0);
    }
  }

  @override
  Future<Manga?> getMangaDetails() async {
    try {
      final result = await getMangaList(ListParams());
      manga = result.items.firstWhere(
        (x) => x.slug == slug,
        orElse: () => throw Exception("Not found"),
      );
      return manga;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Chapter>> getChapterList() async {
    try {
      final mangaDetails = await getMangaDetails();
      if (mangaDetails == null) return [];

      const uuid = Uuid();

      final response = await http.get(
        Uri.parse("$baseUrl/get_chapters.php?series_id=${mangaDetails.id}"),
        headers: headers,
      );

      final chapterList = jsonDecode(response.body)["chapters"] as List? ?? [];

      chapters = chapterList.map((x) {
        final number = (x["number"] as num).toDouble();
        return Chapter(
          id: uuid.v4(),
          slug: _formatFolder("%02d - Chapter %d", number),
          number: number,
          title: "Chapter ${x["number"]}",
          publishedAt: x["date"] != null
              ? DateModule.getDateString(DateTime.parse(x["date"] as String))
              : "",
        );
      }).toList();

      return chapters;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ChapterContent> getPageList(ChapterSlug chapterSlug) async {
    try {
      final folder = "$slug/$chapterSlug";

      final response = await http.get(
        Uri.parse("$baseUrl/get_chapter_images.php?folder=$folder"),
        headers: headers,
      );

      final images = jsonDecode(response.body)["images"] as List? ?? [];

      const uuid = Uuid();

      final pages = images.asMap().entries.map((entry) {
        return ChapterPage(
          id: uuid.v4(),
          index: entry.key,
          imageUrl: "$origin/fejezetek/$folder/${entry.value}",
        );
      }).toList();

      final curr = await getRelativeChapter(chapterSlug, 0);
      final next = await getRelativeChapter(chapterSlug, 1);
      final prev = await getRelativeChapter(chapterSlug, -1);

      return ChapterContent(
        pages: pages,
        currChapter: curr,
        nextChapter: next,
        prevChapter: prev,
      );
    } catch (e) {
      return ChapterContent(
        pages: [],
        currChapter: null,
        nextChapter: null,
        prevChapter: null,
      );
    }
  }
}
