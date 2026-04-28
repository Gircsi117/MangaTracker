import 'package:http/http.dart' as http;
import 'package:manga_tracker/modules/date.module.dart';
import 'dart:convert';
import '../manga.service.dart';
import '../../types/manga.type.dart';
import '../../types/list.type.dart';

class ToonVerseService extends MangaService {
  @override
  String get id => "toonverse";

  @override
  String get name => "ToonVerse";

  @override
  String get baseUrl => "https://api.toonverse.net";

  @override
  String get origin => "https://toonverse.net";

  @override
  String get referer => "https://toonverse.net/";

  @override
  String get logoUrl => "https://toonverse.net/logo.png";

  @override
  String get mangaUrl => "$referer/series/$slug";

  ToonVerseService([super.slug = ""]);

  @override
  MangaService create(String slug) {
    return ToonVerseService(slug);
  }

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      final limit = params.limit ?? 20;
      final offset = params.offset ?? 0;

      final uri = Uri.parse("$baseUrl/api/series").replace(
        queryParameters: {
          "search": params.query ?? "",
          "limit": limit.toString(),
          "offset": offset.toString(),
          "sortBy": "popular",
          "timeRange": "all",
          "excludeAdult": "true",
          "includePromotions": "true",
          "semantic": "true",
        },
      );

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body)["data"];
      final items = data["items"] as List;
      final total = data["total"] as int;

      final mangas = items
          .map(
            (x) => Manga(
              id: x["id"],
              slug: x["slug"],
              title: x["title"],
              coverUrl: x["coverUrl"],
              author: x["author"],
              type: x["type"],
              description: "",
            ),
          )
          .toList();

      return PaginatedList(items: mangas, totalCount: total);
    } catch (e) {
      return PaginatedList(items: [], totalCount: 0);
    }
  }

  @override
  Future<Manga?> getMangaDetails() async {
    try {
      if (manga != null) return manga;

      final res = await http.get(
        Uri.parse("$baseUrl/api/series/slug/$slug"),
        headers: headers,
      );

      final data = jsonDecode(res.body)["data"];

      manga = Manga(
        id: data["id"],
        slug: slug,
        title: data["title"],
        coverUrl: data["coverUrl"],
        author: data["author"],
        type: data["type"],
        description: data["description"],
      );

      return manga;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Chapter>> getChapterList() async {
    try {
      if (chapters.isNotEmpty) return chapters;

      final manga = await getMangaDetails();
      if (manga == null) return [];

      final uri = Uri.parse("$baseUrl/api/series/${manga.id}/chapters").replace(
        queryParameters: {"limit": "999999", "offset": "0", "order": "desc"},
      );

      final res = await http.get(uri, headers: headers);
      final data = jsonDecode(res.body)["data"];
      final chapterList = data["chapters"] as List? ?? [];

      chapters = chapterList
          .map(
            (x) => Chapter(
              id: x["id"],
              number: (x["number"] as num).toDouble(),
              slug: x["number"],
              title: x["title"],
              publishedAt: x["publishedAt"] != null
                  ? DateModule.getDateString(DateTime.parse(x["publishedAt"]))
                  : "",
            ),
          )
          .toList();

      return chapters;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ChapterContent> getPageList(ChapterSlug chapterSlug) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/reading/chapter/$slug/$chapterSlug"),
        headers: headers,
      );

      final data = jsonDecode(res.body)["data"];
      final pageList = (data["chapter"]["pages"] as List? ?? []);

      final pages = pageList.asMap().entries.map((entry) {
        final i = entry.key;
        final x = entry.value;
        return ChapterPage(id: x["id"], index: i, imageUrl: x["imageUrl"]);
      }).toList()..sort((a, b) => a.index.compareTo(b.index));

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
