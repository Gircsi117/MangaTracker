import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:manga_tracker/modules/date.module.dart';
import '../manga.service.dart';
import '../../types/manga.type.dart';
import '../../types/list.type.dart';

class AsuraScansService extends MangaService {
  @override
  String get id => "asurascans";

  @override
  String get name => "AsuraScans";

  @override
  String get baseUrl => "https://asurascans.com";

  @override
  String get origin => "https://asurascans.com";

  @override
  String get referer => "https://asurascans.com/";

  @override
  String get logoUrl => "https://asurascans.com/images/logo.webp";

  @override
  String get mangaUrl => "${referer}comics/$slug";

  AsuraScansService([super.slug = ""]);

  @override
  MangaService create(String slug) {
    return AsuraScansService(slug);
  }

  Map<String, dynamic>? _parseIslandProps(String html, String propsContains) {
    final document = parse(html);
    final elements = document.querySelectorAll("astro-island");

    for (final el in elements) {
      final props = el.attributes["props"];
      if (props != null && props.contains(propsContains)) {
        return jsonDecode(props) as Map<String, dynamic>;
      }
    }

    return null;
  }

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      final limit = params.limit ?? 20;
      final offset = params.offset ?? 0;
      final page = offset ~/ limit + 1;

      final uri = Uri.parse("$origin/browse").replace(
        queryParameters: {"q": params.query ?? "", "page": page.toString()},
      );

      final response = await http.get(uri, headers: headers);
      final props = _parseIslandProps(response.body, "initialSeries");

      if (props == null) return PaginatedList(items: [], totalCount: 0);

      final totalCount = props["totalCount"]?[1] as int? ?? 0;
      final series = props["initialSeries"]?[1] as List? ?? [];

      final mangas = series.map((item) {
        final s = item[1];
        return Manga(
          id: s["id"][1].toString(),
          slug: s["slug"][1] as String,
          title: s["title"][1] as String,
          coverUrl: s["cover"][1] as String,
          author: s["author"]?[1] as String? ?? "Unknown",
          description: s["description"]?[1] as String? ?? "",
          type: s["type"][1] as String,
        );
      }).toList();

      return PaginatedList(items: mangas, totalCount: totalCount);
    } catch (e) {
      return PaginatedList(items: [], totalCount: 0);
    }
  }

  @override
  Future<Manga?> getMangaDetails() async {
    try {
      if (manga != null) return manga;

      final response = await http.get(
        Uri.parse("$origin/comics/$slug"),
        headers: headers,
      );

      final props = _parseIslandProps(response.body, "title");
      if (props == null) return null;

      manga = Manga(
        id: slug,
        slug: slug,
        title: props["title"][1] as String,
        description: props["description"][1] as String,
        author: props["author"][1] as String,
        coverUrl: props["coverUrl"][1] as String,
        type: props["type"][1] as String,
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

      final response = await http.get(
        Uri.parse("$origin/comics/$slug"),
        headers: headers,
      );

      final props = _parseIslandProps(response.body, "chapters");
      if (props == null) return [];

      final chapterList = props["chapters"][1] as List? ?? [];

      chapters = chapterList.map((chapter) {
        final c = chapter[1];
        return Chapter(
          id: c["id"][1].toString(),
          slug: c["number"][1].toString(),
          title: c["title"]?[1] as String? ?? "Chapter ${c["number"][1]}",
          number: double.tryParse(c["number"][1].toString()) ?? 0,
          publishedAt: c["published_at"]?[1] != null
              ? DateModule.getDateString(
                  DateTime.parse(c["published_at"][1] as String),
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
        Uri.parse("$origin/comics/$slug/chapter/$chapterSlug"),
        headers: headers,
      );

      final props = _parseIslandProps(response.body, "pages");

      if (props == null) {
        return ChapterContent(
          pages: [],
          currChapter: null,
          nextChapter: null,
          prevChapter: null,
        );
      }

      final pageList = props["pages"][1] as List? ?? [];

      final pages = pageList.asMap().entries.map((entry) {
        final i = entry.key;
        final page = entry.value[1];
        return ChapterPage(
          id: i.toString(),
          index: i,
          imageUrl: page["url"]?[1] as String? ?? "",
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
      return ChapterContent.empty();
    }
  }
}
