import 'dart:convert';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:manga_tracker/modules/date.module.dart';
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
  bool get needLogin => false;

  @override
  String get mangaUrl => "$origin/series/$slug";

  VortexScansService([super.slug = ""]);

  @override
  MangaService create(String slug) => VortexScansService(slug);

  String _fixEncoding(String text) {
    try {
      // Latin-1 byte-okká alakítja vissza, majd UTF-8-ként olvassa
      final bytes = latin1.encode(text);
      return utf8.decode(bytes);
    } catch (e) {
      return text;
    }
  }

  @override
  Future<PaginatedList<Manga>> getMangaList(ListParams params) async {
    try {
      final limit = params.limit ?? 20;
      final offset = params.offset ?? 0;
      final page = offset ~/ limit + 1;
      final query = (params.query ?? "").trim();

      final uri = Uri.parse("https://api.vortexscans.org/api/query").replace(
        queryParameters: {
          "searchTerm": query.isEmpty ? "a" : query,
          "page": page.toString(),
          "perPage": limit.toString(),
        },
      );

      final res = await http.get(uri, headers: headers);
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final posts = (data["posts"] as List?) ?? [];
      final totalCount = (data["totalCount"] as int?) ?? 0;

      final items = posts
          .map((e) {
            final map = e as Map<String, dynamic>;
            final slug = map["slug"]?.toString() ?? "";
            if (slug.isEmpty) return null;
            return Manga(
              slug: slug,
              title: map["postTitle"]?.toString() ?? slug,
              coverUrl: map["featuredImage"]?.toString() ?? "",
              author: "Unknown",
              description: "",
              type: map["seriesType"]?.toString() ?? "",
            );
          })
          .whereType<Manga>()
          .toList();

      return PaginatedList(items: items, totalCount: totalCount);
    } catch (_) {
      return PaginatedList(items: [], totalCount: 0);
    }
  }

  @override
  Future<Manga?> getMangaDetails() async {
    try {
      if (manga != null) return manga;

      final uri = Uri.parse("$origin/series/$slug");
      final res = await http.get(uri, headers: headers);

      final document = parse(res.body);
      final island = document
          .querySelectorAll('astro-island')
          .firstWhere(
            (el) =>
                el.attributes['opts']?.contains('SeriesChaptersPanelIsland') ??
                false,
          );

      final propsRaw = island.attributes['props'] ?? '';
      final props = jsonDecode(propsRaw) as Map<String, dynamic>;

      // Az astro props formátuma: [type, value] — mindig [1] az érték
      Map<String, dynamic> astroVal(dynamic field) =>
          (field as List)[1] as Map<String, dynamic>;
      dynamic val(dynamic field) => (field as List)[1];

      final post = astroVal(props['post']);

      final title = val(post['postTitle']) as String;
      final coverUrl = val(post['featuredImage']) as String;
      final author = val(post['author']) as String? ?? 'Unknown';
      final type = val(post['seriesType']) as String? ?? 'Unknown';

      // Leírás HTML-ből plain text
      final descHtml = val(post['postContent']) as String? ?? '';
      final description = parse(descHtml).body?.text ?? '';

      manga = Manga(
        title: _fixEncoding(title),
        coverUrl: coverUrl,
        author: _fixEncoding(author),
        type: _fixEncoding(type),
        slug: slug,
        description: _fixEncoding(description),
      );

      return manga;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Chapter>> getChapterList() async {
    try {
      if (chapters.isNotEmpty) return chapters;

      final res = await http.get(
        Uri.parse("$origin/series/$slug"),
        headers: headers,
      );

      final document = parse(res.body);
      final island = document
          .querySelectorAll('astro-island')
          .firstWhere(
            (el) =>
                el.attributes['opts']?.contains('SeriesChaptersPanelIsland') ??
                false,
          );

      final propsRaw = island.attributes['props'] ?? '';
      final props = jsonDecode(propsRaw) as Map<String, dynamic>;
      Map<String, dynamic> astroVal(dynamic field) =>
          (field as List)[1] as Map<String, dynamic>;
      dynamic val(dynamic field) => (field as List)[1];

      final post = astroVal(props['post']);

      final chaptersRaw = (post['chapters'] as List)[1] as List;

      chapters = chaptersRaw.map((entry) {
        final ch = (entry as List)[1] as Map<String, dynamic>;

        final number = (val(ch['number']) as num).toDouble();
        final title = _fixEncoding(val(ch['title']) as String? ?? '').trim();
        final date = _fixEncoding(val(ch['createdAt']) as String? ?? '').trim();

        return Chapter(
          number: number,
          slug: val(ch['slug']) as String,
          title: title.isNotEmpty ? title : "Chapter $number",
          publishedAt: date.isNotEmpty
              ? DateModule.getDateString(DateTime.parse(date))
              : "",
        );
      }).toList();

      return chapters;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ChapterContent> getPageList(ChapterSlug chapterSlug) async {
    try {
      final url = '$origin/series/$slug/$chapterSlug';
      final res = await http.get(Uri.parse(url), headers: headers);
      final document = parse(res.body);

      final images = document.querySelectorAll('[data-reader-page-image]');
      final pages = images
          .map((img) {
            final src = img.attributes['src'] ?? '';
            final index =
                int.tryParse(img.attributes['data-reader-index'] ?? '0') ?? 0;
            return ChapterPage(index: index, imageUrl: src);
          })
          .where((p) => p.imageUrl.isNotEmpty)
          .toList();

      final curr = await getRelativeChapter(chapterSlug, 0);
      final next = await getRelativeChapter(chapterSlug, 1);
      final prev = await getRelativeChapter(chapterSlug, -1);

      return ChapterContent(
        pages: pages,
        prevChapter: prev,
        currChapter: curr,
        nextChapter: next,
      );
    } catch (_) {
      return ChapterContent.empty();
    }
  }
}
