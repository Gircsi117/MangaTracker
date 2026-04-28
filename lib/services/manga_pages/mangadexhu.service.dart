import 'package:http/http.dart' as http;
import 'package:manga_tracker/modules/date.module.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../manga.service.dart';
import '../../types/manga.type.dart';
import '../../types/list.type.dart';

class MangaDexHuService extends MangaService {
  @override
  String get id => "mangadex-hu";

  @override
  String get name => "MangaDexHU";

  @override
  String get baseUrl => "https://api.mangadex.org";

  @override
  String get origin => "https://mangadex.org";

  @override
  String get referer => "https://mangadex.org/";

  @override
  String get logoUrl => "https://mangadex.org/pwa/icons/icon-192.png";

  @override
  String get mangaUrl => "${referer}title/$slug";

  final String lang = "hu";

  MangaDexHuService([super.slug = ""]);

  @override
  MangaService create(String slug) {
    return MangaDexHuService(slug);
  }

  String _getTitle(List<dynamic> altTitles) {
    try {
      final keys = [
        lang,
        "en",
        ...altTitles
            .map((x) => (x as Map<String, dynamic>).keys)
            .expand((k) => k),
      ];

      for (final key in keys) {
        final item = altTitles.cast<Map<String, dynamic>>().firstWhere(
          (x) => x.containsKey(key),
          orElse: () => {},
        );
        if (item.isEmpty) continue;
        return item[key] as String;
      }

      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      final limit = params.limit ?? 20;
      final offset = params.offset ?? 0;

      final uri = Uri.parse("$baseUrl/manga").replace(
        queryParameters: {
          "title": params.query ?? "",
          "limit": limit.toString(),
          "offset": offset.toString(),
          "includes[]": ["cover_art", "author"],
        },
      );

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body);
      final items = data["data"] as List;
      final total = data["total"] as int;

      final mangas = items.map((item) {
        final id = item["id"] as String;
        final attributes = item["attributes"];
        final relationships = item["relationships"] as List;

        final coverArt = relationships.firstWhere(
          (r) => r["type"] == "cover_art",
          orElse: () => null,
        );
        final fileName = coverArt?["attributes"]?["fileName"];

        final author = relationships.firstWhere(
          (r) => r["type"] == "author",
          orElse: () => null,
        );

        return Manga(
          id: id,
          slug: id,
          title:
              attributes["title"]?["en"] ??
              (attributes["title"] as Map).values.first as String,
          description: attributes["description"]?["en"] ?? "",
          coverUrl: "https://uploads.mangadex.org/covers/$id/$fileName.512.jpg",
          author: author?["attributes"]?["name"] ?? "Unknown",
          type: attributes["publicationDemographic"] ?? "manga",
        );
      }).toList();

      return PaginatedList(items: mangas, totalCount: total);
    } catch (e) {
      return PaginatedList(items: [], totalCount: 0);
    }
  }

  @override
  Future<Manga?> getMangaDetails() async {
    try {
      if (manga != null) return manga;

      final uri = Uri.parse("$baseUrl/manga/$slug").replace(
        queryParameters: {
          "includes[]": ["cover_art", "author"],
        },
      );

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body)["data"];

      final id = data["id"] as String;
      final attributes = data["attributes"];
      final relationships = data["relationships"] as List;

      final coverArt = relationships.firstWhere(
        (r) => r["type"] == "cover_art",
        orElse: () => null,
      );
      final fileName = coverArt?["attributes"]?["fileName"];

      final author = relationships.firstWhere(
        (r) => r["type"] == "author",
        orElse: () => null,
      );

      manga = Manga(
        id: id,
        slug: slug,
        title: _getTitle(attributes["altTitles"] as List),
        description: attributes["description"]?["en"] ?? "",
        coverUrl: "https://uploads.mangadex.org/covers/$slug/$fileName",
        type: data["type"] ?? "manga",
        author: author?["attributes"]?["name"] ?? "Unknown Author",
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

      final uri = Uri.parse("$baseUrl/manga/$slug/feed").replace(
        queryParameters: {
          "translatedLanguage[]": lang,
          "order[chapter]": "desc",
        },
      );

      final response = await http.get(uri, headers: headers);
      final data = jsonDecode(response.body)["data"] as List? ?? [];

      chapters = data.map((item) {
        final id = item["id"] as String;
        final attributes = item["attributes"];

        return Chapter(
          id: id,
          slug: id,
          title: attributes["title"] ?? "Chapter ${attributes["chapter"]}",
          number:
              double.tryParse(attributes["chapter"]?.toString() ?? "0") ?? 0,
          publishedAt: attributes["publishAt"] != null
              ? DateModule.getDateString(
                  DateTime.parse(attributes["publishAt"]),
                )
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
      final response = await http.get(
        Uri.parse("$baseUrl/at-home/server/$chapterSlug"),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      final baseUrlServer = data["baseUrl"] as String;
      final chapter = data["chapter"];
      final hash = chapter["hash"] as String;
      final pageList = chapter["data"] as List;

      const uuid = Uuid();

      final pages = pageList.asMap().entries.map((entry) {
        return ChapterPage(
          id: uuid.v4(),
          index: entry.key,
          imageUrl: "$baseUrlServer/data/$hash/${entry.value}",
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
